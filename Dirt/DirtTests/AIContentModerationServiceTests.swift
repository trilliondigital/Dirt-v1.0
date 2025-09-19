import XCTest
import UIKit
@testable import Dirt

class AIContentModerationServiceTests: XCTestCase {
    
    var moderationService: AIContentModerationService!
    
    override func setUp() {
        super.setUp()
        moderationService = AIContentModerationService.shared
    }
    
    override func tearDown() {
        moderationService = nil
        super.tearDown()
    }
    
    // MARK: - Text Moderation Tests
    
    func testCleanTextModeration() async {
        let cleanText = "This is a normal review about a dating profile. The person seems nice and has good photos."
        
        let result = await moderationService.moderateText(cleanText)
        
        XCTAssertEqual(result.status, .approved)
        XCTAssertTrue(result.flags.isEmpty)
        XCTAssertGreaterThan(result.confidence, 0.8)
        XCTAssertEqual(result.severity, .low)
    }
    
    func testInappropriateContentDetection() async {
        let inappropriateText = "This person is a fucking asshole and a complete bitch."
        
        let result = await moderationService.moderateText(inappropriateText)
        
        XCTAssertTrue(result.flags.contains(.inappropriateContent))
        XCTAssertLessThan(result.confidence, 0.9)
        XCTAssertNotEqual(result.status, .approved)
    }
    
    func testHarassmentDetection() async {
        let harassmentText = "You should kill yourself, you worthless piece of shit."
        
        let result = await moderationService.moderateText(harassmentText)
        
        XCTAssertTrue(result.flags.contains(.harassment))
        XCTAssertEqual(result.severity, .high)
        XCTAssertEqual(result.status, .rejected)
    }
    
    func testHateSpeechDetection() async {
        let hateSpeechText = "All nazis should be eliminated, they are subhuman terrorists."
        
        let result = await moderationService.moderateText(hateSpeechText)
        
        XCTAssertTrue(result.flags.contains(.hateSpeech))
        XCTAssertEqual(result.severity, .high)
        XCTAssertGreaterThan(result.confidence, 0.9)
    }
    
    func testSpamDetection() async {
        let spamText = "CLICK HERE NOW!!! BUY NOW LIMITED TIME!!!"
        
        let result = await moderationService.moderateText(spamText)
        
        XCTAssertTrue(result.flags.contains(.spam))
        XCTAssertLessThan(result.confidence, 0.8)
    }
    
    func testSexualContentDetection() async {
        let sexualText = "Looking for someone to have sex with, send me nude pics of your pussy."
        
        let result = await moderationService.moderateText(sexualText)
        
        XCTAssertTrue(result.flags.contains(.sexualContent))
        XCTAssertEqual(result.severity, .medium)
    }
    
    func testViolentContentDetection() async {
        let violentText = "I want to murder someone and stab them with a knife, blood everywhere."
        
        let result = await moderationService.moderateText(violentText)
        
        XCTAssertTrue(result.flags.contains(.violentContent))
        XCTAssertEqual(result.severity, .medium)
    }
    
    // MARK: - PII Detection Tests
    
    func testPhoneNumberDetection() async {
        let textWithPhone = "Call me at 555-123-4567 or (555) 987-6543"
        
        let result = await moderationService.moderateText(textWithPhone)
        
        XCTAssertEqual(result.detectedPII.count, 2)
        XCTAssertTrue(result.detectedPII.allSatisfy { $0.type == .phoneNumber })
        XCTAssertEqual(result.status, .flagged)
    }
    
