import XCTest
import SwiftUI
@testable import Dirt

/// Tests for content display components including review cards, discussion posts, and comment threads
final class ContentDisplayComponentsTests: XCTestCase {
    
    // MARK: - Review Card Tests
    
    func testReviewCardDisplaysCorrectInformation() {
        // Given
        let review = Review(
            authorId: UUID(),
            profileScreenshots: ["https://example.com/screenshot1.jpg"],
            ratings: ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4),
            content: "Great conversation and authentic photos.",
            tags: ["Green Flag", "Authentic"],
            datingApp: .tinder,
            upvotes: 15,
            downvotes: 2,
            commentCount: 8
        )
        
        // Then
        XCTAssertEqual(review.ratings.overall, 4)
        XCTAssertEqual(review.datingApp, .tinder)
        XCTAssertEqual(review.upvotes, 15)
        XCTAssertEqual(review.downvotes, 2)
        XCTAssertEqual(review.commentCount, 8)
        XCTAssertEqual(review.netScore, 13)
        XCTAssertTrue(review.tags.contains("Green Flag"))
        XCTAssertTrue(review.tags.contains("Authentic"))
    }
    
    func testReviewRatingsCalculation() {
        // Given
        let ratings = ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4)
        
        // When
        let averageRating = ratings.averageRating
        
        // Then
        XCTAssertEqual(averageRating, 4.0, accuracy: 0.01)
    }
    
    func testReviewVisibility() {
        // Given
        let approvedReview = Review(
            authorId: UUID(),
            profileScreenshots: [],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Test content",
            tags: [],
            datingApp: .tinder,
            moderationStatus: .approved
        )
        
        let pendingReview = Review(
            authorId: UUID(),
            profileScreenshots: [],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Test content",
            tags: [],
            datingApp: .tinder,
            moderationStatus: .pending
        )
        
        // Then
        XCTAssertTrue(approvedReview.isVisible)
        XCTAssertFalse(pendingReview.isVisible)
    }
    
    // MARK: - Discussion Post Tests
    
    func testDiscussionPostEngagementScore() {
        // Given
        let post = DatingReviewPost(
            authorId: UUID(),
            title: "Test Post",
            content: "Test content",
            category: .advice,
            upvotes: 10,
            downvotes: 2,
            commentCount: 5
        )
        
        // When
        let engagementScore = post.engagementScore
        
        // Then
        XCTAssertGreaterThan(engagementScore, 0)
        // Engagement score should factor in net votes and comments
        let expectedMinScore = Double(post.netScore + (post.commentCount * 2))
        XCTAssertGreaterThanOrEqual(engagementScore, expectedMinScore * 0.1) // Account for time decay
    }
    
    func testPostCategoryProperties() {
        // Given
        let categories: [PostCategory] = [.advice, .question, .success, .rant]
        
        // Then
        for category in categories {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
            XCTAssertFalse(category.iconName.isEmpty)
        }
    }
    
    func testPostValidation() throws {
        // Given
        let validPost = DatingReviewPost(
            authorId: UUID(),
            title: "Valid Title",
            content: "Valid content that meets requirements",
            category: .advice
        )
        
        let invalidTitlePost = DatingReviewPost(
            authorId: UUID(),
            title: "",
            content: "Valid content",
            category: .advice
        )
        
        let invalidContentPost = DatingReviewPost(
            authorId: UUID(),
            title: "Valid Title",
            content: "",
            category: .advice
        )
        
        // Then
        XCTAssertNoThrow(try validPost.validate())
        XCTAssertThrowsError(try invalidTitlePost.validate())
        XCTAssertThrowsError(try invalidContentPost.validate())
    }
    
    // MARK: - Comment Thread Tests
    
    func testCommentThreading() {
        // Given
        let parentComment = Comment(
            id: UUID(),
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: "Parent comment"
        )
        
        let replyComment = Comment(
            authorId: UUID(),
            parentId: parentComment.id,
            contentId: UUID(),
            contentType: .post,
            content: "Reply to parent"
        )
        
        // Then
        XCTAssertTrue(parentComment.isTopLevel)
        XCTAssertFalse(parentComment.isReply)
        XCTAssertFalse(replyComment.isTopLevel)
        XCTAssertTrue(replyComment.isReply)
        XCTAssertEqual(replyComment.parentId, parentComment.id)
    }
    
    func testCommentValidation() throws {
        // Given
        let validComment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: "This is a valid comment with appropriate length."
        )
        
        let emptyComment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: ""
        )
        
        let tooLongComment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: String(repeating: "a", count: 2001)
        )
        
        // Then
        XCTAssertNoThrow(try validComment.validate())
        XCTAssertThrowsError(try emptyComment.validate())
        XCTAssertThrowsError(try tooLongComment.validate())
    }
    
    func testCommentNetScore() {
        // Given
        let comment = Comment(
            authorId: UUID(),
            contentId: UUID(),
            contentType: .post,
            content: "Test comment",
            upvotes: 15,
            downvotes: 3
        )
        
        // Then
        XCTAssertEqual(comment.netScore, 12)
    }
    
    // MARK: - Vote System Tests
    
    func testVoteTypeValues() {
        // Then
        XCTAssertEqual(VoteType.upvote.value, 1)
        XCTAssertEqual(VoteType.downvote.value, -1)
        XCTAssertEqual(VoteType.none.value, 0)
    }
    
    func testUserVoteCreation() {
        // Given
        let userId = UUID()
        let contentId = UUID()
        
        let vote = UserVote(
            userId: userId,
            contentId: contentId,
            contentType: .review,
            voteType: .upvote
        )
        
        // Then
        XCTAssertEqual(vote.userId, userId)
        XCTAssertEqual(vote.contentId, contentId)
        XCTAssertEqual(vote.contentType, .review)
        XCTAssertEqual(vote.voteType, .upvote)
    }
    
    // MARK: - Content Item Tests
    
    func testContentItemProperties() {
        // Given
        let review = Review(
            authorId: UUID(),
            profileScreenshots: [],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Test review",
            tags: [],
            datingApp: .tinder,
            upvotes: 10,
            downvotes: 2
        )
        
        let post = DatingReviewPost(
            authorId: UUID(),
            title: "Test Post",
            content: "Test content",
            category: .advice,
            upvotes: 15,
            downvotes: 3
        )
        
        let reviewItem = ContentItem.review(review)
        let postItem = ContentItem.post(post)
        
        // Then
        XCTAssertEqual(reviewItem.id, review.id)
        XCTAssertEqual(postItem.id, post.id)
        XCTAssertEqual(reviewItem.netScore, 8)
        XCTAssertEqual(postItem.netScore, 12)
        XCTAssertGreaterThan(reviewItem.engagementScore, 0)
        XCTAssertGreaterThan(postItem.engagementScore, 0)
    }
    
    func testContentItemControversyScore() {
        // Given
        let controversialReview = Review(
            authorId: UUID(),
            profileScreenshots: [],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Controversial review",
            tags: [],
            datingApp: .tinder,
            upvotes: 50,
            downvotes: 45 // Almost equal votes = controversial
        )
        
        let nonControversialReview = Review(
            authorId: UUID(),
            profileScreenshots: [],
            ratings: ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3),
            content: "Non-controversial review",
            tags: [],
            datingApp: .tinder,
            upvotes: 50,
            downvotes: 5 // Clear winner = not controversial
        )
        
        let controversialItem = ContentItem.review(controversialReview)
        let nonControversialItem = ContentItem.review(nonControversialReview)
        
        // Then
        XCTAssertGreaterThan(controversialItem.controversyScore, nonControversialItem.controversyScore)
    }
    
    // MARK: - Filter and Sort Tests
    
    func testContentFilters() {
        // Given
        let filters = ContentFilter.allCases
        
        // Then
        XCTAssertTrue(filters.contains(.all))
        XCTAssertTrue(filters.contains(.reviews))
        XCTAssertTrue(filters.contains(.posts))
        XCTAssertTrue(filters.contains(.positive))
        XCTAssertTrue(filters.contains(.negative))
        XCTAssertTrue(filters.contains(.recent))
        
        for filter in filters {
            XCTAssertFalse(filter.displayName.isEmpty)
        }
    }
    
    func testSortOptions() {
        // Given
        let sortOptions = SortOption.allCases
        
        // Then
        XCTAssertTrue(sortOptions.contains(.hot))
        XCTAssertTrue(sortOptions.contains(.new))
        XCTAssertTrue(sortOptions.contains(.top))
        XCTAssertTrue(sortOptions.contains(.controversial))
        
        for option in sortOptions {
            XCTAssertFalse(option.displayName.isEmpty)
            XCTAssertFalse(option.iconName.isEmpty)
        }
    }
    
    // MARK: - Report System Tests
    
    func testReportReasons() {
        // Given
        let reasons = DatingReviewReportReason.allCases
        
        // Then
        XCTAssertTrue(reasons.contains(.harassment))
        XCTAssertTrue(reasons.contains(.spam))
        XCTAssertTrue(reasons.contains(.personalInfo))
        XCTAssertTrue(reasons.contains(.inappropriate))
        
        for reason in reasons {
            XCTAssertFalse(reason.displayName.isEmpty)
            XCTAssertFalse(reason.description.isEmpty)
        }
    }
    
    func testReportCreation() {
        // Given
        let reporterId = UUID()
        let contentId = UUID()
        
        let report = Report(
            reporterId: reporterId,
            contentId: contentId,
            contentType: .review,
            reason: .harassment,
            additionalContext: "This content is harassing other users"
        )
        
        // Then
        XCTAssertEqual(report.reporterId, reporterId)
        XCTAssertEqual(report.contentId, contentId)
        XCTAssertEqual(report.contentType, .review)
        XCTAssertEqual(report.reason, .harassment)
        XCTAssertEqual(report.additionalContext, "This content is harassing other users")
        XCTAssertEqual(report.status, .pending)
    }
    
    // MARK: - Tag System Tests
    
    func testReviewTags() {
        // Given
        let positiveTags: [ReviewTag] = [.greenFlag, .authentic, .goodConversation]
        let negativeTags: [ReviewTag] = [.redFlag, .catfish, .poorConversation]
        
        // Then
        for tag in positiveTags {
            XCTAssertTrue(tag.isPositive)
            XCTAssertFalse(tag.displayName.isEmpty)
        }
        
        for tag in negativeTags {
            XCTAssertFalse(tag.isPositive)
            XCTAssertFalse(tag.displayName.isEmpty)
        }
    }
    
    func testPostTags() {
        // Given
        let tags = PostTag.allCases
        
        // Then
        for tag in tags {
            XCTAssertFalse(tag.displayName.isEmpty)
        }
        
        XCTAssertTrue(tags.contains(.dating101))
        XCTAssertTrue(tags.contains(.onlineDating))
        XCTAssertTrue(tags.contains(.redFlags))
        XCTAssertTrue(tags.contains(.success))
    }
    
    // MARK: - Performance Tests
    
    func testContentSortingPerformance() {
        // Given
        var reviews: [Review] = []
        var posts: [DatingReviewPost] = []
        
        // Create large dataset
        for i in 0..<1000 {
            reviews.append(Review(
                authorId: UUID(),
                profileScreenshots: [],
                ratings: ReviewRatings(photos: Int.random(in: 1...5), bio: Int.random(in: 1...5), conversation: Int.random(in: 1...5), overall: Int.random(in: 1...5)),
                content: "Review \(i)",
                tags: [],
                datingApp: .tinder,
                upvotes: Int.random(in: 0...100),
                downvotes: Int.random(in: 0...20)
            ))
            
            posts.append(DatingReviewPost(
                authorId: UUID(),
                title: "Post \(i)",
                content: "Content \(i)",
                category: .advice,
                upvotes: Int.random(in: 0...100),
                downvotes: Int.random(in: 0...20)
            ))
        }
        
        let reviewItems = reviews.map { ContentItem.review($0) }
        let postItems = posts.map { ContentItem.post($0) }
        let allItems = reviewItems + postItems
        
        // When & Then
        measure {
            let _ = allItems.sorted { $0.engagementScore > $1.engagementScore }
        }
    }
}

