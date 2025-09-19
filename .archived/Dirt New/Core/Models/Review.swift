import Foundation

struct Review: Codable, Identifiable, Equatable {
    let id: String
    let authorId: String
    let authorName: String
    let title: String
    let content: String
    let rating: Double // 1.0 to 5.0
    let category: ReviewCategory?
    let tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
    var isVisible: Bool
    var isReported: Bool
    var reportCount: Int
    var imageUrls: [String]
    let location: String?
    
    // Review-specific fields
    var venue: String?
    var cost: CostLevel?
    var duration: TimeInterval?
    var wouldRecommend: Bool
    
    // Engagement metrics
    var viewCount: Int
    var shareCount: Int
    var saveCount: Int
    
    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorName: String,
        title: String,
        content: String,
        rating: Double,
        category: ReviewCategory? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        likeCount: Int = 0,
        commentCount: Int = 0,
        isLiked: Bool = false,
        isVisible: Bool = true,
        isReported: Bool = false,
        reportCount: Int = 0,
        imageUrls: [String] = [],
        location: String? = nil,
        venue: String? = nil,
        cost: CostLevel? = nil,
        duration: TimeInterval? = nil,
        wouldRecommend: Bool = true,
        viewCount: Int = 0,
        shareCount: Int = 0,
        saveCount: Int = 0
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.title = title
        self.content = content
        self.rating = rating
        self.category = category
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.isVisible = isVisible
        self.isReported = isReported
        self.reportCount = reportCount
        self.imageUrls = imageUrls
        self.location = location
        self.venue = venue
        self.cost = cost
        self.duration = duration
        self.wouldRecommend = wouldRecommend
        self.viewCount = viewCount
        self.shareCount = shareCount
        self.saveCount = saveCount
    }
    
    var engagementScore: Double {
        let baseScore = Double(likeCount * 2 + commentCount * 3 + shareCount * 4 + saveCount * 5)
        let ratingBonus = rating * 2
        let penaltyScore = Double(reportCount * 10)
        return max(0, baseScore + ratingBonus - penaltyScore)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var hasImages: Bool {
        return !imageUrls.isEmpty
    }
    
    var ratingStars: String {
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        
        return String(repeating: "★", count: fullStars) +
               (hasHalfStar ? "☆" : "") +
               String(repeating: "☆", count: emptyStars)
    }
    
    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum CostLevel: String, CaseIterable, Codable {
    case free = "free"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case luxury = "luxury"
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .low:
            return "$"
        case .medium:
            return "$$"
        case .high:
            return "$$$"
        case .luxury:
            return "$$$$"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "Free activities"
        case .low:
            return "Budget-friendly ($0-25)"
        case .medium:
            return "Moderate cost ($25-75)"
        case .high:
            return "Expensive ($75-150)"
        case .luxury:
            return "Luxury ($150+)"
        }
    }
    
    var color: String {
        switch self {
        case .free:
            return "green"
        case .low:
            return "blue"
        case .medium:
            return "orange"
        case .high:
            return "red"
        case .luxury:
            return "purple"
        }
    }
}

// Note: ReviewCategory is defined in ReviewsViewModel.swift
// This allows for better separation of concerns and avoids circular dependencies