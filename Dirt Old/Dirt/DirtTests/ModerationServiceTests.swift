import XCTest
@testable import Dirt

class ModerationServiceTests: XCTestCase {
    
    var moderationService: ModerationService!
    
    override func setUp() {
        super.setUp()
        moderationService = ModerationService()
    }
    
    override func tearDown() {
        moderationService = nil
        super.tearDown()
    }
    
    // MARK: - Moderator Management Tests
    
    func testGetActiveModerators() {
        let activeModerators = moderationService.getActiveModerators()
        
        XCTAssertFalse(activeModerators.isEmpty)
        XCTAssertTrue(activeModerators.allSatisfy { $0.isActive })
    }
    
    func testAssignModeratorToContent() async {
        let activeModerators = moderationService.getActiveModerators()
        guard let moderator = activeModerators.first else {
            XCTFail("No active moderators available")
            return
        }
        
        let contentId = UUID()
        let success = await moderationService.assignModerator(
            contentId: contentId,
            moderatorId: moderator.id
        )
        
        XCTAssertTrue(success)
    }
    
    func testAssignInactiveModerator() async {
        let inactiveModerator = UUID()
        let contentId = UUID()
        
        let success = await moderationService.assignModerator(
            contentId: contentId,
            moderatorId: inactiveModerator
        )
        
        XCTAssertFalse(success)
    }
    
    func testGetModeratorWorkload() {
        let activeModerators = moderationService.getActiveModerators()
        guard let moderator = activeModerators.first else {
            XCTFail("No active moderators available")
            return
        }
        
        let workload = moderationService.getModeratorWorkload(moderatorId: moderator.id)
        
        XCTAssertEqual(workload.moderatorId, moderator.id)
        XCTAssertGreaterThanOrEqual(workload.assignedItems, 0)
        XCTAssertGreaterThanOrEqual(workload.completedToday, 0)
        XCTAssertGreaterThan(workload.averageTimePerItem, 0)
    }
    
    // MARK: - User Penalty System Tests
    
    func testApplyUserPenalty() async {
        let userId = UUID()
        let moderatorId = UUID()
        let contentId = UUID()
        
        await moderationService.applyUserPenalty(
            userId: userId,
            penalty: .warning,
            reason: "Test warning",
            moderatorId: moderatorId,
            contentId: contentId
        )
        
        let penalties = moderationService.getActivePenalties(for: userId)
        XCTAssertEqual(penalties.count, 1)
        
        let penalty = penalties.first!
        XCTAssertEqual(penalty.userId, userId)
        XCTAssertEqual(penalty.moderatorId, moderatorId)
        XCTAssertEqual(penalty.contentId, contentId)
        XCTAssertEqual(penalty.reason, "Test warning")
        XCTAssertTrue(penalty.isActive)
    }
    
    func testApplyTemporaryBan() async {
        let userId = UUID()
        let moderatorId = UUID()
        
        await moderationService.applyUserPenalty(
            userId: userId,
            penalty: .temporaryBan(days: 7),
            reason: "Harassment violation",
            moderatorId: moderatorId
        )
        
        let penalties = moderationService.getActivePenalties(for: userId)
        XCTAssertEqual(penalties.count, 1)
        
        let penalty = penalties.first!
        if case .temporaryBan(let days) = penalty.penaltyType {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected temporary ban penalty")
        }
        
        XCTAssertNotNil(penalty.expiresAt)
    }
    
    func testRemovePenalty() async {
        let userId = UUID()
        let moderatorId = UUID()
        
        await moderationService.applyUserPenalty(
            userId: userId,
            penalty: .warning,
            reason: "Test warning",
            moderatorId: moderatorId
        )
        
        let penalties = moderationService.getActivePenalties(for: userId)
        XCTAssertEqual(penalties.count, 1)
        
        let penaltyId = penalties.first!.id
        await moderationService.removePenalty(penaltyId: penaltyId, reason: "Appeal approved")
        
        let activePenalties = moderationService.getActivePenalties(for: userId)
        XCTAssertTrue(activePenalties.isEmpty)
    }
    
    func testGetActivePenaltiesFiltersExpired() async {
        let userId = UUID()
        let moderatorId = UUID()
        
        // Apply a penalty that would be expired (simulate by creating expired penalty)
        await moderationService.applyUserPenalty(
            userId: userId,
            penalty: .temporaryBan(days: -1), // Negative days to simulate expired
            reason: "Expired ban",
            moderatorId: moderatorId
        )
        
        // The penalty should not appear in active penalties due to expiration
        let activePenalties = moderationService.getActivePenalties(for: userId)
        XCTAssertTrue(activePenalties.isEmpty)
    }
    
    // MARK: - Appeal System Tests
    
