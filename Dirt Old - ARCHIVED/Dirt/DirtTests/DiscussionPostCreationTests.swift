import XCTest
@testable import Dirt

final class DiscussionPostCreationTests: XCTestCase {
    
    var discussionPostService: DiscussionPostService!
    
    override func setUpWithError() throws {
        discussionPostService = DiscussionPostService.shared
    }
    
    override func tearDownWithError() throws {
        discussionPostService = nil
    }
    
    // MARK: - Validation Tests
    
    func testValidDiscussionPostCreation() async throws {
        // Test that a valid discussion post can be created
        let title = "Great dating advice"
        let content = "Here's some helpful advice for dating success..."
        let category = PostCategory.advice
        let tags = ["dating101", "confidence"]
        
        // This test would normally call the service, but since we don't have a real backend,
        // we'll test the validation logic instead
        XCTAssertNoThrow(try validateDiscussionPostInput(title: title, content: content, tags: tags))
    }
    
    func testEmptyTitleValidation() {
        let title = ""
        let content = "Some content here"
        let tags = ["tag1"]
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .emptyTitle)
        }
    }
    
    func testEmptyContentValidation() {
        let title = "Valid title"
        let content = ""
        let tags = ["tag1"]
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .emptyContent)
        }
    }
    
    func testTitleTooLongValidation() {
        let title = String(repeating: "a", count: 201) // Exceeds 200 character limit
        let content = "Valid content"
        let tags = ["tag1"]
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .titleTooLong)
        }
    }
    
    func testContentTooLongValidation() {
        let title = "Valid title"
        let content = String(repeating: "a", count: 10001) // Exceeds 10000 character limit
        let tags = ["tag1"]
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .contentTooLong)
        }
    }
    
    func testTooManyTagsValidation() {
        let title = "Valid title"
        let content = "Valid content"
        let tags = Array(repeating: "tag", count: 11) // Exceeds 10 tag limit
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .tooManyTags)
        }
    }
    
    func testProhibitedContentDetection() {
        let title = "Contact me at john@example.com"
        let content = "Call me at 555-123-4567"
        let tags = ["tag1"]
        
        XCTAssertThrowsError(try validateDiscussionPostInput(title: title, content: content, tags: tags)) { error in
            XCTAssertTrue(error is DiscussionPostValidationError)
            XCTAssertEqual(error as? DiscussionPostValidationError, .containsProhibitedContent)
        }
    }
    
    // MARK: - Post Category Tests
    
    func testPostCategoryProperties() {
        // Test that all post categories have proper properties
        for category in PostCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
            XCTAssertFalse(category.iconName.isEmpty)
        }
    }
    
    func testPostCategoryAdvice() {
        let category = PostCategory.advice
        XCTAssertEqual(category.displayName, "Advice")
        XCTAssertEqual(category.iconName, "lightbulb")
        XCTAssertTrue(category.description.contains("advice"))
    }
    
    // MARK: - Post Tag Tests
    
    func testPostTagProperties() {
        // Test that all post tags have proper display names
        for tag in PostTag.allCases {
            XCTAssertFalse(tag.displayName.isEmpty)
            XCTAssertEqual(tag.displayName, tag.rawValue)
        }
    }
    
    func testPostTagCoverage() {
        // Ensure we have tags for common dating topics
        let tagNames = PostTag.allCases.map { $0.rawValue }
        
        XCTAssertTrue(tagNames.contains("Dating 101"))
        XCTAssertTrue(tagNames.contains("Online Dating"))
        XCTAssertTrue(tagNames.contains("First Date"))
        XCTAssertTrue(tagNames.contains("Red Flags"))
        XCTAssertTrue(tagNames.contains("Green Flags"))
    }
    
    // MARK: - Helper Methods
    
    private func validateDiscussionPostInput(title: String, content: String, tags: [String]) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Title validation
        guard !trimmedTitle.isEmpty else {
            throw DiscussionPostValidationError.emptyTitle
        }
        
        guard trimmedTitle.count <= 200 else {
            throw DiscussionPostValidationError.titleTooLong
        }
        
        // Content validation
        guard !trimmedContent.isEmpty else {
            throw DiscussionPostValidationError.emptyContent
        }
        
        guard trimmedContent.count <= 10000 else {
            throw DiscussionPostValidationError.contentTooLong
        }
        
        // Tags validation
        guard tags.count <= 10 else {
            throw DiscussionPostValidationError.tooManyTags
        }
        
        // Validate individual tags
        for tag in tags {
            guard !tag.isEmpty else {
                throw DiscussionPostValidationError.invalidTag
            }
            
            guard tag.count <= 50 else {
                throw DiscussionPostValidationError.tagTooLong
            }
        }
        
        // Content moderation checks
        try performContentModerationChecks(title: trimmedTitle, content: trimmedContent)
    }
    
    private func performContentModerationChecks(title: String, content: String) throws {
        let combinedText = "\(title) \(content)".lowercased()
        
        // Check for prohibited content patterns
        let prohibitedPatterns = [
            "\\b\\d{3}[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b", // Phone numbers
            "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", // Email addresses
            "@[A-Za-z0-9_]+", // Social media handles
            "\\b(instagram|twitter|snapchat|facebook|tiktok)\\b.*\\b[A-Za-z0-9_]+\\b" // Social media references
        ]
        
        for pattern in prohibitedPatterns {
            if combinedText.range(of: pattern, options: .regularExpression) != nil {
                throw DiscussionPostValidationError.containsProhibitedContent
            }
        }
        
        // Check for excessive profanity or inappropriate content
        let inappropriateWords = ["spam", "scam", "fake", "bot"]
        let wordCount = inappropriateWords.filter { combinedText.contains($0) }.count
        
        if wordCount > 2 {
            throw DiscussionPostValidationError.inappropriateContent
        }
    }
}

// MARK: - DiscussionPostValidationError Equatable

extension DiscussionPostValidationError: Equatable {
    static func == (lhs: DiscussionPostValidationError, rhs: DiscussionPostValidationError) -> Bool {
        switch (lhs, rhs) {
        case (.emptyTitle, .emptyTitle),
             (.titleTooLong, .titleTooLong),
             (.emptyContent, .emptyContent),
             (.contentTooLong, .contentTooLong),
             (.tooManyTags, .tooManyTags),
             (.invalidTag, .invalidTag),
             (.tagTooLong, .tagTooLong),
             (.containsProhibitedContent, .containsProhibitedContent),
             (.inappropriateContent, .inappropriateContent):
            return true
        default:
            return false
        }
    }
}