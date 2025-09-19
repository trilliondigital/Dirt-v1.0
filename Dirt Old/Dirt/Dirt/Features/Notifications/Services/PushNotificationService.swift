import Foundation
import UserNotifications
import SwiftUI

// MARK: - Push Notification Service

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var notifications: [DirtNotification] = []
    @Published var unreadCount: Int = 0
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationSettings = NotificationSettings()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let maxNotifications = 100 // Keep only recent notifications
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        loadNotificationSettings()
        loadStoredNotifications()
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization Management
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            await checkAuthorizationStatus()
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        
        // Update notification settings based on system settings
        notificationSettings.pushNotificationsEnabled = settings.authorizationStatus == .authorized
    }
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Notification Creation and Scheduling
    
    func scheduleNotification(_ notification: DirtNotification) async {
        // Check if notifications are enabled for this type
        guard notificationSettings.isNotificationEnabled(for: notification.type) else {
            print("Notifications disabled for type: \(notification.type)")
            return
        }
        
        // Check quiet hours
        if notificationSettings.isInQuietHours() && notification.type.priority != .urgent {
            print("In quiet hours, skipping non-urgent notification")
            return
        }
        
        // Add to local storage
        await addNotification(notification)
        
        // Create system notification
        await createSystemNotification(notification)
    }
    
    private func createSystemNotification(_ notification: DirtNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = notification.type.priority.soundName
        content.badge = NSNumber(value: unreadCount + 1)
        
        // Add custom data
        var userInfo: [String: Any] = [
            "notificationId": notification.id.uuidString,
            "type": notification.type.rawValue,
            "userId": notification.userId.uuidString
        ]
        
        if let data = notification.data {
            if let contentId = data.contentId {
                userInfo["contentId"] = contentId.uuidString
            }
            if let contentType = data.contentType {
                userInfo["contentType"] = contentType.rawValue
            }
            if let deepLinkPath = data.deepLinkPath {
                userInfo["deepLinkPath"] = deepLinkPath
            }
        }
        
        content.userInfo = userInfo
        
        // Add category for interactive notifications
        content.categoryIdentifier = notification.type.rawValue
        
        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification: \(notification.title)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    private func addNotification(_ notification: DirtNotification) async {
        notifications.insert(notification, at: 0)
        
        // Keep only recent notifications
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
        
        updateUnreadCount()
        saveNotifications()
    }
    
    func markAsRead(_ notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveNotifications()
            
            // Remove from notification center
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId.uuidString])
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveNotifications()
        
        // Clear all delivered notifications
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func deleteNotification(_ notificationId: UUID) {
        notifications.removeAll { $0.id == notificationId }
        updateUnreadCount()
        saveNotifications()
        
        // Remove from notification center
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId.uuidString])
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
        
        // Clear all delivered notifications
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        
        // Update app badge
        Task {
            await UIApplication.shared.setApplicationIconBadgeNumber(unreadCount)
        }
    }
    
    // MARK: - Specific Notification Types
    
    func notifyReply(
        userId: UUID,
        from authorUsername: String,
        contentId: UUID,
        contentType: ContentType
    ) async {
        let template = NotificationTemplate.reply(from: authorUsername, contentType: contentType)
        
        let notification = DirtNotification(
            userId: userId,
            type: .reply,
            title: template.title,
            message: template.message,
            data: NotificationData(
                contentId: contentId,
                contentType: contentType,
                authorUsername: authorUsername,
                deepLinkPath: "/content/\(contentId.uuidString)"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyUpvote(
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        upvoteCount: Int
    ) async {
        // Check upvote threshold
        guard upvoteCount >= notificationSettings.upvoteThreshold else { return }
        
        let template = NotificationTemplate.upvote(count: upvoteCount, contentType: contentType)
        
        let notification = DirtNotification(
            userId: userId,
            type: .upvote,
            title: template.title,
            message: template.message,
            data: NotificationData(
                contentId: contentId,
                contentType: contentType,
                deepLinkPath: "/content/\(contentId.uuidString)"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyMention(
        userId: UUID,
        from authorUsername: String,
        contentId: UUID,
        contentType: ContentType
    ) async {
        let template = NotificationTemplate.mention(from: authorUsername, contentType: contentType)
        
        let notification = DirtNotification(
            userId: userId,
            type: .mention,
            title: template.title,
            message: template.message,
            data: NotificationData(
                contentId: contentId,
                contentType: contentType,
                authorUsername: authorUsername,
                deepLinkPath: "/content/\(contentId.uuidString)"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyMilestone(
        userId: UUID,
        level: String,
        reputation: Int
    ) async {
        let template = NotificationTemplate.milestone(level: level, reputation: reputation)
        
        let notification = DirtNotification(
            userId: userId,
            type: .milestone,
            title: template.title,
            message: template.message,
            data: NotificationData(
                reputationChange: reputation,
                milestoneLevel: level,
                deepLinkPath: "/profile"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyAchievement(
        userId: UUID,
        achievementType: String
    ) async {
        let template = NotificationTemplate.achievement(type: achievementType)
        
        let notification = DirtNotification(
            userId: userId,
            type: .achievement,
            title: template.title,
            message: template.message,
            data: NotificationData(
                achievementType: achievementType,
                deepLinkPath: "/profile/achievements"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyAnnouncement(
        userId: UUID,
        title: String,
        message: String,
        deepLinkPath: String? = nil
    ) async {
        let template = NotificationTemplate.announcement(title: title, message: message)
        
        let notification = DirtNotification(
            userId: userId,
            type: .announcement,
            title: template.title,
            message: template.message,
            data: NotificationData(
                deepLinkPath: deepLinkPath ?? "/announcements"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyRecommendation(
        userId: UUID,
        contentType: ContentType,
        category: String
    ) async {
        let template = NotificationTemplate.recommendation(contentType: contentType, category: category)
        
        let notification = DirtNotification(
            userId: userId,
            type: .recommendation,
            title: template.title,
            message: template.message,
            data: NotificationData(
                contentType: contentType,
                deepLinkPath: "/feed?category=\(category)"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyModeration(
        userId: UUID,
        action: String,
        reason: String,
        contentId: UUID
    ) async {
        let template = NotificationTemplate.moderation(action: action, reason: reason)
        
        let notification = DirtNotification(
            userId: userId,
            type: .moderation,
            title: template.title,
            message: template.message,
            data: NotificationData(
                contentId: contentId,
                deepLinkPath: "/content/\(contentId.uuidString)"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    func notifyFeatureUnlock(
        userId: UUID,
        feature: String
    ) async {
        let template = NotificationTemplate.featureUnlock(feature: feature)
        
        let notification = DirtNotification(
            userId: userId,
            type: .featureUnlock,
            title: template.title,
            message: template.message,
            data: NotificationData(
                deepLinkPath: "/profile/features"
            )
        )
        
        await scheduleNotification(notification)
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        saveNotificationSettings()
    }
    
    private func saveNotificationSettings() {
        if let encoded = try? JSONEncoder().encode(notificationSettings) {
            userDefaults.set(encoded, forKey: "notificationSettings")
        }
    }
    
    private func loadNotificationSettings() {
        if let data = userDefaults.data(forKey: "notificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = settings
        }
    }
    
    // MARK: - Persistence
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: "storedNotifications")
        }
    }
    
    private func loadStoredNotifications() {
        if let data = userDefaults.data(forKey: "storedNotifications"),
           let storedNotifications = try? JSONDecoder().decode([DirtNotification].self, from: data) {
            notifications = storedNotifications
            updateUnreadCount()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let notificationIdString = userInfo["notificationId"] as? String,
           let notificationId = UUID(uuidString: notificationIdString) {
            
            // Mark as read
            markAsRead(notificationId)
            
            // Handle deep linking
            if let deepLinkPath = userInfo["deepLinkPath"] as? String {
                handleDeepLink(deepLinkPath)
            }
        }
        
        completionHandler()
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        // For now, we'll just print the path
        print("Deep link: \(path)")
        
        // Example implementation:
        // NotificationCenter.default.post(
        //     name: .deepLinkReceived,
        //     object: nil,
        //     userInfo: ["path": path]
        // )
    }
}

// MARK: - Notification Categories

extension PushNotificationService {
    
    func setupNotificationCategories() {
        let replyAction = UNNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.foreground]
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )
        
        let replyCategory = UNNotificationCategory(
            identifier: "reply",
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: []
        )
        
        let upvoteCategory = UNNotificationCategory(
            identifier: "upvote",
            actions: [markReadAction],
            intentIdentifiers: [],
            options: []
        )
        
        let mentionCategory = UNNotificationCategory(
            identifier: "mention",
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            replyCategory,
            upvoteCategory,
            mentionCategory
        ])
    }
}