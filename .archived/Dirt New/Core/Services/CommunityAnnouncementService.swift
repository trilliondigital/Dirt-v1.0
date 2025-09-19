import Foundation
import Combine

@MainActor
class CommunityAnnouncementService: ObservableObject {
    static let shared = CommunityAnnouncementService()
    
    @Published var announcements: [CommunityAnnouncement] = []
    @Published var unreadAnnouncementCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let pushNotificationService = PushNotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAnnouncements()
        updateUnreadCount()
    }
    
    // MARK: - Announcement Management
    
    func createAnnouncement(
        title: String,
        message: String,
        type: AnnouncementType,
        priority: AnnouncementPriority = .medium,
        targetAudience: AnnouncementAudience = .all,
        expiresAt: Date? = nil,
        actionURL: String? = nil
    ) async {
        let announcement = CommunityAnnouncement(
            title: title,
            message: message,
            type: type,
            priority: priority,
            targetAudience: targetAudience,
            expiresAt: expiresAt,
            actionURL: actionURL
        )
        
        announcements.insert(announcement, at: 0)
        saveAnnouncements()
        updateUnreadCount()
        
        // Send push notification for high priority announcements
        if priority == .high || priority == .urgent {
            await sendAnnouncementNotification(announcement)
        }
    }
    
    private func sendAnnouncementNotification(_ announcement: CommunityAnnouncement) async {
        let notificationType: NotificationType
        
        switch announcement.type {
        case .general:
            notificationType = .announcement
        case .featureUpdate:
            notificationType = .featureUpdate
        case .event:
            notificationType = .communityEvent
        case .maintenance:
            notificationType = .announcement
        case .moderation:
            notificationType = .moderationUpdate
        case .celebration:
            notificationType = .announcement
        }
        
        await pushNotificationService.createNotification(
            for: SupabaseManager.shared.currentUser?.id ?? UUID(),
            type: notificationType,
            title: announcement.title,
            message: announcement.message,
            data: NotificationData(
                deepLinkPath: announcement.actionURL,
                metadata: [
                    "announcementId": announcement.id.uuidString,
                    "type": announcement.type.rawValue,
                    "priority": announcement.priority.rawValue
                ]
            )
        )
    }
    
    // MARK: - Predefined Announcements
    
    func announceFeatureUpdate(featureName: String, description: String, version: String) async {
        await createAnnouncement(
            title: "New Feature: \(featureName)",
            message: "\(description) Available in version \(version).",
            type: .featureUpdate,
            priority: .medium,
            actionURL: "/features/\(featureName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        )
    }
    
    func announceCommunityEvent(eventName: String, date: Date, description: String) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        
        await createAnnouncement(
            title: "Community Event: \(eventName)",
            message: "\(description) Join us on \(formatter.string(from: date))!",
            type: .event,
            priority: .high,
            expiresAt: date.addingTimeInterval(86400), // Expire 1 day after event
            actionURL: "/events/\(eventName.lowercased().replacingOccurrences(of: " ", with: "-"))"
        )
    }
    
    func announceMaintenanceWindow(startTime: Date, endTime: Date, description: String) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        await createAnnouncement(
            title: "Scheduled Maintenance",
            message: "The app will be unavailable from \(formatter.string(from: startTime)) to \(formatter.string(from: endTime)). \(description)",
            type: .maintenance,
            priority: .high,
            expiresAt: endTime
        )
    }
    
    func announceModerationUpdate(action: String, reason: String, effectiveDate: Date? = nil) async {
        var message = "\(action): \(reason)"
        
        if let effectiveDate = effectiveDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            message += " Effective \(formatter.string(from: effectiveDate))."
        }
        
        await createAnnouncement(
            title: "Community Guidelines Update",
            message: message,
            type: .moderation,
            priority: .high,
            actionURL: "/guidelines"
        )
    }
    
    func announceCommunityMilestone(milestone: String, description: String) async {
        await createAnnouncement(
            title: "Community Milestone! 🎉",
            message: "\(milestone) \(description) Thank you for being part of our amazing community!",
            type: .celebration,
            priority: .medium,
            actionURL: "/community/stats"
        )
    }
    
    func announceUserAchievement(username: String, achievement: String) async {
        await createAnnouncement(
            title: "Community Spotlight! ⭐",
            message: "Congratulations to \(username) for \(achievement)! 🎊",
            type: .celebration,
            priority: .low,
            targetAudience: .active
        )
    }
    
    // MARK: - Seasonal and Special Announcements
    
    func announceSeasonalEvent(season: String, specialFeatures: [String]) async {
        let featuresText = specialFeatures.joined(separator: ", ")
        
        await createAnnouncement(
            title: "\(season) Special Event! 🎊",
            message: "Join our \(season.lowercased()) celebration with special features: \(featuresText)",
            type: .event,
            priority: .medium,
            expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            actionURL: "/events/seasonal"
        )
    }
    
    func announceWeeklyDigest(topPosts: Int, newMembers: Int, totalEngagement: Int) async {
        await createAnnouncement(
            title: "Weekly Community Digest 📊",
            message: "This week: \(topPosts) trending posts, \(newMembers) new members, and \(totalEngagement) total engagements!",
            type: .general,
            priority: .low,
            targetAudience: .active,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            actionURL: "/community/digest"
        )
    }
    
    // MARK: - Announcement Interaction
    
    func markAnnouncementAsRead(_ announcementId: UUID) {
        if let index = announcements.firstIndex(where: { $0.id == announcementId }) {
            announcements[index].isRead = true
            announcements[index].readAt = Date()
            saveAnnouncements()
            updateUnreadCount()
        }
    }
    
    func markAllAnnouncementsAsRead() {
        let now = Date()
        for index in announcements.indices {
            if !announcements[index].isRead {
                announcements[index].isRead = true
                announcements[index].readAt = now
            }
        }
        saveAnnouncements()
        updateUnreadCount()
    }
    
    func dismissAnnouncement(_ announcementId: UUID) {
        if let index = announcements.firstIndex(where: { $0.id == announcementId }) {
            announcements[index].isDismissed = true
            announcements[index].dismissedAt = Date()
            saveAnnouncements()
            updateUnreadCount()
        }
    }
    
    func getActiveAnnouncements() -> [CommunityAnnouncement] {
        let now = Date()
        return announcements.filter { announcement in
            !announcement.isDismissed &&
            (announcement.expiresAt == nil || announcement.expiresAt! > now)
        }
    }
    
    func getUnreadAnnouncements() -> [CommunityAnnouncement] {
        return getActiveAnnouncements().filter { !$0.isRead }
    }
    
    func getAnnouncementsByType(_ type: AnnouncementType) -> [CommunityAnnouncement] {
        return getActiveAnnouncements().filter { $0.type == type }
    }
    
    func getAnnouncementsByPriority(_ priority: AnnouncementPriority) -> [CommunityAnnouncement] {
        return getActiveAnnouncements().filter { $0.priority == priority }
    }
    
    // MARK: - Cleanup
    
    func cleanupExpiredAnnouncements() {
        let now = Date()
        let originalCount = announcements.count
        
        announcements = announcements.filter { announcement in
            announcement.expiresAt == nil || announcement.expiresAt! > now
        }
        
        let removedCount = originalCount - announcements.count
        
        if removedCount > 0 {
            saveAnnouncements()
            updateUnreadCount()
            print("Removed \(removedCount) expired announcements")
        }
    }
    
    func cleanupOldAnnouncements(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let originalCount = announcements.count
        
        announcements = announcements.filter { $0.createdAt >= cutoffDate }
        
        let removedCount = originalCount - announcements.count
        
        if removedCount > 0 {
            saveAnnouncements()
            updateUnreadCount()
            print("Removed \(removedCount) old announcements")
        }
    }
    
    // MARK: - Private Methods
    
    private func updateUnreadCount() {
        unreadAnnouncementCount = getUnreadAnnouncements().count
    }
    
    private func saveAnnouncements() {
        if let encoded = try? JSONEncoder().encode(announcements) {
            userDefaults.set(encoded, forKey: "communityAnnouncements")
        }
    }
    
    private func loadAnnouncements() {
        if let data = userDefaults.data(forKey: "communityAnnouncements"),
           let decoded = try? JSONDecoder().decode([CommunityAnnouncement].self, from: data) {
            announcements = decoded
        }
    }
}

