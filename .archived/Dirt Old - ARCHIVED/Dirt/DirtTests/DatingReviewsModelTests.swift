import XCTest
@testable import Dirt

class DatingReviewsModelTests: XCTestCase {
    
    // MARK: - User Model Tests
    func testUserModelCreation() {
        let user = User(
            anonymousUsername: "testuser123",
            phoneNumberHash: "hashed_phone_number"
        )
        
        XCTAssertEqual(user.anonymousUsername, "testuser123")
        XCTAssertEqual(user.phoneNumberHash, "hashed_phone_number")
        XCTAssertEqual(user.reputation, 0)
        XCTAssertFalse(user.isVerified)
        XCTAssertFalse(user.isBanned)
        XCTAssertTrue(user.notificationPreferences.repliesEnabled)
    }
    
    func testUserValidation() throws {
        let validUser = User(
            anonymousUsername: "validuser",
            phoneNumberHash: "valid_hash"
        )
        
        XCTAssertNoThrow(try validUser.validate())
        
        let invalidUser = User(
            anonymousUsername: "",
            phoneNumberHash: "valid_hash"
        )
        
        XCTAssertThrowsError(try invalidUser.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidUsername)
        }
    }
    
    func testUserPermissions() {
        var user = User(
            anonymousUsername: "testuser",
            phoneNumberHash: "hash",
            reputation: 50,
            isVerified: true
        )
        
        XCTAssertTrue(user.isActive)
        XCTAssertTrue(user.canPost)
        XCTAssertFalse(user.canModerate)
        
        user.reputation = 100
        XCTAssertTrue(user.canModerate)
        
        user.isBanned = true
        XCTAssertFalse(user.isActive)
        XCTAssertFalse(user.canPost)
    }
    
    // MARK: - Review Model Tests
    func testReviewModelCreation() {
        let ratings = ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4)
        let review = Review(
            authorId: UUID(),
            profileScreenshots: ["url1", "url2"],
            ratings: ratings,
            content: "Great conversation, authentic photos",
            tags: ["Green Flag", "Good Conversation"],
            datingApp: .tinder
        )
        
        XCTAssertEqual(review.ratings.photos, 4)
        XCTAssertEqual(review.ratings.averageRating, 4.0)
        XCTAssertEqual(review.tags.count, 2)
        XCTAssertEqual(review.datingApp, .tinder)
        XCTAssertTrue(review.isVisible)
    }
    
    func testReviewRatingsValidation() throws {
        let validRatings = ReviewRatings(photos: 3, bio: 4, conversation: 2, overall: 3)
        XCTAssertNoThrow(try validRatings.validate())
        
        let invalidRatings = ReviewRatings(photos: 6, bio: 4, conversation: 2, overall: 3)
        XCTAssertThrowsError(try invalidRatings.validate()) { error in
            XCTAssertEqual(error as? ValidationError, ValidationError.invalidRating)
        }
    }
    
    func testReviewNetScore() {
        var review = Review(
            authorId: UUID(),
            profileScreenshots: ["url1"],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Test review",
            tags: [],
            datingApp: .bumble,
            upvotes: 10,
            downvotes: 3
        )
        
        XCTAssertEqual(review.netScore, 7)
        
        review.upvotes = 5
        review.downvotes = 8
        XCTAssertEqual(review.netScore, -3)
    }
    
    // MARK: - Post Model Tests
    func testPostModelCreation() {
        let post = DatingReviewPost(
            authorId: UUID(),
            title: "Dating advice needed",
            content: "Looking for advice on first date conversations",
            category: .advice,
            tags: ["First Date", "Conversation"]
        )
        
        XCTAssertEqual(post.title, "Dating advice needed")
        XCTAssertEqual(post.category, .advice)
        XCTAssertEqual(post.tags.count, 2)
        XCTAssertEqual(post.upvotes, 0)
        XCTAssertEqual(post.commentCount, 0)
    }
    
    func testPostEngagementScore() {
        let post = DatingReviewPost(
            authorId: UUID(),
            title: "Test Post",
            content: "Test content",
            category: .experience,
            upvotes: 10,
            downvotes: 2,
            commentCount: 5
        )
        
        let engagementScore = post.engagementScore
        XCTAssertGreaterThan(engagementScore, 0)
        
        // Engagement score should include net votes + weighted comments
        let expectedBase = Double(post.netScore + (post.commentCount * 2))
        XCTAssertGreaterThan(engagementScore, expectedBase * 0.1) // With time decay
    }
    
    // MARK: - Comment Model Tests
    func testCommentModelCreation() {
        let comment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: "Great advice, thanks for sharing!"
        )
        
        XCTAssertEqual(comment.contentType, .post)
        XCTAssertTrue(comment.isTopLevel)
        XCTAssertFalse(comment.isReply)
        XCTAssertEqual(comment.upvotes, 0)
        XCTAssertEqual(comment.replyCount, 0)
    }
    
    func testCommentThreading() {
        let parentComment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: "Parent comment"
        )
        
        let replyComment = Comment(
            authorId: UUID(),
            parentId: parentComment.id,
            contentId: UUID(),
            contentType: .comment,
            content: "Reply to parent"
        )
        
        XCTAssertTrue(parentComment.isTopLevel)
        XCTAssertFalse(parentComment.isReply)
        
        XCTAssertFalse(replyComment.isTopLevel)
        XCTAssertTrue(replyComment.isReply)
        XCTAssertEqual(replyComment.parentId, parentComment.id)
    }
    
    // MARK: - Serialization Tests
    func testUserSerialization() throws {
        let user = User(
            anonymousUsername: "testuser",
            phoneNumberHash: "hash123"
        )
        
        let json = try user.toJSON()
        XCTAssertNotNil(json["id"])
        XCTAssertEqual(json["anonymousUsername"] as? String, "testuser")
        
        let deserializedUser = try User.fromJSON(json)
        XCTAssertEqual(deserializedUser.anonymousUsername, user.anonymousUsername)
        XCTAssertEqual(deserializedUser.phoneNumberHash, user.phoneNumberHash)
    }
    
    func testReviewSerialization() throws {
        let ratings = ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4)
        let review = Review(
            authorId: UUID(),
            profileScreenshots: ["url1"],
            ratings: ratings,
            content: "Test review",
            tags: ["tag1"],
            datingApp: .hinge
        )
        
        let json = try review.toJSON()
        XCTAssertNotNil(json["id"])
        XCTAssertEqual(json["content"] as? String, "Test review")
        
        let deserializedReview = try Review.fromJSON(json)
        XCTAssertEqual(deserializedReview.content, review.content)
        XCTAssertEqual(deserializedReview.datingApp, review.datingApp)
    }
    
    // MARK: - Validation Service Tests
    func testModelValidationService() throws {
        let validationService = ModelValidationService.shared
        
        let validUser = User(
            anonymousUsername: "validuser",
            phoneNumberHash: "valid_hash"
        )
        
        XCTAssertNoThrow(try validationService.validateUser(validUser))
        
        let invalidUser = User(
            anonymousUsername: "ad", // Too short
            phoneNumberHash: "valid_hash"
        )
        
        XCTAssertThrowsError(try validationService.validateUser(invalidUser))
    }
    
    func testContentModerationValidation() {
        let validationService = ModelValidationService.shared
        
        let cleanContent = "This is a normal dating review"
        let flags = validationService.validateForModeration(cleanContent)
        XCTAssertTrue(flags.isEmpty)
        
        let suspiciousContent = "Contact me at john@email.com or call 555-123-4567"
        let personalInfoFlags = validationService.validateForModeration(suspiciousContent)
        XCTAssertTrue(personalInfoFlags.contains(.personalInformation))
    }
}