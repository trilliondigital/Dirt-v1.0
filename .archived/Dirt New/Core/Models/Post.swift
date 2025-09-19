import Foundation

struct Post: Codable, Identifiable, Equatable {
    let id: UUID
    let authorId: UUID
    let title: String
    let content: String
    let category: PostCategory
    let sentiment: PostSentiment
    let tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var upvotes: Int
    var downvotes: Int
    var commentCount: Int
    var isVisible: Bool
    var isReported: Bool
    var reportCount: Int
    var mediaURLs: [String]
    
    // Engagement metrics
    var viewCount: Int
    var shareCount: Int
    var saveCount: Int
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        title: String,
        content: String,
        category: PostCategory,
        sentiment: PostSentiment,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        upvotes: Int = 0,
        downvotes: Int = 0,
        commentCount: Int = 0,
        isVisible: Bool = true,
        isReported: Bool = false,
        reportCount: Int = 0,
        mediaURLs: [String] = [],
        viewCount: Int = 0,
        shareCount: Int = 0,
        saveCount: Int = 0
    ) {
        self.id = id
        self.authorId = authorId
        self.title = title
        self.content = content
        self.category = category
        self.sentiment = sentiment
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.commentCount = commentCount
        self.isVisible = isVisible
        self.isReported = isReported
        self.reportCount = reportCount
        self.mediaURLs = mediaURLs
        self.viewCount = viewCount
        self.shareCount = shareCount
        self.saveCount = saveCount
    }
    
    var netScore: Int {
        return upvotes - downvotes
    }
    
    var engagementScore: Double {
        let baseScore = Double(upvotes * 2 + commentCount * 3 + shareCount * 4 + saveCount * 5)
        let penaltyScore = Double(downvotes + reportCount * 10)
        return max(0, baseScore - penaltyScore)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var hasMedia: Bool {
        return !mediaURLs.isEmpty
    }
}

enum PostCategory: String, CaseIterable, Codable {
    case advice = "advice"
    case experience = "experience"
    case question = "question"
    case strategy = "strategy"
    case success = "success"
    case rant = "rant"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .advice:
            return "Advice"
        case .experience:
            return "Experience"
        case .question:
            return "Question"
        case .strategy:
            return "Strategy"
        case .success:
            return "Success Story"
        case .rant:
            return "Rant"
        case .general:
            return "General"
        }
    }
    
    var iconName: String {
        switch self {
        case .advice:
            return "lightbulb"
        case .experience:
            return "person.2"
        case .question:
            return "questionmark.circle"
        case .strategy:
            return "target"
        case .success:
            return "star"
        case .rant:
            return "exclamationmark.triangle"
        case .general:
            return "bubble.left.and.bubble.right"
        }
    }
    
    var description: String {
        switch self {
        case .advice:
            return "Share helpful tips and guidance"
        case .experience:
            return "Tell your dating stories"
        case .question:
            return "Ask the community for help"
        case .strategy:
            return "Discuss dating approaches"
        case .success:
            return "Celebrate your wins"
        case .rant:
            return "Vent your frustrations"
        case .general:
            return "General discussion"
        }
    }
}

enum PostSentiment: String, CaseIterable, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .positive:
            return "Green Flag"
        case .negative:
            return "Red Flag"
        case .neutral:
            return "Neutral"
        }
    }
    
    var color: String {
        switch self {
        case .positive:
            return "green"
        case .negative:
            return "red"
        case .neutral:
            return "gray"
        }
    }
    
    var iconName: String {
        switch self {
        case .positive:
            return "checkmark.circle.fill"
        case .negative:
            return "xmark.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
}