// MARK: - Community Announcement Model

struct CommunityAnnouncement: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: AnnouncementType
    let priority: AnnouncementPriority
    let targetAudience: AnnouncementAudience
    let createdAt: Date
    let expiresAt: Date?
    let actionURL: String?
    
    var isRead: Bool
    var readAt: Date?
    var isDismissed: Bool
    var dismissedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        type: AnnouncementType,
        priority: AnnouncementPriority = .medium,
        targetAudience: AnnouncementAudience = .all,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        actionURL: String? = nil,
        isRead: Bool = false,
        readAt: Date? = nil,
        isDismissed: Bool = false,
        dismissedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.priority = priority
        self.targetAudience = targetAudience
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.actionURL = actionURL
        self.isRead = isRead
        self.readAt = readAt
        self.isDismissed = isDismissed
        self.dismissedAt = dismissedAt
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }
    
    var isActive: Bool {
        return !isDismissed && !isExpired
    }
}

// MARK: - Announcement Enums

enum AnnouncementType: String, CaseIterable, Codable {
    case general = "general"
    case featureUpdate = "feature_update"
    case event = "event"
    case maintenance = "maintenance"
    case moderation = "moderation"
    case celebration = "celebration"
    
    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .featureUpdate:
            return "Feature Update"
        case .event:
            return "Event"
        case .maintenance:
            return "Maintenance"
        case .moderation:
            return "Moderation"
        case .celebration:
            return "Celebration"
        }
    }
    
    var iconName: String {
        switch self {
        case .general:
            return "megaphone"
        case .featureUpdate:
            return "sparkles"
        case .event:
            return "calendar.badge.plus"
        case .maintenance:
            return "wrench.and.screwdriver"
        case .moderation:
            return "shield"
        case .celebration:
            return "party.popper"
        }
    }
    
    var color: String {
        switch self {
        case .general:
            return "blue"
        case .featureUpdate:
            return "purple"
        case .event:
            return "green"
        case .maintenance:
            return "orange"
        case .moderation:
            return "red"
        case .celebration:
            return "pink"
        }
    }
}

enum AnnouncementPriority: String, CaseIterable, Codable {
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
    
    var color: String {
        switch self {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .high:
            return "orange"
        case .urgent:
            return "red"
        }
    }
}

enum AnnouncementAudience: String, CaseIterable, Codable {
    case all = "all"
    case active = "active"
    case new = "new"
    case contributors = "contributors"
    case moderators = "moderators"
    
    var displayName: String {
        switch self {
        case .all:
            return "All Users"
        case .active:
            return "Active Users"
        case .new:
            return "New Users"
        case .contributors:
            return "Contributors"
        case .moderators:
            return "Moderators"
        }
    }
}