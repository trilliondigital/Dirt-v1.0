import XCTest
import UIKit
@testable import Dirt

class ModerationQueueServiceTests: XCTestCase {
    
    var queueService: ModerationQueueService!
    var mockModerationResult: ModerationResult!
    
    override func setUp() {
        super.setUp()
        queueService = ModerationQueueService.shared
        
        // Clear existing queue items for clean tests
        queueService.queueItems.removeAll()
        
        // Create mock moderation result
        mockModerationResult = ModerationResult(
            contentId: UUID(),
            contentType: .post,
            status: .pending,
            flags: [.inappropriateContent],
            confidence: 0.8,
            severity: .medium,
            reason: "Inappropriate content detected",
            detectedPII: [],
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
    }
    
    override func tearDown() {
        queueService.queueItems.removeAll()
        queueService = nil
        mockModerationResult = nil
        super.tearDown()
    }
    
    // MARK: - Queue Management Tests
    
    func testAddToQueue() async {
        let contentId = UUID()
        let authorId = UUID()
        
        await queueService.addToQueue(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            content: "Test content",
            moderationResult: mockModerationResult
        )
        
        XCTAssertEqual(queueService.queueItems.count, 1)
        
        let queueItem = queueService.queueItems.first!
        XCTAssertEqual(queueItem.contentId, contentId)
        XCTAssertEqual(queueItem.authorId, authorId)
        XCTAssertEqual(queueItem.contentType, .post)
        XCTAssertEqual(queueItem.content, "Test content")
    }
    
    func testQueueSorting() async {
        // Add items with different priorities
        let criticalResult = createModerationResult(severity: .critical, flags: [.hateSpeech])
        let lowResult = createModerationResult(severity: .low, flags: [.spam])
        let highResult = createModerationResult(severity: .high, flags: [.harassment])
        
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: lowResult
        )
        
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: criticalResult
        )
        
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: highResult
        )
        
        // Verify sorting: critical first, then high, then low
        XCTAssertEqual(queueService.queueItems[0].priority, .critical)
        XCTAssertEqual(queueService.queueItems[1].priority, .high)
        XCTAssertEqual(queueService.queueItems[2].priority, .low)
    }
    
    func testRemoveFromQueue() async {
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: mockModerationResult
        )
        
        let itemId = queueService.queueItems.first!.id
        queueService.removeFromQueue(itemId: itemId)
        
        XCTAssertTrue(queueService.queueItems.isEmpty)
    }
    
    // MARK: - Content Processing Tests
    
    func testProcessCleanContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let cleanText = "This is a normal, clean review."
        
        let result = await queueService.processContent(
            contentId: contentId,
            contentType: .review,
            authorId: authorId,
            text: cleanText
        )
        
        XCTAssertEqual(result.status, .approved)
        XCTAssertTrue(result.flags.isEmpty)
        // Clean content should not be added to queue
        XCTAssertTrue(queueService.queueItems.isEmpty)
    }
    
    func testProcessProblematicContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let problematicText = "This is fucking inappropriate content"
        
        let result = await queueService.processContent(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: problematicText
        )
        
        XCTAssertTrue(result.flags.contains(.inappropriateContent))
        // Problematic content should be added to queue
        XCTAssertEqual(queueService.queueItems.count, 1)
        XCTAssertEqual(queueService.queueItems.first?.contentId, contentId)
    }
    
    func testProcessContentWithPII() async {
        let contentId = UUID()
        let authorId = UUID()
        let textWithPII = "Contact me at 555-123-4567"
        
        let result = await queueService.processContent(
            contentId: contentId,
            contentType: .comment,
            authorId: authorId,
            text: textWithPII
        )
        
        XCTAssertGreaterThan(result.detectedPII.count, 0)
        XCTAssertEqual(result.status, .flagged)
        // PII content should be added to queue
        XCTAssertEqual(queueService.queueItems.count, 1)
    }
    
    // MARK: - Queue Filtering Tests
    
    func testGetQueueItemsByPriority() async {
        // Add items with different priorities
        await addMockQueueItems()
        
        let highPriorityItems = queueService.getQueueItems(priority: .high)
        let lowPriorityItems = queueService.getQueueItems(priority: .low)
        
        XCTAssertTrue(highPriorityItems.allSatisfy { $0.priority == .high })
        XCTAssertTrue(lowPriorityItems.allSatisfy { $0.priority == .low })
    }
    
    func testGetQueueItemsByContentType() async {
        await addMockQueueItems()
        
        let reviewItems = queueService.getQueueItems(contentType: .review)
        let postItems = queueService.getQueueItems(contentType: .post)
        
        XCTAssertTrue(reviewItems.allSatisfy { $0.contentType == .review })
        XCTAssertTrue(postItems.allSatisfy { $0.contentType == .post })
    }
    
    func testGetQueueItemsByStatus() async {
        await addMockQueueItems()
        
        let pendingItems = queueService.getQueueItems(status: .pending)
        let flaggedItems = queueService.getQueueItems(status: .flagged)
        
        XCTAssertTrue(pendingItems.allSatisfy { $0.moderationResult.status == .pending })
        XCTAssertTrue(flaggedItems.allSatisfy { $0.moderationResult.status == .flagged })
    }
    
    func testGetQueueItemsWithLimit() async {
        await addMockQueueItems()
        
        let limitedItems = queueService.getQueueItems(limit: 2)
        
        XCTAssertLessThanOrEqual(limitedItems.count, 2)
    }
    
    // MARK: - Moderation Action Tests
    
    func testUpdateQueueItemApprove() async {
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: mockModerationResult
        )
        
        let itemId = queueService.queueItems.first!.id
        let moderatorId = UUID()
        
        await queueService.updateQueueItem(
            itemId: itemId,
            action: .approve,
            moderatorId: moderatorId,
            reason: "Content is acceptable"
        )
        
        // Item should be removed from queue after approval
        XCTAssertTrue(queueService.queueItems.isEmpty)
    }
    
    func testUpdateQueueItemReject() async {
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: mockModerationResult
        )
        
        let itemId = queueService.queueItems.first!.id
        let moderatorId = UUID()
        
        await queueService.updateQueueItem(
            itemId: itemId,
            action: .reject,
            moderatorId: moderatorId,
            reason: "Violates community guidelines"
        )
        
        // Item should be removed from queue after rejection
        XCTAssertTrue(queueService.queueItems.isEmpty)
    }
    
    func testUpdateQueueItemFlag() async {
        await queueService.addToQueue(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            moderationResult: mockModerationResult
        )
        
        let itemId = queueService.queueItems.first!.id
        let moderatorId = UUID()
        
        await queueService.updateQueueItem(
            itemId: itemId,
            action: .flag,
            moderatorId: moderatorId,
            reason: "Needs additional review"
        )
        
        // Item should remain in queue when flagged
        XCTAssertEqual(queueService.queueItems.count, 1)
        XCTAssertEqual(queueService.queueItems.first?.moderationResult.status, .flagged)
    }
    
    // MARK: - Statistics Tests
    
    func testQueueStatistics() async {
        await addMockQueueItems()
        
        let stats = queueService.getQueueStatistics()
        
        XCTAssertGreaterThan(stats.totalItems, 0)
        XCTAssertGreaterThanOrEqual(stats.highPriorityItems, 0)
        XCTAssertGreaterThanOrEqual(stats.pendingItems, 0)
        XCTAssertGreaterThanOrEqual(stats.flaggedItems, 0)
        XCTAssertGreaterThanOrEqual(stats.averageWaitTimeMinutes, 0)
    }
    
    func testEmptyQueueStatistics() {
        let stats = queueService.getQueueStatistics()
        
        XCTAssertEqual(stats.totalItems, 0)
        XCTAssertEqual(stats.highPriorityItems, 0)
        XCTAssertEqual(stats.pendingItems, 0)
        XCTAssertEqual(stats.flaggedItems, 0)
        XCTAssertEqual(stats.averageWaitTimeMinutes, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createModerationResult(
        severity: ModerationSeverity,
        flags: [ModerationFlag],
        status: ModerationStatus = .pending
    ) -> ModerationResult {
        return ModerationResult(
            contentId: UUID(),
            contentType: .post,
            status: status,
            flags: flags,
            confidence: 0.8,
            severity: severity,
            reason: flags.first?.description,
            detectedPII: [],
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
    }
    
    private func addMockQueueItems() async {
        let items = [
            (ContentType.review, ModerationPriority.high, ModerationStatus.pending),
            (ContentType.post, ModerationPriority.low, ModerationStatus.flagged),
            (ContentType.comment, ModerationPriority.critical, ModerationStatus.pending),
            (ContentType.review, ModerationPriority.medium, ModerationStatus.pending)
        ]
        
        for (contentType, priority, status) in items {
            let severity: ModerationSeverity
            switch priority {
            case .critical:
                severity = .critical
            case .high:
                severity = .high
            case .medium:
                severity = .medium
            case .low:
                severity = .low
            }
            
            let result = createModerationResult(
                severity: severity,
                flags: [.inappropriateContent],
                status: status
            )
            
            await queueService.addToQueue(
                contentId: UUID(),
                contentType: contentType,
                authorId: UUID(),
                moderationResult: result
            )
        }
    }
}

// MARK: - Performance Tests

extension ModerationQueueServiceTests {
    
    func testQueuePerformanceWithManyItems() async {
        measure {
            let expectation = XCTestExpectation(description: "Queue performance test")
            
            Task {
                // Add many items to test performance
                for _ in 0..<100 {
                    await queueService.addToQueue(
                        contentId: UUID(),
                        contentType: .post,
                        authorId: UUID(),
                        moderationResult: mockModerationResult
                    )
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testFilteringPerformance() async {
        // Add many items first
        for _ in 0..<1000 {
            await queueService.addToQueue(
                contentId: UUID(),
                contentType: .post,
                authorId: UUID(),
                moderationResult: mockModerationResult
            )
        }
        
        measure {
            _ = queueService.getQueueItems(priority: .high, limit: 50)
        }
    }
}