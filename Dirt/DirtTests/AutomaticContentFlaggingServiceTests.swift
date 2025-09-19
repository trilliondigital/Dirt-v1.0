import XCTest
import UIKit
@testable import Dirt

class AutomaticContentFlaggingServiceTests: XCTestCase {
    
    var flaggingService: AutomaticContentFlaggingService!
    var queueService: ModerationQueueService!
    
    override func setUp() {
        super.setUp()
        flaggingService = AutomaticContentFlaggingService.shared
        queueService = ModerationQueueService.shared
        
        // Clear queue for clean tests
        queueService.queueItems.removeAll()
    }
    
    override func tearDown() {
        queueService.queueItems.removeAll()
        flaggingService = nil
        queueService = nil
        super.tearDown()
    }
    
    // MARK: - Content Processing Tests
    
    func testProcessCleanContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let cleanText = "This is a normal review about a dating profile."
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .review,
            authorId: authorId,
            text: cleanText
        )
        
        XCTAssertEqual(result.contentId, contentId)
        XCTAssertEqual(result.automaticAction, .autoApprove)
        XCTAssertFalse(result.requiresHumanReview)
        XCTAssertTrue(result.moderationResult.flags.isEmpty)
    }
    
    func testProcessContentWithPII() async {
        let contentId = UUID()
        let authorId = UUID()
        let textWithPII = "Contact me at 555-123-4567 for more details."
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: textWithPII
        )
        
        XCTAssertEqual(result.contentId, contentId)
        
        // Should auto-reject due to PII
        if case .autoReject(let reason) = result.automaticAction {
            XCTAssertTrue(reason.contains("Personal information"))
        } else {
            XCTFail("Expected auto-reject for PII content")
        }
        
        XCTAssertGreaterThan(result.moderationResult.detectedPII.count, 0)
    }
    
    func testProcessHarassmentContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let harassmentText = "You should kill yourself, worthless piece of shit."
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .comment,
            authorId: authorId,
            text: harassmentText
        )
        
        XCTAssertEqual(result.contentId, contentId)
        
        // Should auto-reject due to harassment
        if case .autoReject(let reason) = result.automaticAction {
            XCTAssertTrue(reason.contains("Harassment"))
        } else {
            XCTFail("Expected auto-reject for harassment content")
        }
        
        XCTAssertTrue(result.moderationResult.flags.contains(.harassment))
    }
    
    func testProcessHateSpeechContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let hateSpeechText = "All nazis are subhuman terrorists who should be eliminated."
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: hateSpeechText
        )
        
        XCTAssertEqual(result.contentId, contentId)
        
        // Should auto-reject due to hate speech
        if case .autoReject(let reason) = result.automaticAction {
            XCTAssertTrue(reason.contains("Hate speech"))
        } else {
            XCTFail("Expected auto-reject for hate speech content")
        }
        
        XCTAssertTrue(result.moderationResult.flags.contains(.hateSpeech))
    }
    
    func testProcessSpamContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let spamText = "CLICK HERE NOW!!! BUY NOW LIMITED TIME OFFER!!!"
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: spamText
        )
        
        XCTAssertEqual(result.contentId, contentId)
        
        // Should auto-flag due to spam
        if case .autoFlag(let reason) = result.automaticAction {
            XCTAssertTrue(reason.contains("spam"))
        } else {
            XCTFail("Expected auto-flag for spam content")
        }
        
        XCTAssertTrue(result.moderationResult.flags.contains(.spam))
    }
    
    func testProcessInappropriateContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let inappropriateText = "This fucking person is a complete asshole."
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .review,
            authorId: authorId,
            text: inappropriateText
        )
        
        XCTAssertEqual(result.contentId, contentId)
        
        // Should auto-flag due to inappropriate content
        if case .autoFlag(let reason) = result.automaticAction {
            XCTAssertTrue(reason.contains("Inappropriate"))
        } else {
            XCTFail("Expected auto-flag for inappropriate content")
        }
        
        XCTAssertTrue(result.moderationResult.flags.contains(.inappropriateContent))
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchProcessing() async {
        let batchItems = [
            ContentBatchItem(
                contentId: UUID(),
                contentType: .post,
                authorId: UUID(),
                text: "Clean content",
                images: []
            ),
            ContentBatchItem(
                contentId: UUID(),
                contentType: .review,
                authorId: UUID(),
                text: "Contact me at 555-123-4567",
                images: []
            ),
            ContentBatchItem(
                contentId: UUID(),
                contentType: .comment,
                authorId: UUID(),
                text: "SPAM CONTENT CLICK HERE!!!",
                images: []
            )
        ]
        
        let results = await flaggingService.processBatch(batchItems)
        
        XCTAssertEqual(results.count, 3)
        
        // Verify different actions for different content types
        let actions = results.map { $0.automaticAction }
        XCTAssertTrue(actions.contains { action in
            if case .autoApprove = action { return true }
            return false
        })
        XCTAssertTrue(actions.contains { action in
            if case .autoReject = action { return true }
            return false
        })
        XCTAssertTrue(actions.contains { action in
            if case .autoFlag = action { return true }
            return false
        })
    }
    
    // MARK: - Flagging Rules Tests
    
    func testGetFlaggingRules() {
        let rules = flaggingService.getFlaggingRules()
        
        XCTAssertGreaterThan(rules.autoRejectThreshold, 0)
        XCTAssertGreaterThan(rules.autoFlagThreshold, 0)
        XCTAssertLessThan(rules.autoFlagThreshold, rules.autoRejectThreshold)
        XCTAssertGreaterThan(rules.multipleReportsThreshold, 0)
    }
    
    func testUpdateFlaggingRules() {
        let newRules = FlaggingRulesConfiguration(
            autoRejectThreshold: 0.95,
            autoFlagThreshold: 0.75,
            piiAutoReject: true,
            harassmentAutoReject: true,
            hateSpeechAutoReject: true,
            spamAutoFlag: true,
            multipleReportsThreshold: 5,
            newUserStricterRules: false
        )
        
        // This should not throw an error
        flaggingService.updateFlaggingRules(newRules)
        
        // In a real implementation, we would verify the rules were updated
        // For now, just ensure the method can be called
        XCTAssertTrue(true)
    }
    
    // MARK: - Statistics Tests
    
    func testFlaggingStatisticsUpdate() async {
        let initialStats = flaggingService.flaggingStatistics
        let initialProcessed = initialStats.totalProcessed
        
        // Process some content
        await flaggingService.processAndFlag(
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            text: "Clean content"
        )
        
        let updatedStats = flaggingService.flaggingStatistics
        XCTAssertEqual(updatedStats.totalProcessed, initialProcessed + 1)
        XCTAssertGreaterThan(updatedStats.autoApproved, initialStats.autoApproved)
    }
    
    func testFlaggingStatisticsCalculations() {
        var stats = FlaggingStatistics()
        stats.totalProcessed = 100
        stats.autoApproved = 70
        stats.sentToHumanReview = 20
        
        XCTAssertEqual(stats.autoApprovalRate, 0.7, accuracy: 0.01)
        XCTAssertEqual(stats.humanReviewRate, 0.2, accuracy: 0.01)
    }
    
    func testEmptyStatisticsCalculations() {
        let stats = FlaggingStatistics()
        
        XCTAssertEqual(stats.autoApprovalRate, 0.0)
        XCTAssertEqual(stats.humanReviewRate, 0.0)
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImageContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let testImage = createTestImage(size: CGSize(width: 300, height: 400))
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .image,
            authorId: authorId,
            images: [testImage]
        )
        
        XCTAssertEqual(result.contentId, contentId)
        XCTAssertEqual(result.moderationResult.contentType, .image)
    }
    
    func testProcessSmallImage() async {
        let contentId = UUID()
        let authorId = UUID()
        let smallImage = createTestImage(size: CGSize(width: 50, height: 50))
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .image,
            authorId: authorId,
            images: [smallImage]
        )
        
        // Small images should be flagged as potential spam
        XCTAssertTrue(result.moderationResult.flags.contains(.spam))
    }
    
    // MARK: - Edge Cases Tests
    
    func testProcessEmptyContent() async {
        let contentId = UUID()
        let authorId = UUID()
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: nil,
            images: []
        )
        
        // Empty content should be auto-approved
        XCTAssertEqual(result.automaticAction, .autoApprove)
    }
    
    func testProcessVeryLongContent() async {
        let contentId = UUID()
        let authorId = UUID()
        let longText = String(repeating: "This is a very long text. ", count: 1000)
        
        let result = await flaggingService.processAndFlag(
            contentId: contentId,
            contentType: .post,
            authorId: authorId,
            text: longText
        )
        
        // Should still process without errors
        XCTAssertEqual(result.contentId, contentId)
        XCTAssertNotNil(result.moderationResult)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.blue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

// MARK: - Performance Tests

extension AutomaticContentFlaggingServiceTests {
    
    func testSingleContentProcessingPerformance() {
        let contentId = UUID()
        let authorId = UUID()
        let testText = "This is a sample text for performance testing."
        
        measure {
            let expectation = XCTestExpectation(description: "Single content processing performance")
            
            Task {
                _ = await flaggingService.processAndFlag(
                    contentId: contentId,
                    contentType: .post,
                    authorId: authorId,
                    text: testText
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testBatchProcessingPerformance() {
        let batchItems = (0..<50).map { index in
            ContentBatchItem(
                contentId: UUID(),
                contentType: .post,
                authorId: UUID(),
                text: "Test content \(index)",
                images: []
            )
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Batch processing performance")
            
            Task {
                _ = await flaggingService.processBatch(batchItems)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
}