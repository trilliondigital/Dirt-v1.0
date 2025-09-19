import XCTest
@testable import Dirt

class ReputationProfileTests: XCTestCase {
    
    var reputationService: ReputationService!
    var notificationService: ReputationNotificationService!
    var testUserId: UUID!
    
    override func setUp() {
        super.setUp()
        reputationService = ReputationService()
        notificationService = ReputationNotificationService.shared
        testUserId = UUID()
        
        // Clear any existing test data
        clearUserDefaults()
        clearNotifications()
    }
    
    override func tearDown() {
        clearUserDefaults()
        clearNotifications()
        reputationService = nil
        notificationService = nil
        testUserId = nil
        super.tearDown()
    }
    
    private func clearUserDefaults() {
        let userDefaults = UserDefaults.standard
        let keys = [
            "user_achievements_\(testUserId?.uuidString ?? "")",
            "reputation_events_\(testUserId?.uuidString ?? "")",
            "user_reputation_\(testUserId?.uuidString ?? "")"
        ]
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
    
    private func clearNotifications() {
        Task {
            await MainActor.run {
                notificationService.pendingNotifications.removeAll()
            }
        }
    }
    
    // MARK: - Reputation Milestone Tests
    
    func testReputationMilestoneProperties() {
        let contributor = ReputationMilestone.contributor
        XCTAssertEqual(contributor.title, "Contributor")
        XCTAssertEqual(contributor.requiredReputation, 50)
        XCTAssertEqual(contributor.color, "blue")
        XCTAssertEqual(contributor.icon, "person.badge.plus")
        
        let legend = ReputationMilestone.legend
        XCTAssertEqual(legend.title, "Legend")
        XCTAssertEqual(legend.requiredReputation, 1000)
        XCTAssertEqual(legend.color, "gold")
        XCTAssertEqual(legend.icon, "trophy")
    }
    
    func testUnlockedFeatureProperties() {
        let reporting = UnlockedFeature.reporting
        XCTAssertEqual(reporting.description, "Report inappropriate content")
        XCTAssertEqual(reporting.requiredReputation, 10)
        XCTAssertEqual(reporting.icon, "exclamationmark.triangle")
        
        let moderation = UnlockedFeature.moderation
        XCTAssertEqual(moderation.description, "Help moderate community content")
        XCTAssertEqual(moderation.requiredReputation, 100)
        XCTAssertEqual(moderation.icon, "shield")
    }
    
    // MARK: - Notification Service Tests
    
    func testScheduleAchievementNotification() async {
        let achievement = Achievement(userId: testUserId, type: .firstPost)
        
        await notificationService.scheduleAchievementNotification(
            for: achievement,
            username: "TestUser"
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 1)
            
            let notification = notificationService.pendingNotifications.first!
            XCTAssertEqual(notification.type, .achievement)
            XCTAssertEqual(notification.title, "Achievement Unlocked! 🏆")
            XCTAssertTrue(notification.message.contains("First Post"))
        }
    }
    
