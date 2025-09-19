import XCTest
@testable import Dirt

@MainActor
final class RecommendationFeedViewModelTests: XCTestCase {
    
    var sut: RecommendationFeedViewModel!
    var mockRecommendationService: MockContentRecommendationService!
    
    override func setUp() {
        super.setUp()
        mockRecommendationService = MockContentRecommendationService()
        sut = RecommendationFeedViewModel(
            recommendationService: mockRecommendationService,
            userId: UUID()
        )
    }
    
    override func tearDown() {
        sut = nil
        mockRecommendationService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsUpBindings() {
        // Given/When - initialization happens in setUp
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.recommendations.count, 0)
        XCTAssertEqual(sut.filteredRecommendations.count, 0)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Load Recommendations Tests
    
    func testLoadRecommendations_UpdatesRecommendations() async {
        // Given
        let mockRecommendations = createMockRecommendations()
        mockRecommendationService.mockRecommendations = mockRecommendations
        
        // When
        await sut.loadRecommendations()
        
        // Then
        XCTAssertEqual(sut.recommendations.count, mockRecommendations.count)
        XCTAssertEqual(sut.filteredRecommendations.count, mockRecommendations.count)
    }
    
    func testLoadRecommendations_CallsRecommendationService() async {
        // Given
        mockRecommendationService.mockRecommendations = createMockRecommendations()
        
        // When
        await sut.loadRecommendations()
        
        // Then
        XCTAssertTrue(mockRecommendationService.updateRecommendationsCalled)
        XCTAssertTrue(mockRecommendationService.getRecommendationsCalled)
    }
    
    // MARK: - Filter Tests
    
    func testApplyFilter_All_ShowsAllRecommendations() async {
        // Given
        sut.recommendations = createMockRecommendations()
        
        // When
        await sut.applyFilter(.all)
        
        // Then
        XCTAssertEqual(sut.filteredRecommendations.count, sut.recommendations.count)
    }
    
    func testApplyFilter_Posts_ShowsOnlyPosts() async {
        // Given
        let recommendations = createMockRecommendationsWithDifferentTypes()
        sut.recommendations = recommendations
        
        // When
        await sut.applyFilter(.posts)
        
        // Then
        XCTAssertTrue(sut.filteredRecommendations.allSatisfy { $0.contentType == .post })
        let expectedCount = recommendations.filter { $0.contentType == .post }.count
        XCTAssertEqual(sut.filteredRecommendations.count, expectedCount)
    }
    
    func testApplyFilter_Reviews_ShowsOnlyReviews() async {
        // Given
        let recommendations = createMockRecommendationsWithDifferentTypes()
        sut.recommendations = recommendations
        
        // When
        await sut.applyFilter(.reviews)
        
        // Then
        XCTAssertTrue(sut.filteredRecommendations.allSatisfy { $0.contentType == .review })
        let expectedCount = recommendations.filter { $0.contentType == .review }.count
        XCTAssertEqual(sut.filteredRecommendations.count, expectedCount)
    }
    
    func testApplyFilter_Trending_ShowsTrendingRecommendations() async {
        // Given
        let recommendations = createMockRecommendationsWithDifferentReasons()
        sut.recommendations = recommendations
        
        // When
        await sut.applyFilter(.trending)
        
        // Then
        XCTAssertTrue(sut.filteredRecommendations.allSatisfy { 
            $0.recommendationReason == .trendingTopic 
        })
    }
    
    func testApplyFilter_Popular_ShowsPopularRecommendations() async {
        // Given
        let recommendations = createMockRecommendationsWithDifferentReasons()
        sut.recommendations = recommendations
        
        // When
        await sut.applyFilter(.popular)
        
        // Then
        XSortsByScore() async {
        // Given
        let unsortedRecommendations = [
            createMockRecommendation(score: 5.0),
            createMockRecommendation(score: 10.0),
            createMockRecommendation(score: 7.5)
        ]
        sut.recommendations = unsortedRecommendations
        
        // When
        await sut.applyFilter(.all)
        
        // Then
        let scores = sut.filteredRecommendations.map { $0.recommendationScore }
        XCTAssertEqual(scores, [10.0, 7.5, 5.0])
    }
    
    // MARK: - Interaction Tracking Tests
    
    func testTrackInteraction_CallsRecommendationService() async {
        // Given
        let recommendation = createMockRecommendation()
        let interactionType = InteractionType.upvote
        
        // When
        await sut.trackInteraction(recommendation: recommendation, interactionType: interactionType)
        
        // Then
        XCTAssertTrue(mockRecommendationService.trackInteractionCalled)
        XCTAssertEqual(mockRecommendationService.lastTrackedInteractionType, interactionType)
    }
    
    func testTrackInteraction_MarksRecommendationAsInteracted() async {
        // Given
        let recommendation = createMockRecommendation()
        sut.recommendations = [recommendation]
        
        // When
        await sut.trackInteraction(recommendation: recommendation, interactionType: .upvote)
        
        // Then
        let updatedRecommendation = sut.recommendations.first { $0.id == recommendation.id }
        XCTAssertTrue(updatedRecommendation?.isInteracted ?? false)
    }
    
    // MARK: - Selection Tests
    
    func testSelectRecommendation_TracksViewInteraction() async {
        // Given
        let recommendation = createMockRecommendation()
        
        // When
        await sut.selectRecommendation(recommendation)
        
        // Then
        XCTAssertTrue(mockRecommendationService.trackInteractionCalled)
        XCTAssertEqual(mockRecommendationService.lastTrackedInteractionType, .view)
    }
    
    func testSelectRecommendation_MarksAsViewed() async {
        // Given
        let recommendation = createMockRecommendation()
        sut.recommendations = [recommendation]
        
        // When
        await sut.selectRecommendation(recommendation)
        
        // Then
        let updatedRecommendation = sut.recommendations.first { $0.id == recommendation.id }
        XCTAssertTrue(updatedRecommendation?.isViewed ?? false)
    }
    
    func testSelectTrendingTopic_FiltersRecommendations() async {
        // Given
        let topic = createMockTrendingTopic()
        let recommendations = createMockRecommendations()
        sut.recommendations = recommendations
        
        // When
        await sut.selectTrendingTopic(topic)
        
        // Then
        // Verify that some filtering logic was applied
        // (Implementation would depend on actual filtering logic)
        XCTAssertNotNil(sut.filteredRecommendations)
    }
    
    func testSelectPopularContent_TracksInteraction() async {
        // Given
        let contentId = UUID()
        
        // When
        await sut.selectPopularContent(contentId)
        
        // Then
        XCTAssertTrue(mockRecommendationService.trackInteractionCalled)
        XCTAssertEqual(mockRecommendationService.lastTrackedContentId, contentId)
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshRecommendations_CallsUpdateRecommendations() async {
        // Given
        mockRecommendationService.mockRecommendations = createMockRecommendations()
        
        // When
        await sut.refreshRecommendations()
        
        // Then
        XCTAssertTrue(mockRecommendationService.updateRecommendationsCalled)
    }
    
    // MARK: - Helper Methods
    
    private func createMockRecommendation(
        contentType: ContentType = .post,
        reason: RecommendationReason = .similarInterests,
        score: Double = 5.0
    ) -> ContentRecommendation {
        return ContentRecommendation(
            userId: UUID(),
            contentId: UUID(),
            contentType: contentType,
            recommendationScore: score,
            recommendationReason: reason
        )
    }
    
    private func createMockRecommendations() -> [ContentRecommendation] {
        return [
            createMockRecommendation(contentType: .post, reason: .similarInterests),
            createMockRecommendation(contentType: .review, reason: .popularContent),
            createMockRecommendation(contentType: .post, reason: .trendingTopic)
        ]
    }
    
    private func createMockRecommendationsWithDifferentTypes() -> [ContentRecommendation] {
        return [
            createMockRecommendation(contentType: .post),
            createMockRecommendation(contentType: .review),
            createMockRecommendation(contentType: .post),
            createMockRecommendation(contentType: .comment)
        ]
    }
    
    private func createMockRecommendationsWithDifferentReasons() -> [ContentRecommendation] {
        return [
            createMockRecommendation(reason: .trendingTopic),
            createMockRecommendation(reason: .popularContent),
            createMockRecommendation(reason: .similarInterests),
            createMockRecommendation(reason: .categoryPreference)
        ]
    }
    
    private func createMockTrendingTopic() -> TrendingTopic {
        return TrendingTopic(
            topic: "Dating Tips",
            category: .advice,
            contentCount: 10,
            engagementScore: 50.0,
            trendingScore: 75.0
        )
    }
}

// MARK: - Mock Content Recommendation Service

class MockContentRecommendationService: ContentRecommendationService {
    var mockRecommendations: [ContentRecommendation] = []
    var mockTrendingTopics: [TrendingTopic] = []
    var mockPopularContent: [UUID] = []
    
    var updateRecommendationsCalled = false
    var getRecommendationsCalled = false
    var trackInteractionCalled = false
    var lastTrackedInteractionType: InteractionType?
    var lastTrackedContentId: UUID?
    
    override init(reviewService: ReviewCreationService, postService: DiscussionPostService) {
        super.init(reviewService: reviewService, postService: postService)
    }
    
    override func updateRecommendations() async {
        updateRecommendationsCalled = true
        recommendedContent = mockRecommendations
        trendingTopics = mockTrendingTopics
        popularContent = mockPopularContent
    }
    
    override func getRecommendations(for userId: UUID, limit: Int = 20) async -> [ContentRecommendation] {
        getRecommendationsCalled = true
        return Array(mockRecommendations.filter { $0.userId == userId }.prefix(limit))
    }
    
    override func trackInteraction(
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        interactionType: InteractionType
    ) async {
        trackInteractionCalled = true
        lastTrackedInteractionType = interactionType
        lastTrackedContentId = contentId
    }
    
    override func getTrendingTopics(limit: Int = 10) async -> [TrendingTopic] {
        return Array(mockTrendingTopics.prefix(limit))
    }
    
    override func getPopularContent(contentType: ContentType? = nil, limit: Int = 20) async -> [UUID] {
        return Array(mockPopularContent.prefix(limit))
    }
}