// MARK: - Mock Data Extensions

extension ContentDisplayComponentsTests {
    
    func createMockReview(
        upvotes: Int = 10,
        downvotes: Int = 2,
        commentCount: Int = 5,
        ratings: ReviewRatings = ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4)
    ) -> Review {
        return Review(
            authorId: UUID(),
            profileScreenshots: ["https://example.com/screenshot.jpg"],
            ratings: ratings,
            content: "Mock review content",
            tags: ["Green Flag"],
            datingApp: .tinder,
            upvotes: upvotes,
            downvotes: downvotes,
            commentCount: commentCount
        )
    }
    
    func createMockPost(
        upvotes: Int = 15,
        downvotes: Int = 3,
        commentCount: Int = 8,
        category: PostCategory = .advice
    ) -> DatingReviewPost {
        return DatingReviewPost(
            authorId: UUID(),
            title: "Mock Post Title",
            content: "Mock post content",
            category: category,
            tags: ["Dating 101"],
            upvotes: upvotes,
            downvotes: downvotes,
            commentCount: commentCount
        )
    }
    
    func createMockComment(
        parentId: UUID? = nil,
        upvotes: Int = 5,
        downvotes: Int = 1
    ) -> Comment {
        return Comment(
            authorId: UUID(),
            parentId: parentId,
            contentId: UUID(),
            contentType: .post,
            content: "Mock comment content",
            upvotes: upvotes,
            downvotes: downvotes
        )
    }
}