    func testScheduleMilestoneNotification() async {
        await notificationService.scheduleMilestoneNotification(
            userId: testUserId,
            newReputation: 100,
            username: "TestUser"
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 1)
            
            let notification = notificationService.pendingNotifications.first!
            XCTAssertEqual(notification.type, .milestone)
            XCTAssertEqual(notification.title, "Reputation Milestone! ⭐")
            XCTAssertTrue(notification.message.contains("100 reputation points"))
            XCTAssertTrue(notification.message.contains("Trusted Member"))
        }
    }
    
    func testScheduleFeatureUnlockNotification() async {
        await notificationService.scheduleFeatureUnlockNotification(
            feature: .moderation,
            username: "TestUser"
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 1)
            
            let notification = notificationService.pendingNotifications.first!
            XCTAssertEqual(notification.type, .featureUnlock)
            XCTAssertEqual(notification.title, "New Feature Unlocked! 🔓")
            XCTAssertTrue(notification.message.contains("Help moderate community content"))
        }
    }
    
    func testMarkNotificationAsRead() async {
        let achievement = Achievement(userId: testUserId, type: .firstPost)
        
        await notificationService.scheduleAchievementNotification(
            for: achievement,
            username: "TestUser"
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 1)
            
            let notificationId = notificationService.pendingNotifications.first!.id
            notificationService.markNotificationAsRead(notificationId)
            
            XCTAssertEqual(notificationService.pendingNotifications.count, 0)
        }
    }
    
    func testClearAllNotifications() async {
        // Schedule multiple notifications
        let achievement1 = Achievement(userId: testUserId, type: .firstPost)
        let achievement2 = Achievement(userId: testUserId, type: .firstReview)
        
        await notificationService.scheduleAchievementNotification(
            for: achievement1,
            username: "TestUser"
        )
        
        await notificationService.scheduleAchievementNotification(
            for: achievement2,
            username: "TestUser"
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 2)
            
            notificationService.clearAllNotifications()
            
            XCTAssertEqual(notificationService.pendingNotifications.count, 0)
        }
    }
    
    // MARK: - Enhanced Reputation Service Tests
    
    func testAddReputationPointsWithNotifications() async throws {
        // Test milestone notification
        try await reputationService.addReputationPointsWithNotifications(
            userId: testUserId,
            action: .reviewUpvote,
            username: "TestUser"
        )
        
        // Add enough points to reach 50 (contributor milestone)
        for _ in 0..<16 { // 16 * 3 = 48, plus the first 3 = 51
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .reviewUpvote,
                contentId: UUID()
            )
        }
        
        // This should trigger milestone notification
        try await reputationService.addReputationPointsWithNotifications(
            userId: testUserId,
            action: .reviewUpvote,
            username: "TestUser"
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertGreaterThanOrEqual(reputation, 50)
        
        // Check for milestone notification
        await MainActor.run {
            let milestoneNotifications = notificationService.pendingNotifications.filter { 
                $0.type == .milestone 
            }
            XCTAssertGreaterThan(milestoneNotifications.count, 0)
        }
    }
    
    func testFeatureUnlockNotifications() async throws {
        // Add enough points to unlock reporting feature (10 points)
        for _ in 0..<5 { // 5 * 2 = 10 points
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .postUpvote,
                contentId: UUID()
            )
        }
        
        // This should trigger feature unlock notification
        try await reputationService.addReputationPointsWithNotifications(
            userId: testUserId,
            action: .postUpvote,
            username: "TestUser"
        )
        
        await MainActor.run {
            let featureNotifications = notificationService.pendingNotifications.filter { 
                $0.type == .featureUnlock 
            }
            XCTAssertGreaterThan(featureNotifications.count, 0)
        }
    }
    
    func testAchievementNotifications() async throws {
        // This should trigger first post achievement
        try await reputationService.addReputationPointsWithNotifications(
            userId: testUserId,
            action: .postUpvote,
            username: "TestUser"
        )
        
        await MainActor.run {
            let achievementNotifications = notificationService.pendingNotifications.filter { 
                $0.type == .achievement 
            }
            XCTAssertGreaterThan(achievementNotifications.count, 0)
        }
    }
    
    // MARK: - Reputation Level Tests
    
    func testReputationLevelCalculation() {
        XCTAssertEqual(getReputationLevel(0), "Newcomer")
        XCTAssertEqual(getReputationLevel(25), "Newcomer")
        XCTAssertEqual(getReputationLevel(50), "Contributor")
        XCTAssertEqual(getReputationLevel(75), "Contributor")
        XCTAssertEqual(getReputationLevel(100), "Trusted")
        XCTAssertEqual(getReputationLevel(200), "Trusted")
        XCTAssertEqual(getReputationLevel(250), "Veteran")
        XCTAssertEqual(getReputationLevel(400), "Veteran")
        XCTAssertEqual(getReputationLevel(500), "Expert")
        XCTAssertEqual(getReputationLevel(750), "Expert")
        XCTAssertEqual(getReputationLevel(1000), "Legend")
        XCTAssertEqual(getReputationLevel(1500), "Legend")
    }
    
    func testPointsToNextLevel() {
        XCTAssertEqual(getPointsToNextLevel(0), 50)
        XCTAssertEqual(getPointsToNextLevel(25), 25)
        XCTAssertEqual(getPointsToNextLevel(50), 50)
        XCTAssertEqual(getPointsToNextLevel(75), 25)
        XCTAssertEqual(getPointsToNextLevel(100), 150)
        XCTAssertEqual(getPointsToNextLevel(200), 50)
        XCTAssertEqual(getPointsToNextLevel(250), 250)
        XCTAssertEqual(getPointsToNextLevel(400), 100)
        XCTAssertEqual(getPointsToNextLevel(500), 500)
        XCTAssertEqual(getPointsToNextLevel(750), 250)
        XCTAssertEqual(getPointsToNextLevel(1000), 0)
        XCTAssertEqual(getPointsToNextLevel(1500), 0)
    }
    
    // MARK: - Helper Methods
    
    private func getReputationLevel(_ reputation: Int) -> String {
        switch reputation {
        case 0..<50:
            return "Newcomer"
        case 50..<100:
            return "Contributor"
        case 100..<250:
            return "Trusted"
        case 250..<500:
            return "Veteran"
        case 500..<1000:
            return "Expert"
        default:
            return "Legend"
        }
    }
    
    private func getPointsToNextLevel(_ reputation: Int) -> Int {
        switch reputation {
        case 0..<50:
            return 50 - reputation
        case 50..<100:
            return 100 - reputation
        case 100..<250:
            return 250 - reputation
        case 250..<500:
            return 500 - reputation
        case 500..<1000:
            return 1000 - reputation
        default:
            return 0
        }
    }
    
    // MARK: - Performance Tests
    
    func testReputationCalculationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = getReputationLevel(i)
                _ = getPointsToNextLevel(i)
            }
        }
    }
    
    func testNotificationSchedulingPerformance() async {
        let achievements = (0..<100).map { _ in
            Achievement(userId: testUserId, type: .firstPost)
        }
        
        await measureAsync {
            for achievement in achievements {
                await notificationService.scheduleAchievementNotification(
                    for: achievement,
                    username: "TestUser"
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testNotificationWithEmptyUsername() async {
        let achievement = Achievement(userId: testUserId, type: .firstPost)
        
        await notificationService.scheduleAchievementNotification(
            for: achievement,
            username: ""
        )
        
        await MainActor.run {
            XCTAssertEqual(notificationService.pendingNotifications.count, 1)
            let notification = notificationService.pendingNotifications.first!
            XCTAssertFalse(notification.message.isEmpty)
        }
    }
    
    func testMultipleMilestoneNotifications() async throws {
        // Rapidly add points to trigger multiple milestones
        for _ in 0..<334 { // 334 * 3 = 1002 points (should trigger multiple milestones)
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .reviewUpvote,
                contentId: UUID()
            )
        }
        
        // This should trigger multiple milestone notifications
        try await reputationService.addReputationPointsWithNotifications(
            userId: testUserId,
            action: .reviewUpvote,
            username: "TestUser"
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertGreaterThan(reputation, 1000)
        
        await MainActor.run {
            let milestoneNotifications = notificationService.pendingNotifications.filter { 
                $0.type == .milestone 
            }
            // Should have notifications for reaching various milestones
            XCTAssertGreaterThan(milestoneNotifications.count, 0)
        }
    }
}

// MARK: - Async Measurement Helper

extension XCTestCase {
    func measureAsync(block: @escaping () async -> Void) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed: \(timeElapsed) seconds")
    }
}