    func testEmailDetection() async {
        let textWithEmail = "Contact me at john.doe@example.com for more info"
        
        let result = await moderationService.moderateText(textWithEmail)
        
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.type, .email)
        XCTAssertEqual(result.detectedPII.first?.text, "john.doe@example.com")
    }
    
    func testSocialMediaHandleDetection() async {
        let textWithSocial = "Follow me @johndoe on Instagram or instagram.com/johndoe123"
        
        let result = await moderationService.moderateText(textWithSocial)
        
        XCTAssertGreaterThanOrEqual(result.detectedPII.count, 1)
        XCTAssertTrue(result.detectedPII.contains { $0.type == .socialMedia })
    }
    
    func testNameDetection() async {
        let textWithName = "My name is John Smith, call me John"
        
        let result = await moderationService.moderateText(textWithName)
        
        XCTAssertGreaterThanOrEqual(result.detectedPII.count, 1)
        XCTAssertTrue(result.detectedPII.contains { $0.type == .name })
    }
    
    func testAddressDetection() async {
        let textWithAddress = "I live at 123 Main Street, zip code 12345"
        
        let result = await moderationService.moderateText(textWithAddress)
        
        XCTAssertGreaterThanOrEqual(result.detectedPII.count, 1)
        XCTAssertTrue(result.detectedPII.contains { $0.type == .address })
    }
    
    func testCreditCardDetection() async {
        let textWithCC = "My card number is 1234-5678-9012-3456"
        
        let result = await moderationService.moderateText(textWithCC)
        
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.type, .creditCard)
    }
    
    func testSSNDetection() async {
        let textWithSSN = "My SSN is 123-45-6789"
        
        let result = await moderationService.moderateText(textWithSSN)
        
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.type, .ssn)
    }
    
    func testInvalidSSNRejection() async {
        let textWithInvalidSSN = "Invalid SSN: 000-00-0000 or 666-12-3456"
        
        let result = await moderationService.moderateText(textWithInvalidSSN)
        
        // Should not detect invalid SSN patterns
        XCTAssertFalse(result.detectedPII.contains { $0.type == .ssn })
    }
    
    // MARK: - Image Moderation Tests
    
    func testImageModerationWithValidImage() async {
        let testImage = createTestImage(size: CGSize(width: 300, height: 400))
        
        let result = await moderationService.moderateImage(testImage)
        
        XCTAssertEqual(result.contentType, .image)
        XCTAssertNotNil(result.contentId)
    }
    
    func testImageModerationWithSmallImage() async {
        let smallImage = createTestImage(size: CGSize(width: 50, height: 50))
        
        let result = await moderationService.moderateImage(smallImage)
        
        XCTAssertTrue(result.flags.contains(.spam))
        XCTAssertLessThan(result.confidence, 0.8)
    }
    
    // MARK: - Review Moderation Tests
    
    func testReviewModerationWithCleanContent() async {
        let cleanText = "Great profile, seems like a nice person with good photos."
        let testImages = [createTestImage(size: CGSize(width: 300, height: 400))]
        
        let result = await moderationService.moderateReview(text: cleanText, images: testImages)
        
        XCTAssertEqual(result.contentType, .review)
        XCTAssertEqual(result.status, .approved)
        XCTAssertTrue(result.flags.isEmpty)
    }
    
    func testReviewModerationWithPII() async {
        let textWithPII = "Contact this person at 555-123-4567"
        let testImages = [createTestImage(size: CGSize(width: 300, height: 400))]
        
        let result = await moderationService.moderateReview(text: textWithPII, images: testImages)
        
        XCTAssertGreaterThan(result.detectedPII.count, 0)
        XCTAssertEqual(result.status, .flagged)
    }
    
    func testReviewModerationWithMultipleViolations() async {
        let problematicText = "This fucking bitch gave me her number 555-123-4567, what a whore"
        let testImages = [createTestImage(size: CGSize(width: 300, height: 400))]
        
        let result = await moderationService.moderateReview(text: problematicText, images: testImages)
        
        XCTAssertGreaterThan(result.flags.count, 1)
        XCTAssertGreaterThan(result.detectedPII.count, 0)
        XCTAssertNotEqual(result.status, .approved)
    }
    
    // MARK: - PII Blurring Tests
    
    func testPIIBlurring() {
        let testImage = createTestImage(size: CGSize(width: 300, height: 400))
        let piiDetections = [
            PIIDetection(
                type: .phoneNumber,
                location: CGRect(x: 50, y: 50, width: 100, height: 20),
                confidence: 0.9,
                text: "555-123-4567"
            ),
            PIIDetection(
                type: .email,
                location: CGRect(x: 50, y: 100, width: 150, height: 20),
                confidence: 0.95,
                text: "test@example.com"
            )
        ]
        
        let blurredImage = moderationService.blurPIIInImage(testImage, piiDetections: piiDetections)
        
        XCTAssertNotNil(blurredImage)
        XCTAssertEqual(blurredImage.size, testImage.size)
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

extension AIContentModerationServiceTests {
    
    func testTextModerationPerformance() {
        let testText = "This is a sample text for performance testing. It contains some content that needs to be analyzed for various policy violations and PII detection."
        
        measure {
            let expectation = XCTestExpectation(description: "Text moderation performance")
            
            Task {
                _ = await moderationService.moderateText(testText)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testImageModerationPerformance() {
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        
        measure {
            let expectation = XCTestExpectation(description: "Image moderation performance")
            
            Task {
                _ = await moderationService.moderateImage(testImage)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}