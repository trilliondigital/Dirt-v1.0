import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif
import Combine

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var notifications: [DirtNotification] = []
    @Published var unreadCount: Int = 0
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var preferences: NotificationPreferences = NotificationPreferences()
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupNotificationCenter()
        loadPreferences()
        loadNotifications()
        updateUnreadCount()
    }
    
    // MARK: - Setup
    
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        
        // Register notification categories
        registerNotificationCategories()
        
        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    private func registerNotificationCategories() {
        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: getActionsForCategory(category),
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        }
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    private func getActionsForCategory(_ category: NotificationCategory) -> [UNNotificationAction] {
        switch category {
        case NotificationCategory.interaction:
            return [
                UNNotificationAction(
                    identifier: "REPLY_ACTION",
                    title: "Reply",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "VIEW_ACTION",
                    title: "View",
                    options: [.foreground]
                )
            ]
        case NotificationCategory.milestone, NotificationCategory.achievement:
            return [
                UNNotificationAction(
                    identifier: "VIEW_ACTION",
                    title: "View",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "SHARE_ACTION",
                    title: "Share",
                    options: []
                )
            ]
        case NotificationCategory.community:
            return [
                UNNotificationAction(
                    identifier: "VIEW_ACTION",
                    title: "View",
                    options: [.foreground]
                )
            ]
        }
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() async -> Bool {
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
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Notification Creation
    
    func createNotification(
        for userId: UUID,
        type: NotificationType,
        title: String,
        message: String,
        data: NotificationData? = nil
    ) async {
        let notification = DirtNotification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            data: data
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    private func addNotification(_ notification: DirtNotification) async {
        notifications.insert(notification, at: 0)
        
        // Keep only recent notifications (last 100)
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        saveNotifications()
        updateUnreadCount()
    }
    
    private func scheduleLocalNotification(_ notification: DirtNotification) async {
        // Check if notifications are enabled for this type
        guard preferences.isTypeEnabled(notification.type) else { return }
        
        // Check quiet hours
        if preferences.isInQuietHours() && notification.type.priority != NotificationPriority.urgent {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.categoryIdentifier = notification.type.category.rawValue
        content.userInfo = [
            "notificationId": notification.id.uuidString,
            "type": notification.type.rawValue
        ]
        
        // Add data if available
        if let data = notification.data,
           let dataJSON = try? JSONEncoder().encode(data),
           let dataString = String(data: dataJSON, encoding: .utf8) {
            content.userInfo["data"] = dataString
        }
        
        // Configure sound
        if preferences.soundEnabled,
           let soundName = notification.type.priority.soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }
        
        // Configure badge
        if preferences.badgeEnabled {
            content.badge = NSNumber(value: unreadCount + 1)
        }
        
        // Configure interruption level (iOS 15+)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = notification.type.priority.interruptionLevel
        }
        
        // Schedule immediately
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
            
            // Mark as delivered
            var updatedNotification = notification
            updatedNotification.isDelivered = true
            
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = updatedNotification
                saveNotifications()
            }
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Interaction Notifications
    
    func notifyReply(to postId: UUID, from authorId: UUID, authorName: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.reply,
            title: "New Reply",
            message: "\(authorName) replied to your post",
            data: NotificationData(
                postId: postId,
                authorId: authorId,
                deepLinkPath: "/post/\(postId.uuidString)"
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyUpvote(on postId: UUID, from authorId: UUID, authorName: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.upvote,
            title: "Post Upvoted",
            message: "\(authorName) upvoted your post",
            data: NotificationData(
                postId: postId,
                authorId: authorId,
                deepLinkPath: "/post/\(postId.uuidString)"
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyMention(in postId: UUID, from authorId: UUID, authorName: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.mention,
            title: "You were mentioned",
            message: "\(authorName) mentioned you in a post",
            data: NotificationData(
                postId: postId,
                authorId: authorId,
                deepLinkPath: "/post/\(postId.uuidString)"
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyComment(on postId: UUID, from authorId: UUID, authorName: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.comment,
            title: "New Comment",
            message: "\(authorName) commented on your post",
            data: NotificationData(
                postId: postId,
                authorId: authorId,
                deepLinkPath: "/post/\(postId.uuidString)"
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    // MARK: - Milestone Notifications
    
    func notifyReputationMilestone(_ milestone: Int) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.reputationMilestone,
            title: "Reputation Milestone! 🎉",
            message: "You've reached \(milestone) reputation points!",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["milestone": "\(milestone)"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyPostMilestone(_ count: Int) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.postMilestone,
            title: "Post Milestone! 📝",
            message: "You've created \(count) posts!",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["postCount": "\(count)"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyEngagementMilestone(_ totalEngagement: Int) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.engagementMilestone,
            title: "Engagement Milestone! ❤️",
            message: "Your posts have received \(totalEngagement) total engagements!",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["engagement": "\(totalEngagement)"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyAnniversaryMilestone(_ months: Int) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.anniversaryMilestone,
            title: "Anniversary! 🎂",
            message: "You've been part of the community for \(months) months!",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["months": "\(months)"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    // MARK: - Achievement Notifications
    
    func notifyFirstPost() async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.firstPost,
            title: "First Post! 🎉",
            message: "Welcome to the community! You've made your first post.",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["achievement": "first_post"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyFirstUpvote() async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.firstUpvote,
            title: "First Upvote! 👍",
            message: "Someone liked your content! You received your first upvote.",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["achievement": "first_upvote"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyPopularPost(postId: UUID, upvotes: Int) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.popularPost,
            title: "Popular Post! 🔥",
            message: "Your post is trending with \(upvotes) upvotes!",
            data: NotificationData(
                postId: postId,
                deepLinkPath: "/post/\(postId.uuidString)",
                metadata: ["upvotes": "\(upvotes)"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyHelpfulContributor() async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.helpfulContributor,
            title: "Helpful Contributor! 🌟",
            message: "Your advice has been helping others in the community!",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["achievement": "helpful_contributor"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyCommunityChampion() async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.communityChampion,
            title: "Community Champion! 👑",
            message: "You've become a pillar of the community! Thank you for your contributions.",
            data: NotificationData(
                deepLinkPath: "/profile",
                metadata: ["achievement": "community_champion"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    // MARK: - Community Notifications
    
    func sendCommunityAnnouncement(title: String, message: String, deepLink: String? = nil) async {
        // This would typically be called from an admin interface
        // For now, we'll create a notification for the current user
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.announcement,
            title: title,
            message: message,
            data: NotificationData(
                deepLinkPath: deepLink,
                metadata: ["source": "admin"]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyFeatureUpdate(feature: String, description: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.featureUpdate,
            title: "New Feature: \(feature)",
            message: description,
            data: NotificationData(
                deepLinkPath: "/features",
                metadata: ["feature": feature]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyCommunityEvent(event: String, date: Date) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.communityEvent,
            title: "Community Event: \(event)",
            message: "Join us on \(formatter.string(from: date))",
            data: NotificationData(
                deepLinkPath: "/events",
                metadata: ["event": event, "date": ISO8601DateFormatter().string(from: date)]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    func notifyModerationUpdate(action: String, reason: String) async {
        guard let currentUser = SupabaseManager.shared.currentUser else { return }
        
        let notification = DirtNotification(
            userId: currentUser.id,
            type: NotificationType.moderationUpdate,
            title: "Moderation Update",
            message: "\(action): \(reason)",
            data: NotificationData(
                deepLinkPath: "/moderation",
                metadata: ["action": action, "reason": reason]
            )
        )
        
        await addNotification(notification)
        await scheduleLocalNotification(notification)
    }
    
    // MARK: - Notification Management
    
    func markAsRead(_ notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            saveNotifications()
            updateUnreadCount()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveNotifications()
        updateUnreadCount()
    }
    
    func deleteNotification(_ notificationId: UUID) {
        notifications.removeAll { $0.id == notificationId }
        saveNotifications()
        updateUnreadCount()
        
        // Remove from notification center
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId.uuidString])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId.uuidString])
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        saveNotifications()
        updateUnreadCount()
        
        // Clear all from notification center
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        
        // Update app badge
        if preferences.badgeEnabled {
            UIApplication.shared.applicationIconBadgeNumber = unreadCount
        }
    }
    
    // MARK: - Preferences Management
    
    func updatePreferences(_ newPreferences: NotificationPreferences) {
        preferences = newPreferences
        savePreferences()
        
        // Update app badge based on new preferences
        if !preferences.badgeEnabled {
            UIApplication.shared.applicationIconBadgeNumber = 0
        } else {
            UIApplication.shared.applicationIconBadgeNumber = unreadCount
        }
    }
    
    func toggleNotificationType(_ type: NotificationType, enabled: Bool) {
        preferences.typePreferences[type] = enabled
        savePreferences()
    }
    
    func toggleNotificationCategory(_ category: NotificationCategory, enabled: Bool) {
        preferences.categoryPreferences[category] = enabled
        savePreferences()
    }
    
    // MARK: - Persistence
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: "pushNotifications")
        }
    }
    
    private func loadNotifications() {
        if let data = userDefaults.data(forKey: "pushNotifications"),
           let decoded = try? JSONDecoder().decode([DirtNotification].self, from: data) {
            notifications = decoded
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: "notificationPreferences")
        }
    }
    
    private func loadPreferences() {
        if let data = userDefaults.data(forKey: "notificationPreferences"),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            preferences = decoded
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

@MainActor
extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        if preferences.previewEnabled {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.badge])
        }
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
            
            // Handle action
            switch response.actionIdentifier {
            case "REPLY_ACTION":
                handleReplyAction(notificationId: notificationId, userInfo: userInfo)
            case "VIEW_ACTION":
                handleViewAction(notificationId: notificationId, userInfo: userInfo)
            case "SHARE_ACTION":
                handleShareAction(notificationId: notificationId, userInfo: userInfo)
            case UNNotificationDefaultActionIdentifier:
                handleDefaultAction(notificationId: notificationId, userInfo: userInfo)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func handleReplyAction(notificationId: UUID, userInfo: [AnyHashable: Any]) {
        // Navigate to reply interface
        if let dataString = userInfo["data"] as? String,
           let data = dataString.data(using: .utf8),
           let notificationData = try? JSONDecoder().decode(NotificationData.self, from: data),
           let deepLink = notificationData.deepLinkPath {
            handleDeepLink(deepLink + "?action=reply")
        }
    }
    
    private func handleViewAction(notificationId: UUID, userInfo: [AnyHashable: Any]) {
        // Navigate to content
        if let dataString = userInfo["data"] as? String,
           let data = dataString.data(using: .utf8),
           let notificationData = try? JSONDecoder().decode(NotificationData.self, from: data),
           let deepLink = notificationData.deepLinkPath {
            handleDeepLink(deepLink)
        }
    }
    
    private func handleShareAction(notificationId: UUID, userInfo: [AnyHashable: Any]) {
        // Handle share action
        print("Share action for notification: \(notificationId)")
    }
    
    private func handleDefaultAction(notificationId: UUID, userInfo: [AnyHashable: Any]) {
        // Handle default tap
        if let dataString = userInfo["data"] as? String,
           let data = dataString.data(using: .utf8),
           let notificationData = try? JSONDecoder().decode(NotificationData.self, from: data),
           let deepLink = notificationData.deepLinkPath {
            handleDeepLink(deepLink)
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
        // In a real implementation, you would use your navigation coordinator
        // to navigate to the appropriate screen
    }
}