    func testSubmitAppeal() async {
        let userId = UUID()
        let contentId = UUID()
        let moderationActionId = UUID()
        
        let appeal = await moderationService.submitAppeal(
            userId: userId,
            contentId: contentId,
            moderationActionId: moderationActionId,
            reason: "I believe this was incorrectly flagged",
            evidence: "Additional context about the content"
        )
        
        XCTAssertEqual(appeal.userId, userId)
        XCTAssertEqual(appeal.contentId, contentId)
        XCTAssertEqual(appeal.moderationActionId, moderationActionId)
        XCTAssertEqual(appeal.reason, "I believe this was incorrectly flagged")
        XCTAssertEqual(appeal.evidence, "Additional context about the content")
        XCTAssertEqual(appeal.status, .pending)
        XCTAssertNil(appeal.reviewedAt)
        XCTAssertNil(appeal.reviewedBy)
        
        let pendingAppeals = moderationService.getPendingAppeals()
        XCTAssertTrue(pendingAppeals.contains { $0.id == appeal.id })
    }
    
    func testReviewAppealApproved() async {
        let userId = UUID()
        let contentId = UUID()
        let moderationActionId = UUID()
        let moderatorId = UUID()
        
        let appeal = await moderationService.submitAppeal(
            userId: userId,
            contentId: contentId,
            moderationActionId: moderationActionId,
            reason: "Appeal reason"
        )
        
        let success = await moderationService.reviewAppeal(
            appealId: appeal.id,
            moderatorId: moderatorId,
            decision: .approved,
            reason: "Appeal is valid"
        )
        
        XCTAssertTrue(success)
        
        let updatedAppeal = moderationService.appeals.first { $0.id == appeal.id }
        XCTAssertNotNil(updatedAppeal)
        XCTAssertEqual(updatedAppeal?.status, .approved)
        XCTAssertEqual(updatedAppeal?.decision, .approved)
        XCTAssertEqual(updatedAppeal?.decisionReason, "Appeal is valid")
        XCTAssertEqual(updatedAppeal?.reviewedBy, moderatorId)
        XCTAssertNotNil(updatedAppeal?.reviewedAt)
    }
    
    func testReviewAppealRejected() async {
        let userId = UUID()
        let contentId = UUID()
        let moderationActionId = UUID()
        let moderatorId = UUID()
        
        let appeal = await moderationService.submitAppeal(
            userId: userId,
            contentId: contentId,
            moderationActionId: moderationActionId,
            reason: "Appeal reason"
        )
        
        let success = await moderationService.reviewAppeal(
            appealId: appeal.id,
            moderatorId: moderatorId,
            decision: .rejected,
            reason: "Original decision was correct"
        )
        
        XCTAssertTrue(success)
        
        let updatedAppeal = moderationService.appeals.first { $0.id == appeal.id }
        XCTAssertNotNil(updatedAppeal)
        XCTAssertEqual(updatedAppeal?.status, .rejected)
        XCTAssertEqual(updatedAppeal?.decision, .rejected)
        XCTAssertEqual(updatedAppeal?.decisionReason, "Original decision was correct")
    }
    
    func testReviewNonexistentAppeal() async {
        let nonexistentAppealId = UUID()
        let moderatorId = UUID()
        
        let success = await moderationService.reviewAppeal(
            appealId: nonexistentAppealId,
            moderatorId: moderatorId,
            decision: .approved,
            reason: "Test"
        )
        
        XCTAssertFalse(success)
    }
    
    // MARK: - Content Approval Workflow Tests
    
