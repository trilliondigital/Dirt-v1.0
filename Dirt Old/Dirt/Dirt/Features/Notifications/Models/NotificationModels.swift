import Foundation
import UserNotifications

// MARK: - Notification Models

struct DirtNotification: Identifiable, Codable, Equatable {
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

// MARK: - Notification Types

enum NotificationType: String, Codable, CaseIterable {
    case reply = "reply"
    case upvote = "upvote"
    case mention = "mention"
    case milestone = "milestone"
    case achievement = "achievement"
    case announcement = "announcement"
    case recommendation = "recommendation"
    case moderation = "moderation"
    case featureUnlock = "feature_unlock"
    
    var displayName: String {
        switch self {
        case .reply:
            return "Reply"
        case .upvote:
            return "Upvote"
        case .mention:
            return "Mention"
        case .milestone:
            return "Milestone"
        case .achievement:
            return "Achievement"
        case .announcement:
            return "Announcement"
        case .recommendation:
            return "Recommendation"
        case .moderation:
            return "Moderation"
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
        case .milestone:
            return "star.circle"
        case .achievement:
            return "trophy"
        case .announcement:
            return "megaphone"
        case .recommendation:
            return "lightbulb"
        case .moderation:
            return "shield"
        case .featureUnlock:
            return "lock.open"
        }
    }
    
    var priority: NotificationPriority {
        switch self {
        case .reply, .mention:
            return .high
        case .upvote, .recommendation:
            return .normal
        case .milestone, .achievement, .featureUnlock:
            return .high
        case .announcement:
            return .urgent
        case .moderation:
            return .urgent
        }
    }
}

// MARK: - Notification Priority

enum NotificationPriority: String, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var soundName: UNNotificationSound {
        switch self {
        case .low, .normal:
            return .default
        case .high:
            return UNNotificationSound(named: UNNotificationSoundName("notification_high.wav"))
        case .urgent:
            return UNNotificationSound(named: UNNotificationSoundName("notification_urgent.wav"))
        }
    }
}

// MARK: - Notification Data

struct NotificationData: Codable, Equatable {
    let contentId: UUID?
    let contentType: ContentType?
    let authorId: UUID?
    let authorUsername: String?
    let reputationChange: Int?
    let achievementType: String?
    let milestoneLevel: String?
    let deepLinkPath: String?
    
    init(
        contentId: UUID? = nil,
        contentType: ContentType? = nil,
        authorId: UUID? = nil,
        authorUsername: String? = nil,
        reputationChange: Int? = nil,
        achievementType: String? = nil,
        milestoneLevel: String? = nil,
        deepLinkPath: String? = nil
    ) {
        self.contentId = contentId
        self.contentType = contentType
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.reputationChange = reputationChange
        self.achievementType = achievementType
        self.milestoneLevel = milestoneLevel
        self.deepLinkPath = deepLinkPath
    }
}

// MARK: - Notification Templates

struct NotificationTemplate {
    static func reply(from username: String, contentType: ContentType) -> (title: String, message: String) {
        let contentTypeText = contentType == .post ? "post" : "review"
        return (
            title: "New Reply",
            message: "\(username) replied to your \(contentTypeText)"
        )
    }
    
    static func upvote(count: Int, contentType: ContentType) -> (title: String, message: String) {
        let contentTypeText = contentType == .post ? "post" : "review"
        if count == 1 {
            return (
                title: "Your \(contentTypeText) was upvoted!",
                message: "Someone liked your content"
            )
        } else {
            return (
                title: "Your \(contentTypeText) is popular!",
                message: "You've received \(count) upvotes"
            )
        }
    }
    
    static func mention(from username: String, contentType: ContentType) -> (title: String, message: String) {
        let contentTypeText = contentType == .post ? "post" : "comment"
        return (
            title: "You were mentioned",
            message: "\(username) mentioned you in a \(contentTypeText)"
        )
    }
    
    static func milestone(level: String, reputation: Int) -> (title: String, message: String) {
        return (
            title: "Reputation Milestone! ⭐",
            message: "You've reached \(reputation) points and are now a \(level)!"
        )
    }
    
