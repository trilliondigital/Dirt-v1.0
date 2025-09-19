import SwiftUI
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [DirtNotification] = []
    @Published var filteredNotifications: [DirtNotification] = []
    @Published var isLoading = false
    @Published var error: NotificationError?
    
    private let supabaseManager = SupabaseManager.shared
    private var currentFilter: NotificationFilter = .all
    
    func loadNotifications() async {
        isLoading = true
        error = nil
        
        // Simulate loading notifications
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        notifications = generateMockNotifications()
        applyFilter(currentFilter)
        
        isLoading = false
    }
    
    func refreshNotifications() async {
        await loadNotifications()
    }
    
    func applyFilter(_ filter: NotificationFilter) {
        currentFilter = filter
        
        switch filter {
        case .all:
            filteredNotifications = notifications
        case .unread:
            filteredNotifications = notifications.filter { !$0.isRead }
        case .mentions:
            filteredNotifications = notifications.filter { $0.type == .mention }
        case .upvotes:
            filteredNotifications = notifications.filter { $0.type == .upvote }
        case .replies:
            filteredNotifications = notifications.filter { $0.type == .reply }
        }
    }
    
    func markAsRead(_ notification: DirtNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        notifications[index].isRead = true
        applyFilter(currentFilter)
        
        // TODO: Update in backend
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        applyFilter(currentFilter)
        
        // TODO: Update in backend
    }
    
    func dismissNotification(_ notification: DirtNotification) {
        notifications.removeAll { $0.id == notification.id }
        applyFilter(currentFilter)
        
        // TODO: Update in backend
    }
    
    func deleteNotification(_ notification: DirtNotification) {
        notifications.removeAll { $0.id == notification.id }
        applyFilter(currentFilter)
        
        // TODO: Delete from backend
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        filteredNotifications.removeAll()
        
        // TODO: Clear from backend
    }
    
    private func generateMockNotifications() -> [DirtNotification] {
        let userId = UUID()
        
        return [
            DirtNotification(
                userId: userId,
                type: .upvote,
                title: "Your post was upvoted!",
                message: "Someone liked your post about first date tips",
                createdAt: Date().addingTimeInterval(-300), // 5 minutes ago
                isRead: false
            ),
            
            DirtNotification(
                userId: userId,
                type: .reply,
                title: "New reply to your post",
                message: "Anonymous replied: \"Great advice! This really helped me...\"",
                createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
                isRead: false
            ),
            
            DirtNotification(
                userId: userId,
                type: .mention,
                title: "You were mentioned",
                message: "Anonymous mentioned you in a comment about dating apps",
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                isRead: true
            ),
            
            DirtNotification(
                userId: userId,
                type: .reputationMilestone,
                title: "Reputation Milestone! ⭐",
                message: "You've reached 100 points and are now a Contributor!",
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                isRead: true
            ),
            
            DirtNotification(
                userId: userId,
                type: .announcement,
                title: "New content for you",
                message: "Check out trending posts in Dating Advice",
                createdAt: Date().addingTimeInterval(-14400), // 4 hours ago
                isRead: true
            ),
            
            DirtNotification(
                userId: userId,
                type: .helpfulContributor,
                title: "Achievement Unlocked! 🏆",
                message: "You've earned the \"Helpful Community Member\" achievement",
                createdAt: Date().addingTimeInterval(-86400), // 1 day ago
                isRead: true
            ),
            
            DirtNotification(
                userId: userId,
                type: .announcement,
                title: "📢 Community Update",
                message: "New features have been added to improve your experience",
                createdAt: Date().addingTimeInterval(-172800), // 2 days ago
                isRead: true
            ),
            
            DirtNotification(
                userId: userId,
                type: .upvote,
                title: "Your post is popular!",
                message: "You've received 10 upvotes on your dating app strategy post",
                createdAt: Date().addingTimeInterval(-259200), // 3 days ago
                isRead: true
            )
        ]
    }
}

enum NotificationError: LocalizedError {
    case loadingFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Failed to load notifications"
        case .updateFailed:
            return "Failed to update notification"
        }
    }
}