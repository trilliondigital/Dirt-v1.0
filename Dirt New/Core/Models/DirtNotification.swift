import Foundation

struct DirtNotification: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let type: NotificationType
    let title: String
    let message: String
    let data: NotificationData?
    let createdAt: Date
    var isRead: Bool
    var deliveredAt: Date?
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        type: NotificationType,
        title: String,
        message: String,
        data: NotificationData? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false,
        deliveredAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.data = data
        self.createdAt = createdAt
        self.isRead = isRead
        self.deliveredAt = deliveredAt
    }
}

enum NotificationType: String, Codable, CaseIterable {
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
    
    // System notifications
    case recommendation = "recommendation"
    case featureUnlock = "feature_unlock"
    
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
        case .recommendation:
            return "Recommendation"
        case .featureUnlock:
            return "Feature Unlock"
        }
    }
    
    var iconName: String {
        switch self {
        case .reply:
            return "bubble.left"
        case .upvote:
            return "arrow.up.circle"
        case .mention:
            return "at"
        case .comment:
            return "bubble.right"
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
            return "arrow.up.circle.badge"
        case .popularPost:
            return "flame.circle"
        case .helpfulContributor:
            return "star.circle.fill"
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
        case .recommendation:
            return "lightbulb"
        case .featureUnlock:
            return "lock.open"
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
        case .announcement, .featureUpdate, .communityEvent, .moderationUpdate, .recommendation, .featureUnlock:
            return .community
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .recommendation:
            return .low
        case .reply, .upvote, .mention, .comment, .firstPost, .firstUpvote:
            return .medium
        case .reputationMilestone, .postMilestone, .engagementMilestone, .anniversaryMilestone, .popularPost, .helpfulContributor, .communityChampion, .announcement, .featureUpdate, .communityEvent:
            return .high
        case .moderationUpdate, .featureUnlock:
            return .urgent
        }
    }
}

struct NotificationData: Codable, Equatable {
    let postId: UUID?
    let commentId: UUID?
    let authorId: UUID?
    let authorUsername: String?
    let reputationChange: Int?
    let achievementType: String?
    let milestoneLevel: String?
    let deepLinkPath: String?
    let metadata: [String: String]?
    
    init(
        postId: UUID? = nil,
        commentId: UUID? = nil,
        authorId: UUID? = nil,
        authorUsername: String? = nil,
        reputationChange: Int? = nil,
        achievementType: String? = nil,
        milestoneLevel: String? = nil,
        deepLinkPath: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.postId = postId
        self.commentId = commentId
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.reputationChange = reputationChange
        self.achievementType = achievementType
        self.milestoneLevel = milestoneLevel
        self.deepLinkPath = deepLinkPath
        self.metadata = metadata
    }
}

// MARK: - Notification Categories

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
            return "Replies, upvotes, mentions, and comments on your posts"
        case .milestone:
            return "Reputation, post count, and engagement milestones"
        case .achievement:
            return "Badges and special accomplishments"
        case .community:
            return "Announcements, updates, and community events"
        }
    }
    
    var iconName: String {
        switch self {
        case .interaction:
            return "person.2"
        case .milestone:
            return "star"
        case .achievement:
            return "trophy"
        case .community:
            return "megaphone"
        }
    }
}

// MARK: - Notification Priority

enum NotificationPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }
    
    var soundName: String? {
        switch self {
        case .low:
            return nil
        case .medium:
            return "default"
        case .high:
            return "default"
        case .urgent:
            return "alarm"
        }
    }
    
    @available(iOS 15.0, *)
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

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var isEnabled: Bool = true
    var categoryPreferences: [NotificationCategory: Bool] = [:]
    var typePreferences: [NotificationType: Bool] = [:]
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Int = 22 // 10 PM
    var quietHoursEnd: Int = 8   // 8 AM
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true
    var previewEnabled: Bool = true
    
    init() {
        // Set default preferences
        for category in NotificationCategory.allCases {
            categoryPreferences[category] = true
        }
        
        for type in NotificationType.allCases {
            typePreferences[type] = true
        }
    }
    
    func isTypeEnabled(_ type: NotificationType) -> Bool {
        guard isEnabled else { return false }
        guard categoryPreferences[type.category] == true else { return false }
        return typePreferences[type] == true
    }
    
    func isCategoryEnabled(_ category: NotificationCategory) -> Bool {
        guard isEnabled else { return false }
        return categoryPreferences[category] == true
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Calendar.current.component(.hour, from: Date())
        
        if quietHoursStart < quietHoursEnd {
            // Same day (e.g., 10 AM to 6 PM)
            return now >= quietHoursStart && now < quietHoursEnd
        } else {
            // Crosses midnight (e.g., 10 PM to 8 AM)
            return now >= quietHoursStart || now < quietHoursEnd
        }
    }
}