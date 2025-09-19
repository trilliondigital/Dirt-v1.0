import Foundation
import Combine

// MARK: - Content Recommendation Service
@MainActor
class ContentRecommendationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recommendedContent: [ContentRecommendation] = []
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var popularContent: [UUID] = []
    @Published var isLoading = false
    @Published var error: ContentRecommendationError?
    
    // MARK: - Private Properties
    private var userInteractions: [UserInteraction] = []
    private var userPreferences: [UUID: UserPreferences] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Dependencies
    private let reviewService: ReviewCreationService
    private let postService: DiscussionPostService
    
    // MARK: - Configuration
    private let maxRecommendations = 50
    private let trendingTimeWindow: TimeInterval = 24 * 60 * 60 // 24 hours
    private let popularContentThreshold = 10 // Minimum interactions for popular content
    
    init(reviewService: ReviewCreationService, postService: DiscussionPostService) {
        self.reviewService = reviewService
        self.postService = postService
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update recommendations when content changes
        Publishers.CombineLatest(
            reviewService.$reviews,
            postService.$posts
        )
        .debounce(for: .seconds(1), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            Task {
                await self?.updateRecommendations()
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Track user interaction with content
    func trackInteraction(
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        interactionType: InteractionType
    ) async {
        let interaction = UserInteraction(
            userId: userId,
            contentId: contentId,
            contentType: contentType,
            interactionType: interactionType,
            weight: interactionType.weight
        )
        
        userInteractions.append(interaction)
        
        // Update user preferences based on interaction
        await updateUserPreferences(for: userId, interaction: interaction)
        
        // Refresh recommendations for this user
        await generateRecommendations(for: userId)
    }
    
    /// Get personalized recommendations for a user
    func getRecommendations(for userId: UUID, limit: Int = 20) async -> [ContentRecommendation] {
        let userRecommendations = recommendedContent
            .filter { $0.userId == userId }
            .sorted { $0.recommendationScore > $1.recommendationScore }
            .prefix(limit)
        
        return Array(userRecommendations)
    }
    
    /// Get trending topics
    func getTrendingTopics(limit: Int = 10) async -> [TrendingTopic] {
        await calculateTrendingTopics()
        return Array(trendingTopics.prefix(limit))
    }
    
    /// Get popular content
    func getPopularContent(contentType: ContentType? = nil, limit: Int = 20) async -> [UUID] {
        await calculatePopularContent()
        
        var filtered = popularContent
        
        if let contentType = contentType {
            // Filter by content type if specified
            filtered = popularContent.filter { contentId in
                // Check if content matches the specified type
                return getContentType(for: contentId) == contentType
            }
        }
        
        return Array(filtered.prefix(limit))
    }
    
    /// Get content recommendations by category
    func getContentByCategory(_ category: PostCategory, limit: Int = 20) async -> [UUID] {
        let categoryPosts = postService.posts
            .filter { $0.category == category && $0.isVisible }
            .sorted { $0.engagementScore > $1.engagementScore }
            .prefix(limit)
            .map { $0.id }
        
        return Array(categoryPosts)
    }
    
    /// Generate recommendations for all users
    func updateRecommendations() async {
        isLoading = true
        error = nil
        
        do {
            // Calculate trending topics
            await calculateTrendingTopics()
            
            // Calculate popular content
            await calculatePopularContent()
            
            // Generate recommendations for all users
            let allUserIds = Set(userInteractions.map { $0.userId })
            
            for userId in allUserIds {
                await generateRecommendations(for: userId)
            }
            
        } catch {
            self.error = error as? ContentRecommendationError ?? .unknown
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func generateRecommendations(for userId: UUID) async {
        let userPrefs = userPreferences[userId] ?? UserPreferences(userId: userId)
        let userInteractionHistory = userInteractions.filter { $0.userId == userId }
        
        var recommendations: [ContentRecommendation] = []
        
        // 1. Category-based recommendations
        recommendations += await generateCategoryRecommendations(for: userId, preferences: userPrefs)
        
        // 2. Tag-based recommendations
        recommendations += await generateTagRecommendations(for: userId, preferences: userPrefs)
        
        // 3. Popular content recommendations
        recommendations += await generatePopularContentRecommendations(for: userId)
        
        // 4. Trending topic recommendations
        recommendations += await generateTrendingRecommendations(for: userId)
        
        // 5. Similar user recommendations
        recommendations += await generateSimilarUserRecommendations(for: userId, interactions: userInteractionHistory)
        
        // Remove duplicates and sort by score
        let uniqueRecommendations = Dictionary(grouping: recommendations) { $0.contentId }
            .compactMapValues { $0.max { $0.recommendationScore < $1.recommendationScore } }
            .values
            .sorted { $0.recommendationScore > $1.recommendationScore }
            .prefix(maxRecommendations)
        
        // Remove existing recommendations for this user and add new ones
        recommendedContent.removeAll { $0.userId == userId }
        recommendedContent.append(contentsOf: uniqueRecommendations)
    }
    
    private func generateCategoryRecommendations(for userId: UUID, preferences: UserPreferences) async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        for category in preferences.preferredCategories {
            let categoryContent = postService.posts
                .filter { $0.category == category && $0.isVisible }
                .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                .sorted { $0.engagementScore > $1.engagementScore }
                .prefix(5)
            
            for post in categoryContent {
                let score = calculateCategoryScore(post: post, preferences: preferences)
                let recommendation = ContentRecommendation(
                    userId: userId,
                    contentId: post.id,
                    contentType: .post,
                    recommendationScore: score,
                    recommendationReason: .categoryPreference
                )
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    private func generateTagRecommendations(for userId: UUID, preferences: UserPreferences) async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        for tag in preferences.preferredTags {
            // Find posts with matching tags
            let taggedPosts = postService.posts
                .filter { $0.tags.contains(tag) && $0.isVisible }
                .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                .sorted { $0.engagementScore > $1.engagementScore }
                .prefix(3)
            
            for post in taggedPosts {
                let score = calculateTagScore(post: post, preferences: preferences)
                let recommendation = ContentRecommendation(
                    userId: userId,
                    contentId: post.id,
                    contentType: .post,
                    recommendationScore: score,
                    recommendationReason: .tagPreference
                )
                recommendations.append(recommendation)
            }
            
            // Find reviews with matching tags
            let taggedReviews = reviewService.reviews
                .filter { $0.tags.contains(tag) && $0.isVisible }
                .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                .sorted { $0.netScore > $1.netScore }
                .prefix(3)
            
            for review in taggedReviews {
                let score = calculateReviewTagScore(review: review, preferences: preferences)
                let recommendation = ContentRecommendation(
                    userId: userId,
                    contentId: review.id,
                    contentType: .review,
                    recommendationScore: score,
                    recommendationReason: .tagPreference
                )
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    private func generatePopularContentRecommendations(for userId: UUID) async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        for contentId in popularContent.prefix(10) {
            if !hasUserInteracted(userId: userId, contentId: contentId) {
                let contentType = getContentType(for: contentId)
                let score = calculatePopularityScore(for: contentId)
                
                let recommendation = ContentRecommendation(
                    userId: userId,
                    contentId: contentId,
                    contentType: contentType,
                    recommendationScore: score,
                    recommendationReason: .popularContent
                )
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    private func generateTrendingRecommendations(for userId: UUID) async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        for topic in trendingTopics.prefix(5) {
            // Find content related to trending topics
            let trendingContent: [UUID]
            
            if let category = topic.category {
                trendingContent = postService.posts
                    .filter { $0.category == category && $0.isVisible }
                    .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                    .sorted { $0.engagementScore > $1.engagementScore }
                    .prefix(2)
                    .map { $0.id }
            } else if let tag = topic.tag {
                let posts = postService.posts
                    .filter { $0.tags.contains(tag) && $0.isVisible }
                    .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                    .prefix(1)
                    .map { $0.id }
                
                let reviews = reviewService.reviews
                    .filter { $0.tags.contains(tag) && $0.isVisible }
                    .filter { !hasUserInteracted(userId: userId, contentId: $0.id) }
                    .prefix(1)
                    .map { $0.id }
                
                trendingContent = posts + reviews
            } else {
                continue
            }
            
            for contentId in trendingContent {
                let contentType = getContentType(for: contentId)
                let score = topic.trendingScore * 0.8 // Slightly lower than direct preferences
                
                let recommendation = ContentRecommendation(
                    userId: userId,
                    contentId: contentId,
                    contentType: contentType,
                    recommendationScore: score,
                    recommendationReason: .trendingTopic
                )
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    private func generateSimilarUserRecommendations(for userId: UUID, interactions: [UserInteraction]) async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Find users with similar interaction patterns
        let similarUsers = findSimilarUsers(for: userId, interactions: interactions)
        
        for similarUserId in similarUsers.prefix(3) {
            let similarUserInteractions = userInteractions
                .filter { $0.userId == similarUserId && $0.interactionType == .upvote }
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(5)
            
            for interaction in similarUserInteractions {
                if !hasUserInteracted(userId: userId, contentId: interaction.contentId) {
                    let score = interaction.weight * 0.6 // Lower score for similar user recommendations
                    
                    let recommendation = ContentRecommendation(
                        userId: userId,
                        contentId: interaction.contentId,
                        contentType: interaction.contentType,
                        recommendationScore: score,
                        recommendationReason: .similarUsers
                    )
                    recommendations.append(recommendation)
                }
            }
        }
        
        return recommendations
    }
    
    private func calculateTrendingTopics() async {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-trendingTimeWindow)
        
        var topicScores: [String: (count: Int, engagement: Double)] = [:]
        
        // Calculate trending categories
        let recentPosts = postService.posts.filter { $0.createdAt > cutoffTime }
        for post in recentPosts {
            let key = "category:\(post.category.rawValue)"
            let current = topicScores[key] ?? (count: 0, engagement: 0.0)
            topicScores[key] = (
                count: current.count + 1,
                engagement: current.engagement + post.engagementScore
            )
        }
        
        // Calculate trending tags
        let allTags = recentPosts.flatMap { $0.tags } + reviewService.reviews
            .filter { $0.createdAt > cutoffTime }
            .flatMap { $0.tags }
        
        let tagCounts = Dictionary(grouping: allTags) { $0 }
            .mapValues { $0.count }
        
        for (tag, count) in tagCounts where count >= 3 {
            let key = "tag:\(tag)"
            let engagement = calculateTagEngagement(tag: tag, since: cutoffTime)
            topicScores[key] = (count: count, engagement: engagement)
        }
        
        // Convert to trending topics
        let newTrendingTopics = topicScores.compactMap { (key, value) -> TrendingTopic? in
            let trendingScore = Double(value.count) * 0.3 + value.engagement * 0.7
            
            if key.hasPrefix("category:") {
                let categoryName = String(key.dropFirst(9))
                guard let category = PostCategory(rawValue: categoryName) else { return nil }
                
                return TrendingTopic(
                    topic: category.displayName,
                    category: category,
                    contentCount: value.count,
                    engagementScore: value.engagement,
                    trendingScore: trendingScore
                )
            } else if key.hasPrefix("tag:") {
                let tag = String(key.dropFirst(4))
                
                return TrendingTopic(
                    topic: tag,
                    tag: tag,
                    contentCount: value.count,
                    engagementScore: value.engagement,
                    trendingScore: trendingScore
                )
            }
            
            return nil
        }
        .sorted { $0.trendingScore > $1.trendingScore }
        
        trendingTopics = newTrendingTopics
    }
    
    private func calculatePopularContent() async {
        let allContent: [(id: UUID, score: Double)] = 
            postService.posts.map { (id: $0.id, score: $0.engagementScore) } +
            reviewService.reviews.map { (id: $0.id, score: Double($0.netScore)) }
        
        let sortedContent = allContent
            .filter { $0.score >= Double(popularContentThreshold) }
            .sorted { $0.score > $1.score }
            .map { $0.id }
        
        popularContent = sortedContent
    }
    
    // MARK: - Helper Methods
    
    private func updateUserPreferences(for userId: UUID, interaction: UserInteraction) async {
        var preferences = userPreferences[userId] ?? UserPreferences(userId: userId)
        
        // Update preferences based on positive interactions
        if interaction.interactionType == .upvote || interaction.interactionType == .comment {
            if interaction.contentType == .post,
               let post = postService.posts.first(where: { $0.id == interaction.contentId }) {
                
                // Add category preference
                if !preferences.preferredCategories.contains(post.category) {
                    preferences.preferredCategories.append(post.category)
                }
                
                // Add tag preferences
                for tag in post.tags {
                    if !preferences.preferredTags.contains(tag) {
                        preferences.preferredTags.append(tag)
                    }
                }
            } else if interaction.contentType == .review,
                      let review = reviewService.reviews.first(where: { $0.id == interaction.contentId }) {
                
                // Add dating app preference
                if !preferences.preferredDatingApps.contains(review.datingApp) {
                    preferences.preferredDatingApps.append(review.datingApp)
                }
                
                // Add tag preferences
                for tag in review.tags {
                    if !preferences.preferredTags.contains(tag) {
                        preferences.preferredTags.append(tag)
                    }
                }
            }
        }
        
        // Update content type preferences
        let currentWeight = preferences.contentTypePreferences[interaction.contentType] ?? 1.0
        let adjustment = interaction.weight > 0 ? 0.1 : -0.1
        preferences.contentTypePreferences[interaction.contentType] = max(0.1, currentWeight + adjustment)
        
        preferences.lastUpdated = Date()
        userPreferences[userId] = preferences
    }
    
    private func hasUserInteracted(userId: UUID, contentId: UUID) -> Bool {
        return userInteractions.contains { 
            $0.userId == userId && $0.contentId == contentId 
        }
    }
    
    private func getContentType(for contentId: UUID) -> ContentType {
        if postService.posts.contains(where: { $0.id == contentId }) {
            return .post
        } else if reviewService.reviews.contains(where: { $0.id == contentId }) {
            return .review
        } else {
            return .comment
        }
    }
    
    private func calculateCategoryScore(post: DatingReviewPost, preferences: UserPreferences) -> Double {
        let baseScore = post.engagementScore
        let categoryBonus = preferences.preferredCategories.contains(post.category) ? 2.0 : 1.0
        let contentTypeWeight = preferences.contentTypePreferences[.post] ?? 1.0
        
        return baseScore * categoryBonus * contentTypeWeight
    }
    
    private func calculateTagScore(post: DatingReviewPost, preferences: UserPreferences) -> Double {
        let baseScore = post.engagementScore
        let tagMatches = post.tags.filter { preferences.preferredTags.contains($0) }.count
        let tagBonus = 1.0 + (Double(tagMatches) * 0.5)
        let contentTypeWeight = preferences.contentTypePreferences[.post] ?? 1.0
        
        return baseScore * tagBonus * contentTypeWeight
    }
    
    private func calculateReviewTagScore(review: Review, preferences: UserPreferences) -> Double {
        let baseScore = Double(review.netScore)
        let tagMatches = review.tags.filter { preferences.preferredTags.contains($0) }.count
        let tagBonus = 1.0 + (Double(tagMatches) * 0.5)
        let appBonus = preferences.preferredDatingApps.contains(review.datingApp) ? 1.5 : 1.0
        let contentTypeWeight = preferences.contentTypePreferences[.review] ?? 1.0
        
        return baseScore * tagBonus * appBonus * contentTypeWeight
    }
    
    private func calculatePopularityScore(for contentId: UUID) -> Double {
        if let post = postService.posts.first(where: { $0.id == contentId }) {
            return post.engagementScore * 1.2 // Boost for popular content
        } else if let review = reviewService.reviews.first(where: { $0.id == contentId }) {
            return Double(review.netScore) * 1.2
        }
        return 0.0
    }
    
    private func calculateTagEngagement(tag: String, since: Date) -> Double {
        let taggedPosts = postService.posts
            .filter { $0.tags.contains(tag) && $0.createdAt > since }
        
        let taggedReviews = reviewService.reviews
            .filter { $0.tags.contains(tag) && $0.createdAt > since }
        
        let postEngagement = taggedPosts.reduce(0.0) { $0 + $1.engagementScore }
        let reviewEngagement = taggedReviews.reduce(0.0) { $0 + Double($1.netScore) }
        
        return postEngagement + reviewEngagement
    }
    
    private func findSimilarUsers(for userId: UUID, interactions: [UserInteraction]) -> [UUID] {
        let userContentIds = Set(interactions.map { $0.contentId })
        var userSimilarity: [UUID: Double] = [:]
        
        // Group interactions by user
        let otherUserInteractions = Dictionary(grouping: userInteractions.filter { $0.userId != userId }) { $0.userId }
        
        for (otherUserId, otherInteractions) in otherUserInteractions {
            let otherContentIds = Set(otherInteractions.map { $0.contentId })
            let intersection = userContentIds.intersection(otherContentIds)
            let union = userContentIds.union(otherContentIds)
            
            // Calculate Jaccard similarity
            let similarity = Double(intersection.count) / Double(union.count)
            userSimilarity[otherUserId] = similarity
        }
        
        return userSimilarity
            .filter { $0.value > 0.1 } // Minimum similarity threshold
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
}

// MARK: - Content Recommendation Error
enum ContentRecommendationError: Error, LocalizedError {
    case invalidUserId
    case contentNotFound
    case insufficientData
    case calculationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID provided"
        case .contentNotFound:
            return "Content not found"
        case .insufficientData:
            return "Insufficient data for recommendations"
        case .calculationFailed:
            return "Failed to calculate recommendations"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}