    func testProcessContentApprovalSuccess() async {
        let activeModerators = moderationService.getActiveModerators()
        guard let moderator = activeModerators.first else {
            XCTFail("No active moderators available")
            return
        }
        
        let contentId = UUID()
        
        let result = await moderationService.processContentApproval(
            contentId: contentId,
            moderatorId: moderator.id,
            action: .approve,
            reason: "Content is acceptable",
            notes: "No issues found"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertNil(result.error)
    }
    
    func testProcessContentApprovalInvalidModerator() async {
        let invalidModeratorId = UUID()
        let contentId = UUID()
        
        let result = await moderationService.processContentApproval(
            contentId: contentId,
            moderatorId: invalidModeratorId,
            action: .approve,
            reason: "Test"
        )
        
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
        XCTAssertTrue(result.error?.contains("permission") == true)
    }
    
    // MARK: - Analytics Tests
    
    func testGetModerationMetrics() async {
        let activeModerators = moderationService.getActiveModerators()
        guard let moderator = activeModerators.first else {
            XCTFail("No active moderators available")
            return
        }
        
        let metrics = await moderationService.getModerationMetrics(
            for: moderator.id,
            timeRange: .week
        )
        
        XCTAssertEqual(metrics.moderatorId, moderator.id)
        XCTAssertEqual(metrics.timeRange, .week)
        XCTAssertGreaterThanOrEqual(metrics.totalReviewed, 0)
        XCTAssertGreaterThanOrEqual(metrics.approved, 0)
        XCTAssertGreaterThanOrEqual(metrics.rejected, 0)
        XCTAssertGreaterThan(metrics.averageTimePerReview, 0)
        XCTAssertGreaterThan(metrics.accuracyScore, 0)
        XCTAssertLessThanOrEqual(metrics.accuracyScore, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.appealsOverturned, 0)
    }
    
    func testGetSystemModerationStats() async {
        let stats = await moderationService.getSystemModerationStats(timeRange: .month)
        
        XCTAssertEqual(stats.timeRange, .month)
        XCTAssertGreaterThan(stats.totalContentProcessed, 0)
        XCTAssertGreaterThanOrEqual(stats.autoApproved, 0)
        XCTAssertGreaterThanOrEqual(stats.autoRejected, 0)
        XCTAssertGreaterThanOrEqual(stats.humanReviewed, 0)
        XCTAssertGreaterThan(stats.averageQueueTime, 0)
        XCTAssertGreaterThan(stats.aiAccuracy, 0)
        XCTAssertLessThanOrEqual(stats.aiAccuracy, 1.0)
        XCTAssertGreaterThanOrEqual(stats.falsePositiveRate, 0)
        XCTAssertLessThanOrEqual(stats.falsePositiveRate, 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteAppealWorkflow() async {
        let userId = UUID()
        let contentId = UUID()
        let moderationActionId = UUID()
        let moderatorId = moderationService.getActiveModerators().first!.id
        
        // 1. Apply a penalty
        await moderationService.applyUserPenalty(
            userId: userId,
            penalty: .temporaryBan(days: 3),
            reason: "Inappropriate content",
            moderatorId: moderatorId,
            contentId: contentId
        )
        
        let initialPenalties = moderationService.getActivePenalties(for: userId)
        XCTAssertEqual(initialPenalties.count, 1)
        
        // 2. Submit an appeal
        let appeal = await moderationService.submitAppeal(
            userId: userId,
            contentId: contentId,
            moderationActionId: moderationActionId,
            reason: "Content was misunderstood"
        )
        
        XCTAssertEqual(appeal.status, .pending)
        
        // 3. Approve the appeal
        let success = await moderationService.reviewAppeal(
            appealId: appeal.id,
            moderatorId: moderatorId,
            decision: .approved,
            reason: "User was correct"
        )
        
        XCTAssertTrue(success)
        
        // 4. Verify penalty was removed
        let finalPenalties = moderationService.getActivePenalties(for: userId)
        XCTAssertTrue(finalPenalties.isEmpty)
    }
    
    func testModerationWorkflowWithAutomaticPenalties() async {
        let contentId = UUID()
        let moderatorId = moderationService.getActiveModerators().first!.id
        
        // Create a mock queue item with high severity violation
        let mockResult = ModerationResult(
            contentId: contentId,
            contentType: .post,
            status: .flagged,
            flags: [.harassment, .hateSpeech],
            confidence: 0.95,
            severity: .high,
            reason: "Harassment and hate speech detected",
            detectedPII: [],
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
        
        let queueItem = ModerationQueueItem(
            id: UUID(),
            contentId: contentId,
            contentType: .post,
            authorId: UUID(),
            content: "Offensive content",
            imageUrls: [],
            moderationResult: mockResult,
            reportCount: 2,
            priority: .high,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Add to queue
        await ModerationQueueService.shared.addToQueue(
            contentId: contentId,
            contentType: .post,
            authorId: queueItem.authorId,
            content: queueItem.content,
            moderationResult: mockResult
        )
        
        // Process rejection
        let result = await moderationService.processContentApproval(
            contentId: contentId,
            moderatorId: moderatorId,
            action: .reject,
            reason: "Violates community guidelines"
        )
        
        XCTAssertTrue(result.success)
        
        // Verify automatic penalty was applied
        let penalties = moderationService.getActivePenalties(for: queueItem.authorId)
        XCTAssertFalse(penalties.isEmpty)
    }
}

// MARK: - Performance Tests

extension ModerationServiceTests {
    
    func testModerationServicePerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Moderation service performance")
            
            Task {
                let userId = UUID()
                let moderatorId = UUID()
                
                // Test multiple operations
                await moderationService.applyUserPenalty(
                    userId: userId,
                    penalty: .warning,
                    reason: "Performance test",
                    moderatorId: moderatorId
                )
                
                _ = moderationService.getActivePenalties(for: userId)
                
                let appeal = await moderationService.submitAppeal(
                    userId: userId,
                    contentId: UUID(),
                    moderationActionId: UUID(),
                    reason: "Performance test appeal"
                )
                
                _ = await moderationService.reviewAppeal(
                    appealId: appeal.id,
                    moderatorId: moderatorId,
                    decision: .approved,
                    reason: "Performance test"
                )
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}