import XCTest
@testable import Dirt

@MainActor
final class CategoryBrowsingViewModelTests: XCTestCase {
    
    var sut: CategoryBrowsingViewModel!
    var mockRecommendationService: MockContentRecommendationService!
    var mockPostService: MockDiscussionPostService!
    var mockReviewService: MockReviewCreationService!
    
    override func setUp() {
        super.setUp()
        mockRecommendationService = MockContentRecommendationService()
        mockPostService = MockDiscussionPostService()
        mockReviewService = MockReviewCreationService()
        
        sut = CategoryBrowsingViewModel(
            recommendationService: mockRecommendationService,
            postService: mockPostService,
            reviewService: mockReviewService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockRecommendationService = nil
        mockPostService = nil
        mockReviewService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsUpCorrectly() {
        // Given/When - initialization happens in setUp
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.categoryStats.count, 0)
        XCTAssertEqual(sut.popularCategories.count, 0)
        XCTAssertEqual(sut.categoryActivity.count, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Load Data Tests
    
    func testLoadData_CalculatesCategoryStats() async {
        // Given
        let posts = createMockPostsForCategories()
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertGreaterThan(sut.categoryStats.count, 0)
        
        // Verify stats for advice category
        let adviceStats = sut.categoryStats[.advice]
        XCTAssertNotNil(adviceStats)
        XCTAssertEqual(adviceStats?.category, .advice)
        XCTAssertGreaterThan(adviceStats?.postCount ?? 0, 0)
    }
    
    func testLoadData_CalculatesPopularCategories() async {
        // Given
        let posts = createMockPostsWithRecentActivity()
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertGreaterThanOrEqual(sut.popularCategories.count, 0)
        
        // Verify popular categories are sorted by trending score
        for i in 0..<(sut.popularCategories.count - 1) {
            XCTAssertGreaterThanOrEqual(
                sut.popularCategories[i].trendingScore,
                sut.popularCategories[i + 1].trendingScore
            )
        }
    }
    
    func testLoadData_CalculatesCategoryActivity() async {
        // Given
        let posts = createMockPostsWithRecentActivity()
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertGreaterThanOrEqual(sut.categoryActivity.count, 0)
        
        // Verify activity is sorted by engagement
        for i in 0..<(sut.categoryActivity.count - 1) {
            XCTAssertGreaterThanOrEqual(
                sut.categoryActivity[i].totalEngagement,
                sut.categoryActivity[i + 1].totalEngagement
            )
        }
    }
    
    func testLoadData_SetsLoadingState() async {
        // Given
        let posts = createMockPostsForCategories()
        mockPostService.posts = posts
        
        // When
        let loadingTask = Task {
            await sut.loadData()
        }
        
        // Then - Check loading state during execution
        // Note: This is a simplified test - in practice, you might need more sophisticated timing
        await loadingTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Refresh Data Tests
    
    func testRefreshData_CallsLoadData() async {
        // Given
        let posts = createMockPostsForCategories()
        mockPostService.posts = posts
        
        // When
        await sut.refreshData()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertGreaterThan(sut.categoryStats.count, 0)
    }
    
    // MARK: - Get Content for Category Tests
    
    func testGetContentForCategory_CallsRecommendationService() async {
        // Given
        let category = PostCategory.advice
        let expectedContent = [UUID(), UUID(), UUID()]
        mockRecommendationService.mockCategoryContent = expectedContent
        
        // When
        let result = await sut.getContentForCategory(category)
        
        // Then
        XCTAssertEqual(result, expectedContent)
    }
    
    // MARK: - Category Stats Calculation Tests
    
    func testCategoryStats_CalculatesCorrectPostCount() async {
        // Given
        let advicePosts = [
            createMockPost(category: .advice),
            createMockPost(category: .advice),
            createMockPost(category: .advice)
        ]
        let experiencePosts = [
            createMockPost(category: .experience),
            createMockPost(category: .experience)
        ]
        mockPostService.posts = advicePosts + experiencePosts
        
        // When
        await sut.loadData()
        
        // Then
        let adviceStats = sut.categoryStats[.advice]
        let experienceStats = sut.categoryStats[.experience]
        
        XCTAssertEqual(adviceStats?.postCount, 3)
        XCTAssertEqual(experienceStats?.postCount, 2)
    }
    
    func testCategoryStats_CalculatesRecentPosts() async {
        // Given
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        let oldTime = now.addingTimeInterval(-48 * 3600) // 2 days ago
        
        let recentPosts = [
            createMockPost(category: .advice, createdAt: recentTime),
            createMockPost(category: .advice, createdAt: recentTime)
        ]
        let oldPosts = [
            createMockPost(category: .advice, createdAt: oldTime)
        ]
        mockPostService.posts = recentPosts + oldPosts
        
        // When
        await sut.loadData()
        
        // Then
        let adviceStats = sut.categoryStats[.advice]
        XCTAssertEqual(adviceStats?.recentPosts, 2)
        XCTAssertEqual(adviceStats?.postCount, 3)
    }
    
    func testCategoryStats_CalculatesTotalEngagement() async {
        // Given
        let posts = [
            createMockPost(category: .advice, upvotes: 10, commentCount: 5),
            createMockPost(category: .advice, upvotes: 8, commentCount: 3),
            createMockPost(category: .experience, upvotes: 15, commentCount: 7)
        ]
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        let adviceStats = sut.categoryStats[.advice]
        let experienceStats = sut.categoryStats[.experience]
        
        XCTAssertEqual(adviceStats?.totalEngagement, 26) // (10+5) + (8+3)
        XCTAssertEqual(experienceStats?.totalEngagement, 22) // (15+7)
    }
    
    func testCategoryStats_DeterminesActiveStatus() async {
        // Given
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        let oldTime = now.addingTimeInterval(-48 * 3600) // 2 days ago
        
        let posts = [
            createMockPost(category: .advice, createdAt: recentTime), // Recent - should be active
            createMockPost(category: .experience, createdAt: oldTime) // Old - should not be active
        ]
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        let adviceStats = sut.categoryStats[.advice]
        let experienceStats = sut.categoryStats[.experience]
        
        XCTAssertTrue(adviceStats?.isActive ?? false)
        XCTAssertFalse(experienceStats?.isActive ?? true)
    }
    
    // MARK: - Popular Categories Tests
    
    func testPopularCategories_CalculatesGrowthPercentage() async {
        // Given
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 3600)
        let twoDaysAgo = now.addingTimeInterval(-48 * 3600)
        
        // Category with growth: 2 posts today, 1 yesterday = 100% growth
        let growingCategoryPosts = [
            createMockPost(category: .advice, createdAt: now.addingTimeInterval(-3600)), // Today
            createMockPost(category: .advice, createdAt: now.addingTimeInterval(-7200)), // Today
            createMockPost(category: .advice, createdAt: oneDayAgo.addingTimeInterval(-3600)) // Yesterday
        ]
        
        mockPostService.posts = growingCategoryPosts
        
        // When
        await sut.loadData()
        
        // Then
        let popularCategory = sut.popularCategories.first { $0.category == .advice }
        XCTAssertNotNil(popularCategory)
        XCTAssertEqual(popularCategory?.growthPercentage, 100)
    }
    
    func testPopularCategories_LimitsToTopFive() async {
        // Given
        let posts = PostCategory.allCases.flatMap { category in
            [
                createMockPost(category: category, createdAt: Date().addingTimeInterval(-3600)),
                createMockPost(category: category, createdAt: Date().addingTimeInterval(-7200))
            ]
        }
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        XCTAssertLessThanOrEqual(sut.popularCategories.count, 5)
    }
    
    // MARK: - Category Activity Tests
    
    func testCategoryActivity_OnlyIncludesActiveCategories() async {
        // Given
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        let oldTime = now.addingTimeInterval(-48 * 3600) // 2 days ago
        
        let posts = [
            createMockPost(category: .advice, createdAt: recentTime), // Should be included
            createMockPost(category: .experience, createdAt: oldTime) // Should not be included
        ]
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        let activityCategories = sut.categoryActivity.map { $0.category }
        XCTAssertTrue(activityCategories.contains(.advice))
        XCTAssertFalse(activityCategories.contains(.experience))
    }
    
    func testCategoryActivity_CalculatesCorrectEngagement() async {
        // Given
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        
        let posts = [
            createMockPost(category: .advice, createdAt: recentTime, upvotes: 10, downvotes: 2, commentCount: 5),
            createMockPost(category: .advice, createdAt: recentTime, upvotes: 8, downvotes: 1, commentCount: 3)
        ]
        mockPostService.posts = posts
        
        // When
        await sut.loadData()
        
        // Then
        let adviceActivity = sut.categoryActivity.first { $0.category == .advice }
        XCTAssertNotNil(adviceActivity)
        XCTAssertEqual(adviceActivity?.totalEngagement, 29) // (10+2+5) + (8+1+3)
        XCTAssertEqual(adviceActivity?.newPosts, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost(
        category: PostCategory,
        createdAt: Date = Date(),
        upvotes: Int = 5,
        downvotes: Int = 1,
        commentCount: Int = 2
    ) -> DatingReviewPost {
        return DatingReviewPost(
            authorId: UUID(),
            title: "Test Post",
            content: "Test content",
            category: category,
            createdAt: createdAt,
            upvotes: upvotes,
            downvotes: downvotes,
            commentCount: commentCount
        )
    }
    
    private func createMockPostsForCategories() -> [DatingReviewPost] {
        return [
            createMockPost(category: .advice),
            createMockPost(category: .advice),
            createMockPost(category: .experience),
            createMockPost(category: .question),
            createMockPost(category: .strategy)
        ]
    }
    
    private func createMockPostsWithRecentActivity() -> [DatingReviewPost] {
        let now = Date()
        let recentTime = now.addingTimeInterval(-3600) // 1 hour ago
        
        return [
            createMockPost(category: .advice, createdAt: recentTime, upvotes: 15, commentCount: 8),
            createMockPost(category: .advice, createdAt: recentTime, upvotes: 12, commentCount: 6),
            createMockPost(category: .experience, createdAt: recentTime, upvotes: 10, commentCount: 4),
            createMockPost(category: .question, createdAt: recentTime, upvotes: 8, commentCount: 3)
        ]
    }
}

// MARK: - Mock Extensions

extension MockContentRecommendationService {
    var mockCategoryContent: [UUID] = []
    
    override func getContentByCategory(_ category: PostCategory, limit: Int = 20) async -> [UUID] {
        return Array(mockCategoryContent.prefix(limit))
    }
}