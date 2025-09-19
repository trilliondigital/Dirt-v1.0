import Foundation
import SwiftUI

// MARK: - Community Announcement Service

@MainActor
class CommunityAnnouncementService: ObservableObject {
    static let shared = CommunityAnnouncementService()
    
    @Published var announcements: [CommunityAnnouncement] = []
    @Published var unreadAnnouncementCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let pushNotificationService = PushNotificationService.shared
    
    init() {
        loadAnnouncements()
    }
    
    // MARK: - Announcement Management
    
    func createAnnouncement(
        title: String,
        message: String,
        type: AnnouncementType,
        priority: AnnouncementPriority = .normal,
        targetAudience: AnnouncementAudience = .all,
        expiresAt: Date? = nil,
        actionButton: AnnouncementAction? = nil
    ) async {
        let announcement = CommunityAnnouncement(
            title: title,
            message: message,
            type: type,
            priority: priority,
            targetAudience: targetAudience,
            expiresAt: expiresAt,
            actionButton: actionButton
        )
        
        announcements.insert(announcement, at: 0)
        updateUnreadCount()
        saveAnnouncements()
        
        // Send push notifications to all users
        await broadcastAnnouncement(announcement)
    }
    
    private func broadcastAnnouncement(_ announcement: CommunityAnnouncement) async {
        // In a real app, this would send to all users via a backend service
        // For now, we'll just send to the current user as an example
        
        let currentUserId = getCurrentUserId() // This would come from your auth service
        
        await pushNotificationService.notifyAnnouncement(
            userId: currentUserId,
            title: announcement.title,
            message: announcement.message,
            deepLinkPath: "/announcements/\(announcement.id.uuidString)"
        )
    }
    
    func markAnnouncementAsRead(_ announcementId: UUID) {
        if let index = announcements.firstIndex(where: { $0.id == announcementId }) {
            announcements[index].isRead = true
            updateUnreadCount()
            saveAnnouncements()
        }
    }
    
    func markAllAnnouncementsAsRead() {
        for index in announcements.indices {
            announcements[index].isRead = true
        }
        updateUnreadCount()
        saveAnnouncements()
    }
    
    func dismissAnnouncement(_ announcementId: UUID) {
        if let index = announcements.firstIndex(where: { $0.id == announcementId }) {
            announcements[index].isDismissed = true
            updateUnreadCount()
            saveAnnouncements()
        }
    }
    
    private func updateUnreadCount() {
        unreadAnnouncementCount = announcements.filter { !$0.isRead && !$0.isDismissed && !$0.isExpired }.count
    }
    
    // MARK: - Predefined Announcements
    
    func announceNewFeature(featureName: String, description: String) async {
        await createAnnouncement(
            title: "New Feature: \(featureName)",
            message: description,
            type: .feature,
            priority: .high,
            actionButton: AnnouncementAction(
                title: "Learn More",
                deepLink: "/features/\(featureName.lowercased().replacingOccurrences(of: " ", with: "-"))"
            )
        )
    }
    
    func announceMaintenanceWindow(startTime: Date, duration: TimeInterval) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let endTime = startTime.addingTimeInterval(duration)
        
        await createAnnouncement(
            title: "Scheduled Maintenance",
            message: "The app will be unavailable from \(formatter.string(from: startTime)) to \(formatter.string(from: endTime)) for maintenance.",
            type: .maintenance,
            priority: .urgent,
            expiresAt: endTime
        )
    }
    
    func announceCommunityMilestone(milestone: String, description: String) async {
        await createAnnouncement(
            title: "Community Milestone: \(milestone)",
            message: description,
            type: .milestone,
            priority: .high,
            actionButton: AnnouncementAction(
                title: "Celebrate",
                deepLink: "/community/milestones"
            )
        )
    }
    
    func announceSecurityUpdate(description: String) async {
        await createAnnouncement(
            title: "Security Update",
            message: description,
            type: .security,
            priority: .urgent,
            actionButton: AnnouncementAction(
                title: "Update Now",
                deepLink: "/settings/security"
            )
        )
    }
    
    func announcePolicyUpdate(policyName: String, description: String) async {
        await createAnnouncement(
            title: "Policy Update: \(policyName)",
            message: description,
            type: .policy,
            priority: .high,
            actionButton: AnnouncementAction(
                title: "Read Policy",
                deepLink: "/policies/\(policyName.lowercased().replacingOccurrences(of: " ", with: "-"))"
            )
        )
    }
    
    func announceEvent(eventName: String, description: String, eventDate: Date) async {
        await createAnnouncement(
            title: "Community Event: \(eventName)",
            message: description,
            type: .event,
            priority: .normal,
            expiresAt: eventDate,
            actionButton: AnnouncementAction(
                title: "Join Event",
                deepLink: "/events/\(eventName.lowercased().replacingOccurrences(of: " ", with: "-"))"
            )
        )
    }
    
    // MARK: - Filtering and Sorting
    
    func getActiveAnnouncements() -> [CommunityAnnouncement] {
        return announcements.filter { !$0.isDismissed && !$0.isExpired }
    }
    
    func getUnreadAnnouncements() -> [CommunityAnnouncement] {
        return announcements.filter { !$0.isRead && !$0.isDismissed && !$0.isExpired }
    }
    
    func getAnnouncementsByType(_ type: AnnouncementType) -> [CommunityAnnouncement] {
        return announcements.filter { $0.type == type && !$0.isDismissed && !$0.isExpired }
    }
    
    func getAnnouncementsByPriority(_ priority: AnnouncementPriority) -> [CommunityAnnouncement] {
        return announcements.filter { $0.priority == priority && !$0.isDismissed && !$0.isExpired }
    }
    
    // MARK: - Persistence
    
    private func saveAnnouncements() {
        if let encoded = try? JSONEncoder().encode(announcements) {
            userDefaults.set(encoded, forKey: "communityAnnouncements")
        }
    }
    
    private func loadAnnouncements() {
        if let data = userDefaults.data(forKey: "communityAnnouncements"),
           let storedAnnouncements = try? JSONDecoder().decode([CommunityAnnouncement].self, from: data) {
            announcements = storedAnnouncements
            updateUnreadCount()
        } else {
            // Load default announcements for new users
            loadDefaultAnnouncements()
        }
    }
    
    private func loadDefaultAnnouncements() {
        let welcomeAnnouncement = CommunityAnnouncement(
            title: "Welcome to Dirt!",
            message: "Thanks for joining our community. Please read our community guidelines to get started.",
            type: .general,
            priority: .high,
            actionButton: AnnouncementAction(
                title: "Read Guidelines",
                deepLink: "/guidelines"
            )
        )
        
        announcements = [welcomeAnnouncement]
        updateUnreadCount()
        saveAnnouncements()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> UUID {
        // This would integrate with your authentication service
        // For now, return a placeholder UUID
        return UUID()
    }
}