    static func achievement(type: String) -> (title: String, message: String) {
        return (
            title: "Achievement Unlocked! 🏆",
            message: "You've earned the \"\(type)\" achievement"
        )
    }
    
    static func announcement(title: String, message: String) -> (title: String, message: String) {
        return (
            title: "📢 \(title)",
            message: message
        )
    }
    
    static func recommendation(contentType: ContentType, category: String) -> (title: String, message: String) {
        let contentTypeText = contentType == .post ? "posts" : "reviews"
        return (
            title: "New content for you",
            message: "Check out trending \(contentTypeText) in \(category)"
        )
    }
    
    static func moderation(action: String, reason: String) -> (title: String, message: String) {
        return (
            title: "Content Moderation",
            message: "Your content was \(action): \(reason)"
        )
    }
    
    static func featureUnlock(feature: String) -> (title: String, message: String) {
        return (
            title: "New Feature Unlocked! 🔓",
            message: "Your reputation has unlocked: \(feature)"
        )
    }
}

// MARK: - Notification Batch

struct NotificationBatch {
    let notifications: [DirtNotification]
    let batchId: UUID
    let createdAt: Date
    
    init(notifications: [DirtNotification]) {
        self.notifications = notifications
        self.batchId = UUID()
        self.createdAt = Date()
    }
    
    var count: Int {
        notifications.count
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var pushNotificationsEnabled: Bool
    var repliesEnabled: Bool
    var upvotesEnabled: Bool
    var mentionsEnabled: Bool
    var milestonesEnabled: Bool
    var achievementsEnabled: Bool
    var announcementsEnabled: Bool
    var recommendationsEnabled: Bool
    var moderationEnabled: Bool
    var featureUnlocksEnabled: Bool
    var quietHoursEnabled: Bool
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var upvoteThreshold: Int // Only notify after X upvotes
    
    init(
        pushNotificationsEnabled: Bool = true,
        repliesEnabled: Bool = true,
        upvotesEnabled: Bool = true,
        mentionsEnabled: Bool = true,
        milestonesEnabled: Bool = true,
        achievementsEnabled: Bool = true,
        announcementsEnabled: Bool = true,
        recommendationsEnabled: Bool = false,
        moderationEnabled: Bool = true,
        featureUnlocksEnabled: Bool = true,
        quietHoursEnabled: Bool = false,
        quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date(),
        quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8)) ?? Date(),
        upvoteThreshold: Int = 1
    ) {
        self.pushNotificationsEnabled = pushNotificationsEnabled
        self.repliesEnabled = repliesEnabled
        self.upvotesEnabled = upvotesEnabled
        self.mentionsEnabled = mentionsEnabled
        self.milestonesEnabled = milestonesEnabled
        self.achievementsEnabled = achievementsEnabled
        self.announcementsEnabled = announcementsEnabled
        self.recommendationsEnabled = recommendationsEnabled
        self.moderationEnabled = moderationEnabled
        self.featureUnlocksEnabled = featureUnlocksEnabled
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.upvoteThreshold = upvoteThreshold
    }
    
    func isNotificationEnabled(for type: NotificationType) -> Bool {
        guard pushNotificationsEnabled else { return false }
        
        switch type {
        case .reply:
            return repliesEnabled
        case .upvote:
            return upvotesEnabled
        case .mention:
            return mentionsEnabled
        case .milestone:
            return milestonesEnabled
        case .achievement:
            return achievementsEnabled
        case .announcement:
            return announcementsEnabled
        case .recommendation:
            return recommendationsEnabled
        case .moderation:
            return moderationEnabled
        case .featureUnlock:
            return featureUnlocksEnabled
        }
    }
    
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endTime = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        let startMinutes = (startTime.hour ?? 0) * 60 + (startTime.minute ?? 0)
        let endMinutes = (endTime.hour ?? 0) * 60 + (endTime.minute ?? 0)
        
        if startMinutes < endMinutes {
            // Same day (e.g., 9 AM to 5 PM)
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Crosses midnight (e.g., 10 PM to 8 AM)
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
}