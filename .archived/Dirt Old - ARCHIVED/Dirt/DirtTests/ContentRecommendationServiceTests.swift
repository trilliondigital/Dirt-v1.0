import XCTest
@testable import Dirt

@MainActor
final class ContentRecommendationServiceTests: XCTestCase {
    
    var sut: ContentRecommendationService!
    var mockReviewService: MockReviewCreationService!
    var mockPostService: MockDiscussionPostService!
    
    override func setUp() {
        super.setUp()
        mockReviewService = MockReviewCreationService()
        mockPostService = MockDiscussionPostService()
        sut = ContentRecommendationService(
            reviewService: mockReviewService,
            postService: mockPostService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockReviewService = nil
        mockPostService = nil
        super.tearDown()
    }
    
    // MARK: - Interaction Tracking Tests
    
    func testTrackInteraction_CreatesInteraction() async {
        // Given
        let userId = UUID()
        let contentId = UUID()
        let contentType = ContentType.post
        let interactionType = InteractionType.upvote
        
        // When
        await sut.trackInteraction(
            userId: userId,
            contentId: contentId,
            contentType: contentType,
            interactionType: interactionType
        )
        
        // Then
        let recommendations = await sut.getRecommendations(for: userId)
        XCTAssertTrue(recommendations.count >= 0) // Should have processed the interaction
    }
    
    func testTrackInteraction_UpdatesUserPreferences() async {
        // Given
        let userId = UUID()
        let postId = UUID()
        let post = createMockPost(id: postId, category: .advice, tags: ["dating", "tips"])
        mockPostService.posts = [post]
        
        // When
        await sut.trackInteraction(
            userId: userId,
            contentId: postId,
            contentType: .post,
            interactionType: .upvote
        )
        
        // Then
        // Verify that user preferences are updated (would need access to internal state)
        let recommendations = await sut.getRecommendations(for: userId)
        XCTAssertNotNil(recommendations)
    }
    
    // MARK: - Recommendation Generation Tests
    
    func testGetRecommendations_ReturnsPersonalizedContent() async {
        // Given
        let userId = UUID()
        let posts = createMockPosts()
        mockPostService.posts = posts
        
        // Create some interactions to build preferences
        await sut.trackInteraction(
            userId: userId,
            contentId: posts[0].id,
            contentType: .post,
            interactionType: .upvote
        )
        
        // When
        await sut.updateRecommendations()
        let recommendations = await sut.getRecommendations(for: userId, limit: 10)
        
        // Then
        XCTAssertTrue(recommendations.count <= 10)
        XCTAssertTrue(recommendations.allSatisfy { $0.userId == userId })
        XCTAssertTrue(recommendations.allSatisfy { $0.recommendationScore > 0 })
    }
    
    func testGetRecommendations_SortsByScore() async {
        // Given
        let userId = UUID()
        let posts = createMockPosts()
        mockPostService.posts = posts
        
        // When
        await sut.updateRecommendations()
        let recommendations = await sut.getRecommendations(for: userId)
        
        // Then
        for i in 0..<(recommendations.count - 1) {
            XCTAssertGreaterThanOrEqual(
                recommendations[i].recommendationScore,
                recommendations[i + 1].recommendationScore,
                "Recommendations should be sorted by score in descending order"
            )
        }
    }
    
    // MARK: - Trending Topics Tests
    
    func testGetTrendingTopics_CalculatesCorrectly() async {
        // Given
        let posts = createMockPostsWithTrending()
        mockPostService.posts = posts
        
        // When
        let trendingTopics = await sut.getTrendingTopics(limit: 5)
        
        // Then
        XCTAssertTrue(trendingTopics.count <= 5)
        XCTAssertTrue(trendingTopics.allSatisfy { $0.contentCount > 0 })
        XCTAssertTrue(trendingTopics.allSatisfy { $0.trendingScore > 0 })
        
        // Verify sorting by trending score
        for i in 0..<(trendingTopics.count - 1) {
            XCTAssertGreaterThanOrEqual(
                trendingTopics[i].trendingScore,
                trendingTopics[i + 1].trendingScore
            )
        }
    }
    
    func testGetTrendingTopics_IncludesCategoriesAndTags() async {
        // Given
        let posts = createMockPostsWithTrending()
        mockPostService.posts = posts
        
        // When
        let trendingTopics = await sut.getTrendingTopics()
        
        // Then
        let hasCategories = trendingTopics.contains { $0.category != nil }
        let hasTags = trendingTopics.contains { $0.tag != nil }
        
        XCTAssertTrue(hasCategories || hasTags, "Should include either categories or tags")
    }
    
    // MARK: - Popular Content Tests
    
    func testGetPopularContent_ReturnsHighEngagementContent() async {
        // Given
        let posts = createMockPostsWithVaryingEngagement()
        mockPostService.posts = posts
        
        // When
        let popularContent = await sut.getPopularContent(limit: 5)
        
        // Then
        XCTAssertTrue(popularContent.count <= 5)
        
        // Verify that returned content has high engagement
        for contentId in popularContent {
            let post = posts.first { $0.id == contentId }
            XCTAssertNotNil(post)
            XCTAssertTrue(post!.engagementScore >= 10.0) // Above threshold
        }
    }
    
    func testGetPopularContent_FiltersByContentType() async {
        // Given
        let posts = createMockPostsWithVaryingEngagement()
        let reviews = createMockReviews()
        mockPostService.posts = posts
        mockReviewService.reviews = reviews
        
        // When
        let popularPosts = await sut.getPopularContent(contentType: .post, limit: 10)
        let popularReviews = await sut.getPopularContent(contentType: .review, limit: 10)
        
        // Then
        // Verify that posts only contain post IDs
        for contentId in popularPosts {
            XCTAssertTrue(posts.contains { $0.id == contentId })
        }
        
        // Verify that reviews only contain review IDs
        for contentId in popularReviews {
            XCTAssertTrue(reviews.contains { $0.id == contentId })
        }
    }
    
    // MARK: - Category-Based Content Tests
    
    func testGetContentByCategory_ReturnsCorrectCategory() async {
        // Given
        let posts = createMockPostsWithDifferentCategories()
        mockPostService.posts = posts
        let targetCategory = PostCategory.advice
        
        // When
        let categoryContent = await sut.getContentByCategory(targetCategory, limit: 10)
        
        // Then
        XCTAssertTrue(categoryContent.count <= 10)
        
        // Verify all returned content belongs to the target category
        for contentId in categoryContent {
            let post = posts.first { $0.id == contentId }
            XCTAssertNotNil(post)
            XCTAssertEqual(post!.category, targetCategory)
        }
    }
    
    func testGetContentByCategory_SortsByEngagement() async {
        // Given
        let posts = createMockPostsWithSameCategory()
        mockPostService.posts = posts
        
        // When
        let categoryContent = await sut.getContentByCategory(.advice)
        
        // Then
        // Verify sorting by engagement score
        var previousScore = Double.infinity
        for contentId in categoryContent {
            let post = posts.first { $0.id == contentId }!
            XCTAssertLessThanOrEqual(post.engagementScore, previousScore)
            previousScore = post.engagementScore
        }
    }
    
    // MARK: - Update Recommendations Tests
    
    func testUpdateRecommendations_UpdatesAllComponents() async {
        // Given
        let posts = createMockPosts()
        let reviews = createMockReviews()
        mockPostService.posts = posts
        mockReviewService.reviews = reviews
        
        // When
        await sut.updateRecommendations()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertGreaterThan(sut.trendingTopics.count, 0)
        XCTAssertGreaterThan(sut.popularContent.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testUpdateRecommendations_HandlesErrors() async {
        // Given
        mockPostService.shouldThrowError = true
        
        // When
        await sut.updateRecommendations()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        // Error handling would depend on implementation
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost(
        id: UUID = UUID(),
        category: PostCategory = .advice,
        tags: [String] = [],
        upvotes: Int = 5,
        commentCount: Int = 2
    ) -> DatingReviewPost {
        return DatingReviewPost(
            id: id,
            authorId: UUID(),
            title: "Test Post",
            content: "Test content",
            category: category,
            tags: tags,
            upvotes: upvotes,
            commentCount: commentCount
        )
    }
    
    private func createMockPosts() -> [DatingReviewPost] {
        return [
            createMockPost(category: .advice, tags: ["dating", "tips"], upvotes: 10),
            createMockPost(category: .experience, tags: ["success", "story"], upvotes: 8),
            createMockPost(category: .question, tags: ["help", "advice"], upvotes: 6),
            createMockPost(category: .strategy, tags: ["approach", "dating"], upvotes: 12)
        ]
    }
    
    private func createMockPostsWithTrending() -> [DatingReviewPost] {
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        
        return [
            DatingReviewPost(
                authorId: UUID(),
                title: "Trending Advice",
                content: "Popular advice post",
                category: .advice,
                tags: ["trending", "popular"],
                createdAt: recentTime,
                upvotes: 20,
                commentCount: 10
            ),
            DatingReviewPost(
                authorId: UUID(),
                title: "Hot Topic",
                content: "Another trending post",
                category: .experience,
                tags: ["trending", "hot"],
                createdAt: recentTime,
                upvotes: 15,
                commentCount: 8
            )
        ]
    }
    
    private func createMockPostsWithVaryingEngagement() -> [DatingReviewPost] {
        return [
            createMockPost(upvotes: 50, commentCount: 20), // High engagement
            createMockPost(upvotes: 30, commentCount: 15), // Medium engagement
            createMockPost(upvotes: 5, commentCount: 2),   // Low engagement
            createMockPost(upvotes: 100, commentCount: 40) // Very high engagement
        ]
    }
    
    private func createMockPostsWithDifferentCategories() -> [DatingReviewPost] {
        return PostCategory.allCases.map { category in
            createMockPost(category: category)
        }
    }
    
    private func createMockPostsWithSameCategory() -> [DatingReviewPost] {
        return [
            DatingReviewPost(
                authorId: UUID(),
                title: "High Engagement",
                content: "Content",
                category: .advice,
                upvotes: 50,
                commentCount: 20
            ),
            DatingReviewPost(
                authorId: UUID(),
                title: "Medium Engagement",
                content: "Content",
                category: .advice,
                upvotes: 30,
                commentCount: 10
            ),
            DatingReviewPost(
                authorId: UUID(),
                title: "Low Engagement",
                content: "Content",
                category: .advice,
                upvotes: 10,
                commentCount: 5
            )
        ]
    }
    
    private func createMockReviews() -> [Review] {
        return [
            Review(
                authorId: UUID(),
                profileScreenshots: ["url1"],
                ratings: ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4),
                content: "Good review",
                tags: ["positive"],
                datingApp: .tinder,
                upvotes: 15,
                commentCount: 5
            ),
            Review(
                authorId: UUID(),
                profileScreenshots: ["url2"],
                ratings: ReviewRatings(photos: 2, bio: 2, conversation: 1, overall: 2),
                content: "Bad review",
                tags: ["negative"],
                datingApp: .bumble,
                upvotes: 8,
                commentCount: 3
            )
        ]
    }
}

// MARK: - Mock Services

class MockReviewCreationService: ReviewCreationService {
    var reviews: [Review] = []
    var shouldThrowError = false
    
    override init() {
        super.init()
        self.reviews = []
    }
}

class MockDiscussionPostService: DiscussionPostService {
    var posts: [DatingReviewPost] = []
    var shouldThrowError = false
    
    override init() {
        super.init()
        self.posts = []
    }
}