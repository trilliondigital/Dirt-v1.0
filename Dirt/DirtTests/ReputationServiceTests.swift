import XCTest
@testable import Dirt

class ReputationServiceTests: XCTestCase {
    
    var reputationService: ReputationService!
    var testUserId: UUID!
    
    override func setUp() {
        super.setUp()
        reputationService = ReputationService()
        testUserId = UUID()
        
        // Clear any existing test data
        clearUserDefaults()
    }
    
    override func tearDown() {
        clearUserDefaults()
        reputationService = nil
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
    
    // MARK: - Basic Reputation Tests
    
    func testInitialReputationIsZero() async throws {
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, 0)
    }
    
    func testAddPositiveReputationPoints() async throws {
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: UUID()
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, ReputationAction.postUpvote.points)
    }
    
    func testAddNegativeReputationPoints() async throws {
        // First add some positive points
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: UUID()
        )
        
        // Then subtract points
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postDownvote,
            contentId: UUID()
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        let expectedReputation = ReputationAction.postUpvote.points + ReputationAction.postDownvote.points
        XCTAssertEqual(reputation, expectedReputation)
    }
    
    func testReputationCannotGoBelowZero() async throws {
        // Try to subtract points when reputation is 0
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .contentRemoved,
            contentId: UUID()
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, 0)
    }
    
    // MARK: - Achievement Tests
    
    func testInitialAchievementsEmpty() async throws {
        let achievements = try await reputationService.getUserAchievements(userId: testUserId)
        XCTAssertTrue(achievements.isEmpty)
    }
    
    func testFirstPostAchievement() async throws {
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: UUID()
        )
        
        let newAchievements = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertTrue(newAchievements.contains { $0.type == .firstPost })
        
        let allAchievements = try await reputationService.getUserAchievements(userId: testUserId)
        XCTAssertTrue(allAchievements.contains { $0.type == .firstPost })
    }
    
    func testFirstReviewAchievement() async throws {
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .reviewUpvote,
            contentId: UUID()
        )
        
        let newAchievements = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertTrue(newAchievements.contains { $0.type == .firstReview })
    }
    
    func testTrustedMemberAchievement() async throws {
        // Add enough points to reach trusted member status
        let pointsNeeded = 100
        let upvotesNeeded = pointsNeeded / ReputationAction.reviewUpvote.points
        
        for _ in 0..<upvotesNeeded {
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .reviewUpvote,
                contentId: UUID()
            )
        }
        
        let newAchievements = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertTrue(newAchievements.contains { $0.type == .trustedMember })
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertGreaterThanOrEqual(reputation, 100)
    }
    
    func testAchievementNotDuplicated() async throws {
        // Award first post achievement
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: UUID()
        )
        
        let firstCheck = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertTrue(firstCheck.contains { $0.type == .firstPost })
        
        // Try to award again
        let secondCheck = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertFalse(secondCheck.contains { $0.type == .firstPost })
        
        // Verify only one achievement exists
        let allAchievements = try await reputationService.getUserAchievements(userId: testUserId)
        let firstPostAchievements = allAchievements.filter { $0.type == .firstPost }
        XCTAssertEqual(firstPostAchievements.count, 1)
    }
    
    // MARK: - Permission Tests
    
    func testBasicUserCanCreateContent() async throws {
        let canCreatePost = try await reputationService.canUserPerformAction(userId: testUserId, action: .createPost)
        let canCreateReview = try await reputationService.canUserPerformAction(userId: testUserId, action: .createReview)
        
        XCTAssertTrue(canCreatePost)
        XCTAssertTrue(canCreateReview)
    }
    
    func testNewUserCannotModerate() async throws {
        let canModerate = try await reputationService.canUserPerformAction(userId: testUserId, action: .moderate)
        XCTAssertFalse(canModerate)
    }
    
    func testHighReputationUserCanModerate() async throws {
        // Add enough points for moderation privileges
        let pointsNeeded = 100
        let upvotesNeeded = pointsNeeded / ReputationAction.reviewUpvote.points
        
        for _ in 0..<upvotesNeeded {
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .reviewUpvote,
                contentId: UUID()
            )
        }
        
        let canModerate = try await reputationService.canUserPerformAction(userId: testUserId, action: .moderate)
        XCTAssertTrue(canModerate)
    }
    
    func testNewUserCannotReportContent() async throws {
        let canReport = try await reputationService.canUserPerformAction(userId: testUserId, action: .reportContent)
        XCTAssertFalse(canReport)
    }
    
    func testUserWithMinimumReputationCanReportContent() async throws {
        // Add minimum points for reporting
        for _ in 0..<5 {
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .postUpvote,
                contentId: UUID()
            )
        }
        
        let canReport = try await reputationService.canUserPerformAction(userId: testUserId, action: .reportContent)
        XCTAssertTrue(canReport)
    }
    
    // MARK: - Reputation History Tests
    
    func testReputationHistoryTracking() async throws {
        let contentId1 = UUID()
        let contentId2 = UUID()
        
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: contentId1
        )
        
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .reviewUpvote,
            contentId: contentId2
        )
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 10)
        
        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history.contains { $0.action == .postUpvote && $0.contentId == contentId1 })
        XCTAssertTrue(history.contains { $0.action == .reviewUpvote && $0.contentId == contentId2 })
    }
    
    func testReputationHistoryLimit() async throws {
        // Add more events than the limit
        for i in 0..<15 {
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .postUpvote,
                contentId: UUID()
            )
        }
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 10)
        XCTAssertEqual(history.count, 10)
    }
    
    func testReputationHistoryOrdering() async throws {
        let firstContentId = UUID()
        let secondContentId = UUID()
        
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: firstContentId
        )
        
        // Add a small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .reviewUpvote,
            contentId: secondContentId
        )
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 10)
        
        // Most recent should be first
        XCTAssertEqual(history.first?.action, .reviewUpvote)
        XCTAssertEqual(history.first?.contentId, secondContentId)
    }
    
    // MARK: - Convenience Method Tests
    
    func testHandleContentUpvote() async throws {
        let contentId = UUID()
        
        try await reputationService.handleContentUpvote(
            userId: testUserId,
            contentId: contentId,
            contentType: .post
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, ReputationAction.postUpvote.points)
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 1)
        XCTAssertEqual(history.first?.action, .postUpvote)
        XCTAssertEqual(history.first?.contentId, contentId)
    }
    
    func testHandleContentDownvote() async throws {
        // First add some positive reputation
        try await reputationService.addReputationPoints(
            userId: testUserId,
            action: .postUpvote,
            contentId: UUID()
        )
        
        let contentId = UUID()
        try await reputationService.handleContentDownvote(
            userId: testUserId,
            contentId: contentId,
            contentType: .review
        )
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 10)
        XCTAssertTrue(history.contains { $0.action == .reviewDownvote && $0.contentId == contentId })
    }
    
    func testHandleQualityContent() async throws {
        let contentId = UUID()
        
        try await reputationService.handleQualityContent(
            userId: testUserId,
            contentId: contentId,
            contentType: .review
        )
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, ReputationAction.helpfulReview.points)
        
        let history = try await reputationService.getReputationHistory(userId: testUserId, limit: 1)
        XCTAssertEqual(history.first?.action, .helpfulReview)
    }
    
    // MARK: - Achievement Type Tests
    
    func testAchievementTypeProperties() {
        let firstPost = AchievementType.firstPost
        XCTAssertEqual(firstPost.title, "First Post")
        XCTAssertEqual(firstPost.requiredReputation, 0)
        XCTAssertFalse(firstPost.description.isEmpty)
        
        let trustedMember = AchievementType.trustedMember
        XCTAssertEqual(trustedMember.requiredReputation, 100)
        XCTAssertEqual(trustedMember.title, "Trusted Member")
    }
    
    func testReputationActionPoints() {
        XCTAssertEqual(ReputationAction.postUpvote.points, 2)
        XCTAssertEqual(ReputationAction.reviewUpvote.points, 3)
        XCTAssertEqual(ReputationAction.commentUpvote.points, 1)
        XCTAssertEqual(ReputationAction.postDownvote.points, -1)
        XCTAssertEqual(ReputationAction.contentRemoved.points, -10)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleUsersIndependentReputation() async throws {
        let user1 = UUID()
        let user2 = UUID()
        
        try await reputationService.addReputationPoints(
            userId: user1,
            action: .postUpvote,
            contentId: UUID()
        )
        
        try await reputationService.addReputationPoints(
            userId: user2,
            action: .reviewUpvote,
            contentId: UUID()
        )
        
        let user1Reputation = try await reputationService.getUserReputation(userId: user1)
        let user2Reputation = try await reputationService.getUserReputation(userId: user2)
        
        XCTAssertEqual(user1Reputation, ReputationAction.postUpvote.points)
        XCTAssertEqual(user2Reputation, ReputationAction.reviewUpvote.points)
    }
    
    func testLargeReputationCalculation() async throws {
        // Test with many reputation events
        for _ in 0..<100 {
            try await reputationService.addReputationPoints(
                userId: testUserId,
                action: .reviewUpvote,
                contentId: UUID()
            )
        }
        
        let reputation = try await reputationService.getUserReputation(userId: testUserId)
        XCTAssertEqual(reputation, 100 * ReputationAction.reviewUpvote.points)
        
        let achievements = try await reputationService.checkAndAwardAchievements(userId: testUserId)
        XCTAssertTrue(achievements.contains { $0.type == .trustedMember })
    }
}