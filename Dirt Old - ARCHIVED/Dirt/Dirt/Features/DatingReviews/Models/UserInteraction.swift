import Foundation

// MARK: - User Interaction Model
struct UserInteraction: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let contentId: UUID
    let contentType: ContentType
    let interactionType: InteractionType
    let timestamp: Date
    var weight: Double // Interaction strength (1.0 = view, 2.0 = upvote, 3.0 = comment, etc.)
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        interactionType: InteractionType,
        timestamp: Date = Date(),
        weight: Double
    ) {
        self.id = id
        self.userId = userId
        self.contentId = contentId
        self.contentType = contentType
        self.interactionType = interactionType
        self.timestamp = timestamp
        self.weight = weight
    }
}

// MARK: - Content Type
enum ContentType: String, Codable, CaseIterable {
    case review = "review"
    case post = "post"
    case comment = "comment"
}

// MARK: - Interaction Type
enum InteractionType: String, Codable, CaseIterable {
    case view = "view"
    case upvote = "upvote"
    case downvote = "downvote"
    case comment = "comment"
    case share = "share"
    case save = "save"
    case report = "report"
    
    var weight: Double {
        switch self {
        case .view:
            return 1.0
        case .upvote:
            return 2.0
        case .downvote:
            return -1.0
        case .comment:
            return 3.0
        case .share:
            return 2.5
        case .save:
            return 2.5
        case .report:
            return -2.0
        }
    }
}

// MARK: - User Preferences Model
struct UserPreferences: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    var preferredCategories: [PostCategory]
    var preferredTags: [String]
    var preferredDatingApps: [DatingApp]
    var contentTypePreferences: [ContentType: Double] // Preference weights
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        preferredCategories: [PostCategory] = [],
        preferredTags: [String] = [],
        preferredDatingApps: [DatingApp] = [],
        contentTypePreferences: [ContentType: Double] = [
            .review: 1.0,
            .post: 1.0,
            .comment: 0.5
        ],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.preferredCategories = preferredCategories
        self.preferredTags = preferredTags
        self.preferredDatingApps = preferredDatingApps
        self.contentTypePreferences = contentTypePreferences
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Trending Topic Model
struct TrendingTopic: Codable, Identifiable, Equatable {
    let id: UUID
    let topic: String
    let category: PostCategory?
    let tag: String?
    let contentCount: Int
    let engagementScore: Double
    let trendingScore: Double
    let timeWindow: TimeInterval // Hours
    let calculatedAt: Date
    
    init(
        id: UUID = UUID(),
        topic: String,
        category: PostCategory? = nil,
        tag: String? = nil,
        contentCount: Int,
        engagementScore: Double,
        trendingScore: Double,
        timeWindow: TimeInterval = 24 * 60 * 60, // 24 hours
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.category = category
        self.tag = tag
        self.contentCount = contentCount
        self.engagementScore = engagementScore
        self.trendingScore = trendingScore
        self.timeWindow = timeWindow
        self.calculatedAt = calculatedAt
    }
}

// MARK: - Content Recommendation Model
struct ContentRecommendation: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let contentId: UUID
    let contentType: ContentType
    let recommendationScore: Double
    let recommendationReason: RecommendationReason
    let generatedAt: Date
    var isViewed: Bool
    var isInteracted: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        recommendationScore: Double,
        recommendationReason: RecommendationReason,
        generatedAt: Date = Date(),
        isViewed: Bool = false,
        isInteracted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.contentId = contentId
        self.contentType = contentType
        self.recommendationScore = recommendationScore
        self.recommendationReason = recommendationReason
        self.generatedAt = generatedAt
        self.isViewed = isViewed
        self.isInteracted = isInteracted
    }
}

// MARK: - Recommendation Reason
enum RecommendationReason: String, Codable, CaseIterable {
    case similarInterests = "similar_interests"
    case popularContent = "popular_content"
    case trendingTopic = "trending_topic"
    case categoryPreference = "category_preference"
    case tagPreference = "tag_preference"
    case highRated = "high_rated"
    case recentActivity = "recent_activity"
    case similarUsers = "similar_users"
    
    var displayName: String {
        switch self {
        case .similarInterests:
            return "Based on your interests"
        case .popularContent:
            return "Popular in community"
        case .trendingTopic:
            return "Trending now"
        case .categoryPreference:
            return "Matches your preferences"
        case .tagPreference:
            return "Related to your interests"
        case .highRated:
            return "Highly rated content"
        case .recentActivity:
            return "Recent activity"
        case .similarUsers:
            return "Users like you also viewed"
        }
    }
}