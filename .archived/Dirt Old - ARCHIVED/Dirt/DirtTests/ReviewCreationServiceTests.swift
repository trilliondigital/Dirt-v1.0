import XCTest
@testable import Dirt
import UIKit

@MainActor
class ReviewCreationServiceTests: XCTestCase {
    
    var reviewService: ReviewCreationService!
    var mockAuthorId: UUID!
    var testImages: [UIImage]!
    var testRatings: ReviewRatings!
    
    override func setUp() {
        super.setUp()
        reviewService = ReviewCreationService.shared
        mockAuthorId = UUID()
        
        // Create test images
        testImages = [
            createTestImage(color: .red),
            createTestImage(color: .blue)
        ]
        
        testRatings = ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4)
    }
    
    override func tearDown() {
        reviewService = nil
        mockAuthorId = nil
        testImages = nil
        testRatings = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Review Creation Tests
    
    func testCreateReviewWithValidInput() async throws {
        // Given
        let content = "This is a detailed review with more than 10 characters."
        let tags: [ReviewTag] = [.greenFlag, .goodConversation]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let review = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
            
            // Verify review properties
            XCTAssertEqual(review.authorId, mockAuthorId)
            XCTAssertEqual(review.ratings, testRatings)
            XCTAssertEqual(review.content, content)
            XCTAssertEqual(review.tags, tags.map { $0.rawValue })
            XCTAssertEqual(review.datingApp, datingApp)
            XCTAssertFalse(review.profileScreenshots.isEmpty)
            
        } catch {
            XCTFail("Review creation should succeed with valid input: \(error)")
        }
    }
    
    func testCreateReviewWithEmptyImages() async {
        // Given
        let content = "This is a valid review content."
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: [], // Empty images
                ratings: testRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with empty images")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .invalidImageCount)
        } catch {
            XCTFail("Expected DatingReviewValidationError.invalidImageCount, got: \(error)")
        }
    }
    
    func testCreateReviewWithTooManyImages() async {
        // Given
        let tooManyImages = Array(repeating: createTestImage(color: .red), count: 6)
        let content = "This is a valid review content."
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: tooManyImages,
                ratings: testRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with too many images")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .invalidImageCount)
        } catch {
            XCTFail("Expected DatingReviewValidationError.invalidImageCount, got: \(error)")
        }
    }
    
    func testCreateReviewWithEmptyContent() async {
        // Given
        let emptyContent = ""
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: emptyContent,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with empty content")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .invalidContent)
        } catch {
            XCTFail("Expected DatingReviewValidationError.invalidContent, got: \(error)")
        }
    }
    
    func testCreateReviewWithShortContent() async {
        // Given
        let shortContent = "Short" // Less than 10 characters
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: shortContent,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with short content")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .contentTooShort)
        } catch {
            XCTFail("Expected DatingReviewValidationError.contentTooShort, got: \(error)")
        }
    }
    
    func testCreateReviewWithLongContent() async {
        // Given
        let longContent = String(repeating: "a", count: 5001) // More than 5000 characters
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: longContent,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with long content")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .contentTooLong)
        } catch {
            XCTFail("Expected DatingReviewValidationError.contentTooLong, got: \(error)")
        }
    }
    
    func testCreateReviewWithTooManyTags() async {
        // Given
        let content = "This is a valid review content."
        let tooManyTags = Array(ReviewTag.allCases.prefix(11)) // More than 10 tags
        let datingApp = DatingApp.tinder
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: content,
                selectedTags: tooManyTags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with too many tags")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .tooManyTags)
        } catch {
            XCTFail("Expected DatingReviewValidationError.tooManyTags, got: \(error)")
        }
    }
    
    func testCreateReviewWithInvalidRatings() async {
        // Given
        let content = "This is a valid review content."
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        let invalidRatings = ReviewRatings(photos: 0, bio: 3, conversation: 5, overall: 4) // Invalid rating
        
        // When & Then
        do {
            let _ = try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: invalidRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
            XCTFail("Review creation should fail with invalid ratings")
        } catch let error as DatingReviewValidationError {
            XCTAssertEqual(error, .invalidRating)
        } catch {
            XCTFail("Expected DatingReviewValidationError.invalidRating, got: \(error)")
        }
    }
    
    // MARK: - Draft Management Tests
    
    func testSaveDraft() async throws {
        // Given
        let content = "Draft content"
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.bumble
        
        // When & Then
        do {
            try await reviewService.saveDraft(
                images: testImages,
                ratings: testRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
            // If we reach here, the draft was saved successfully
            XCTAssertTrue(true)
        } catch {
            XCTFail("Draft saving should succeed: \(error)")
        }
    }
    
    func testLoadDrafts() async throws {
        // When
        let drafts = try await reviewService.loadDrafts()
        
        // Then
        XCTAssertNotNil(drafts)
        // In the current implementation, this returns an empty array
        XCTAssertTrue(drafts.isEmpty)
    }
    
    // MARK: - Progress Tracking Tests
    
    func testSubmissionProgressTracking() async throws {
        // Given
        let content = "This is a detailed review with more than 10 characters."
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // Track progress changes
        var progressValues: [Double] = []
        
        // Start the review creation task
        let task = Task {
            try await reviewService.createReview(
                authorId: mockAuthorId,
                images: testImages,
                ratings: testRatings,
                content: content,
                selectedTags: tags,
                datingApp: datingApp
            )
        }
        
        // Monitor progress
        let monitorTask = Task {
            while !task.isCancelled && !task.isCompleted {
                progressValues.append(reviewService.submissionProgress)
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
        
        // Wait for completion
        let _ = try await task.value
        monitorTask.cancel()
        
        // Verify progress was tracked
        XCTAssertTrue(progressValues.count > 0)
        XCTAssertEqual(reviewService.submissionProgress, 1.0)
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() {
        XCTAssertFalse(reviewService.isSubmitting)
        XCTAssertEqual(reviewService.submissionProgress, 0.0)
        XCTAssertNil(reviewService.errorMessage)
        XCTAssertNil(reviewService.successMessage)
    }
    
    func testStateResetAfterSubmission() async throws {
        // Given
        let content = "This is a detailed review with more than 10 characters."
        let tags: [ReviewTag] = [.greenFlag]
        let datingApp = DatingApp.tinder
        
        // When
        let _ = try await reviewService.createReview(
            authorId: mockAuthorId,
            images: testImages,
            ratings: testRatings,
            content: content,
            selectedTags: tags,
            datingApp: datingApp
        )
        
        // Then
        XCTAssertFalse(reviewService.isSubmitting)
        XCTAssertEqual(reviewService.submissionProgress, 0.0)
        XCTAssertNotNil(reviewService.successMessage)
    }
}

// MARK: - Review Ratings Tests

class ReviewRatingsTests: XCTestCase {
    
    func testValidRatings() throws {
        let ratings = ReviewRatings(photos: 1, bio: 3, conversation: 5, overall: 2)
        XCTAssertNoThrow(try ratings.validate())
    }
    
    func testInvalidPhotosRating() {
        let ratings = ReviewRatings(photos: 0, bio: 3, conversation: 5, overall: 2)
        XCTAssertThrowsError(try ratings.validate()) { error in
            XCTAssertTrue(error is DatingReviewValidationError)
        }
    }
    
    func testInvalidBioRating() {
        let ratings = ReviewRatings(photos: 3, bio: 6, conversation: 5, overall: 2)
        XCTAssertThrowsError(try ratings.validate()) { error in
            XCTAssertTrue(error is DatingReviewValidationError)
        }
    }
    
    func testAverageRatingCalculation() {
        let ratings = ReviewRatings(photos: 2, bio: 4, conversation: 3, overall: 5)
        let expectedAverage = (2.0 + 4.0 + 3.0 + 5.0) / 4.0
        XCTAssertEqual(ratings.averageRating, expectedAverage, accuracy: 0.01)
    }
}

// MARK: - Review Tag Tests

class ReviewTagTests: XCTestCase {
    
    func testPositiveTags() {
        let positiveTags: [ReviewTag] = [.greenFlag, .authentic, .goodConversation, .accuratePhotos, .respectful, .metInPerson, .longTermPotential]
        
        for tag in positiveTags {
            XCTAssertTrue(tag.isPositive, "\(tag.rawValue) should be positive")
        }
    }
    
    func testNegativeTags() {
        let negativeTags: [ReviewTag] = [.redFlag, .catfish, .poorConversation, .misleadingPhotos, .disrespectful, .ghosted, .hookupOnly]
        
        for tag in negativeTags {
            XCTAssertFalse(tag.isPositive, "\(tag.rawValue) should be negative")
        }
    }
    
    func testTagDisplayNames() {
        XCTAssertEqual(ReviewTag.greenFlag.displayName, "Green Flag")
        XCTAssertEqual(ReviewTag.redFlag.displayName, "Red Flag")
        XCTAssertEqual(ReviewTag.goodConversation.displayName, "Good Conversation")
    }
}