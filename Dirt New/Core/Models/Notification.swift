import Foundation
import UserNotifications

// MARK: - Notification Models

struct DirtNotification: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let message: String
    let data: NotificationData?
    let createdAt: Date
    var isRead: Bool
    var isDelivered: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        type: NotificationType,
        title: String,
        message: String,
        data: NotificationData? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false,
        isDelivered: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.data = data
        self.createdAt = createdAt
        self.isRead = isRead
        self.isDelivered = isDelivered
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Notification Types

enum NotificationType: String, CaseIterable, Codable {
    // Interaction notifications
    case reply = "reply"
    case upvote = "upvote"
    case mention = "mention"
    case comment = "comment"
    
    // Milestone notifications
    case reputationMilestone = "reputation_milestone"
    case postMilestone = "post_milestone"
    case engagementMilestone = "engagement_milestone"
    case anniversaryMilestone = "anniversary_milestone"
    
    // Achievement notifications
    case firstPost = "first_post"
    case firstUpvote = "first_upvote"
    case popularPost = "popular_post"
    case helpfulContributor = "helpful_contributor"
    case communityChampion = "community_champion"
    
    // Community notifications
    case announcement = "announcement"
    case featureUpdate = "feature_update"
    case communityEvent = "community_event"
    case moderationUpdate = "moderation_update"
    
    var displayName: String {
        switch self {
        case .reply:
            return "Reply"
        case .upvote:
            return "Upvote"
        case .mention:
            return "Mention"
        case .comment:
            return "Comment"
        case .reputationMilestone:
            return "Reputation Milestone"
        case .postMilestone:
            return "Post Milestone"
        case .engagementMilestone:
            return "Engagement Milestone"
        case .anniversaryMilestone:
            return "Anniversary"
        case .firstPost:
            return "First Post"
        case .firstUpvote:
            return "First Upvote"
        case .popularPost:
            return "Popular Post"
        case .helpfulContributor:
            return "Helpful Contributor"
        case .communityChampion:
            return "Community Champion"
        case .announcement:
            return "Announcement"
        case .featureUpdate:
            return "Feature Update"
        case .communityEvent:
            return "Community Event"
        case .moderationUpdate:
            return "Moderation Update"
        }
    }
    
    var iconName: String {
        switch self {
        case .reply:
            return "arrowshape.turn.up.left"
        case .upvote:
            return "arrow.up.circle"
        case .mention:
            return "at"
        case .comment:
            return "bubble.left"
        case .reputationMilestone:
            return "star.circle"
        case .postMilestone:
            return "doc.circle"
        case .engagementMilestone:
            return "heart.circle"
        case .anniversaryMilestone:
            return "calendar.circle"
        case .firstPost:
            return "doc.badge.plus"
        case .firstUpvote:
            return "arrow.up.heart"
        case .popularPost:
            return "flame"
        case .helpfulContributor:
            return "hand.thumbsup"
        case .communityChampion:
            return "crown"
        case .announcement:
            return "megaphone"
        case .featureUpdate:
            return "sparkles"
        case .communityEvent:
            return "calendar.badge.plus"
        case .moderationUpdate:
            return "shield"
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .reply, .mention, .comment:
            return .high
        case .upvote:
            return .medium
        case .reputationMilestone, .anniversaryMilestone, .firstPost, .firstUpvote, .popularPost:
            return .medium
        case .postMilestone, .engagementMilestone, .helpfulContributor, .communityChampion:
            return .low
        case .announcement, .moderationUpdate:
            return .high
        case .featureUpdate, .communityEvent:
            return .medium
        }
    }
    
    var category: NotificationCategory {
        switch self {
        case .reply, .upvote, .mention, .comment:
            return .interaction
        case .reputationMilestone, .postMilestone, .engagementMilestone, .anniversaryMilestone:
            return .milestone
        case .firstPost, .firstUpvote, .popularPost, .helpfulContributor, .communityChampion:
            return .achievement
        case .announcement, .featureUpdate, .communityEvent, .moderationUpdate:
            return .community
        }
    }
}

// MARK: - Notification Priority

enum NotificationPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var soundName: String? {
        switch self {
        case .low:
            return nil
        case .medium:
            return "default"
        case .high:
            return "default"
        case .urgent:
            return "urgent"
        }
    }
    
    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .low:
            return .passive
        case .medium:
            return .active
        case .high:
            return .timeSensitive
        case .urgent:
            return .critical
        }
    }
}

// MARK: - Notification Category

enum NotificationCategory: String, CaseIterable, Codable {
    case interaction = "interaction"
    case milestone = "milestone"
    case achievement = "achievement"
    case community = "community"
    
    var displayName: String {
        switch self {
        case .interaction:
            return "Interactions"
        case .milestone:
            return "Milestones"
        case .achievement:
            return "Achievements"
        case .community:
            return "Community"
        }
    }
    
    var description: String {
        switch self {
        case .interaction:
            return "Replies, upvotes, and mentions"
        case .milestone:
            return "Reputation and engagement milestones"
        case .achievement:
            return "Badges and accomplishments"
        case .community:
            return "Announcements and updates"
        }
    }
}

// MARK: - Notification Data

struct NotificationData: Codable, Equatable {
    let postId: UUID?
    let commentId: UUID?
    let authorId: UUID?
    let deepLinkPath: String?
    let metadata: [String: String]?
    
    init(
        postId: UUID? = nil,
        commentId: UUID? = nil,
        authorId: UUID? = nil,
        deepLinkPath: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.postId = postId
        self.commentId = commentId
        self.authorId = authorId
        self.deepLinkPath = deepLinkPath
        self.metadata = metadata
    }
}

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var isEnabled: Bool
    var categoryPreferences: [NotificationCategory: Bool]
    var typePreferences: [NotificationType: Bool]
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour of day (0-23)
    var quietHoursEnd: Int // Hour of day (0-23)
    var soundEnabled: Bool
    var badgeEnabled: Bool
    var previewEnabled: Bool
    
    init() {
        self.isEnabled = true
        self.categoryPreferences = Dictionary(uniqueKeysWithValues: NotificationCategory.allCases.map { ($0, true) })
        self.typePreferences = Dictionary(uniqueKeysWithValues: NotificationType.allCases.map { ($0, true) })
        self.quietHoursEnabled = false
        self.quietHoursStart = 22 // 10 PM
        self.quietHoursEnd = 8 // 8 AM
        self.soundEnabled = true
        self.badgeEnabled = true
        self.previewEnabled = true
    }
    
    func isTypeEnabled(_ type: NotificationType) -> Bool {
        guard isEnabled else { return false }
        guard categoryPreferences[type.category] == true else { return false }
        return typePreferences[type] == true
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        if quietHoursStart < quietHoursEnd {
            // Same day quiet hours (e.g., 10 PM to 8 AM next day)
            return currentHour >= quietHoursStart || currentHour < quietHoursEnd
        } else {
            // Cross-midnight quiet hours (e.g., 22:00 to 08:00)
            return currentHour >= quietHoursStart && currentHour < quietHoursEnd
        }
    }
}