// MARK: - Community Announcement Model

struct CommunityAnnouncement: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: AnnouncementType
    let priority: AnnouncementPriority
    let targetAudience: AnnouncementAudience
    let createdAt: Date
    let expiresAt: Date?
    let actionButton: AnnouncementAction?
    var isRead: Bool
    var isDismissed: Bool
    var readAt: Date?
    var dismissedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        type: AnnouncementType,
        priority: AnnouncementPriority = .normal,
        targetAudience: AnnouncementAudience = .all,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        actionButton: AnnouncementAction? = nil,
        isRead: Bool = false,
        isDismissed: Bool = false,
        readAt: Date? = nil,
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
        self.actionButton = actionButton
        self.isRead = isRead
        self.isDismissed = isDismissed
        self.readAt = readAt
        self.dismissedAt = dismissedAt
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var isActive: Bool {
        return !isDismissed && !isExpired
    }
}

// MARK: - Announcement Types

enum AnnouncementType: String, CaseIterable, Codable {
    case general = "general"
    case feature = "feature"
    case maintenance = "maintenance"
    case security = "security"
    case policy = "policy"
    case event = "event"
    case milestone = "milestone"
    case update = "update"
    
    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .feature:
            return "New Feature"
        case .maintenance:
            return "Maintenance"
        case .security:
            return "Security"
        case .policy:
            return "Policy Update"
        case .event:
            return "Event"
        case .milestone:
            return "Milestone"
        case .update:
            return "App Update"
        }
    }
    
    var iconName: String {
        switch self {
        case .general:
            return "info.circle"
        case .feature:
            return "sparkles"
        case .maintenance:
            return "wrench"
        case .security:
            return "shield"
        case .policy:
            return "doc.text"
        case .event:
            return "calendar"
        case .milestone:
            return "flag"
        case .update:
            return "arrow.down.circle"
        }
    }
    
    var color: String {
        switch self {
        case .general:
            return "blue"
        case .feature:
            return "green"
        case .maintenance:
            return "orange"
        case .security:
            return "red"
        case .policy:
            return "purple"
        case .event:
            return "pink"
        case .milestone:
            return "yellow"
        case .update:
            return "blue"
        }
    }
}

// MARK: - Announcement Priority

enum AnnouncementPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        case .urgent:
            return "Urgent"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent:
            return 0
        case .high:
            return 1
        case .normal:
            return 2
        case .low:
            return 3
        }
    }
}

// MARK: - Announcement Audience

enum AnnouncementAudience: String, CaseIterable, Codable {
    case all = "all"
    case newUsers = "new_users"
    case activeUsers = "active_users"
    case moderators = "moderators"
    case highReputation = "high_reputation"
    
    var displayName: String {
        switch self {
        case .all:
            return "All Users"
        case .newUsers:
            return "New Users"
        case .activeUsers:
            return "Active Users"
        case .moderators:
            return "Moderators"
        case .highReputation:
            return "High Reputation Users"
        }
    }
}

// MARK: - Announcement Action

struct AnnouncementAction: Codable, Equatable {
    let title: String
    let deepLink: String
    
    init(title: String, deepLink: String) {
        self.title = title
        self.deepLink = deepLink
    }
}