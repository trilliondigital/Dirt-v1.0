import Foundation
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var totalUnreadCount: Int = 0
    @Published var isInitialized: Bool = false
    
    private let pushNotificationService = PushNotificationService.shared
    private let communityAnnouncementService = CommunityAnnouncementService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        // Request notification permissions
        let granted = await pushNotificationService.requestNotificationPermission()
        
        if granted {
            print("Notification permissions granted")
        } else {
            print("Notification permissions denied")
        }
        
        // Load existing notifications
        updateTotalUnreadCount()
        
        // Setup periodic cleanup
        setupPeriodicCleanup()
        
        // Create some sample notifications for testing
        await createSampleNotifications()
        
        isInitialized = true
    }
    
    private func setupObservers() {
        // Observe push notification unread count
        pushNotificationService.$unreadCount
            .combineLatest(communityAnnouncementService.$unreadAnnouncementCount)
            .map { pushUnread, announcementUnread in
                pushUnread + announcementUnread
            }
            .assign(to: &$totalUnreadCount)
    }
    
    private func updateTotalUnreadCount() {
        totalUnreadCount = pushNotificationService.unreadCount + communityAnnouncementService.unreadAnnouncementCount
    }
    
    // MARK: - Notification Triggers
    
    func handlePostCreated(_ post: Post) async {
        // Check if this is the user's first post
        let userPosts = await getUserPostCount(post.authorId)
        
        if userPosts == 1 {
            await pushNotificationService.notifyFirstPost()
        }
        
        // Check for post milestones
        if [5, 10, 25, 50, 100].contains(userPosts) {
            await pushNotificationService.notifyPostMilestone(userPosts)
        }
    }
    
    func handlePostUpvoted(_ post: Post, by userId: UUID, authorName: String) async {
        // Notify post author about upvote
        await pushNotificationService.notifyUpvote(
            on: post.id,
            from: userId,
            authorName: authorName
        )
        
        // Check if this is the author's first upvote
        let totalUpvotes = await getUserTotalUpvotes(post.authorId)
        
        if totalUpvotes == 1 {
            await pushNotificationService.notifyFirstUpvote()
        }
        
        // Check for popular post milestone
        if post.upvotes >= 10 && post.upvotes % 10 == 0 {
            await pushNotificationService.notifyPopularPost(
                postId: post.id,
                upvotes: post.upvotes
            )
        }
    }
    
    func handleCommentCreated(_ comment: Comment, on post: Post, by authorName: String) async {
        // Notify post author about comment
        await pushNotificationService.notifyComment(
            on: post.id,
            from: comment.authorId,
            authorName: authorName
        )
    }
    
    func handleReplyCreated(_ reply: Comment, to originalComment: Comment, by authorName: String) async {
        // Notify original comment author about reply
        await pushNotificationService.notifyReply(
            to: originalComment.postId,
            from: reply.authorId,
            authorName: authorName
        )
    }
    
    func handleUserMentioned(in postId: UUID, by userId: UUID, authorName: String) async {
        // Notify mentioned user
        await pushNotificationService.notifyMention(
            in: postId,
            from: userId,
            authorName: authorName
        )
    }
    
    func handleReputationChanged(_ newReputation: Int, for userId: UUID) async {
        // Check for reputation milestones
        let milestones = [100, 250, 500, 1000, 2500, 5000, 10000]
        
        for milestone in milestones {
            if newReputation >= milestone {
                let previousReputation = newReputation - 10 // Assuming small increment
                if previousReputation < milestone {
                    await pushNotificationService.notifyReputationMilestone(milestone)
                    
                    // Check for special achievements
                    if milestone >= 1000 {
                        await pushNotificationService.notifyHelpfulContributor()
                    }
                    
                    if milestone >= 5000 {
                        await pushNotificationService.notifyCommunityChampion()
                    }
                }
            }
        }
    }
    
    func handleEngagementMilestone(_ totalEngagement: Int) async {
        // Check for engagement milestones
        let milestones = [50, 100, 250, 500, 1000, 2500, 5000]
        
        for milestone in milestones {
            if totalEngagement >= milestone {
                await pushNotificationService.notifyEngagementMilestone(milestone)
                break
            }
        }
    }
    
    func handleUserAnniversary(_ months: Int) async {
        await pushNotificationService.notifyAnniversaryMilestone(months)
    }
    
    // MARK: - Community Announcements
    
    func announceFeatureUpdate(_ feature: String, description: String, version: String) async {
        await communityAnnouncementService.announceFeatureUpdate(
            featureName: feature,
            description: description,
            version: version
        )
    }
    
    func announceCommunityEvent(_ event: String, date: Date, description: String) async {
        await communityAnnouncementService.announceCommunityEvent(
            eventName: event,
            date: date,
            description: description
        )
    }
    
    func announceMaintenanceWindow(start: Date, end: Date, description: String) async {
        await communityAnnouncementService.announceMaintenanceWindow(
            startTime: start,
            endTime: end,
            description: description
        )
    }
    
    func announceCommunityMilestone(_ milestone: String, description: String) async {
        await communityAnnouncementService.announceCommunityMilestone(
            milestone: milestone,
            description: description
        )
    }
    
    // MARK: - Bulk Operations
    
    func markAllAsRead() async {
        pushNotificationService.markAllAsRead()
        communityAnnouncementService.markAllAnnouncementsAsRead()
    }
    
    func clearAllNotifications() async {
        pushNotificationService.clearAllNotifications()
    }
    
    // MARK: - Cleanup
    
    private func setupPeriodicCleanup() {
        // Setup timer to clean up old notifications daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task { @MainActor in
                await self.performPeriodicCleanup()
            }
        }
    }
    
    private func performPeriodicCleanup() async {
        // Clean up expired announcements
        communityAnnouncementService.cleanupExpiredAnnouncements()
        
        // Clean up old announcements (older than 30 days)
        communityAnnouncementService.cleanupOldAnnouncements(olderThan: 30)
        
        print("Performed periodic notification cleanup")
    }
    
    // MARK: - Sample Data (for testing)
    
    private func createSampleNotifications() async {
        // Only create samples if no notifications exist
        guard pushNotificationService.notifications.isEmpty else { return }
        
        // Sample interaction notifications
        await pushNotificationService.createNotification(
            for: SupabaseManager.shared.currentUser?.id ?? UUID(),
            type: .reply,
            title: "New Reply",
            message: "Someone replied to your post about dating advice",
            data: NotificationData(
                postId: UUID(),
                deepLinkPath: "/post/sample"
            )
        )
        
        await pushNotificationService.createNotification(
            for: SupabaseManager.shared.currentUser?.id ?? UUID(),
            type: .upvote,
            title: "Post Upvoted",
            message: "Your post received an upvote!",
            data: NotificationData(
                postId: UUID(),
                deepLinkPath: "/post/sample"
            )
        )
        
        // Sample milestone notification
        await pushNotificationService.createNotification(
            for: SupabaseManager.shared.currentUser?.id ?? UUID(),
            type: .reputationMilestone,
            title: "Reputation Milestone! 🎉",
            message: "You've reached 100 reputation points!",
            data: NotificationData(
                deepLinkPath: "/profile"
            )
        )
        
        // Sample community announcements
        await communityAnnouncementService.createAnnouncement(
            title: "Welcome to the Community! 🎉",
            message: "Thank you for joining our dating advice community. Here you can share experiences, ask questions, and help others navigate their dating journey.",
            type: .general,
            priority: .medium,
            actionURL: "/welcome"
        )
        
        await communityAnnouncementService.createAnnouncement(
            title: "New Feature: Enhanced Notifications",
            message: "We've improved our notification system with better categorization, smart filtering, and customizable preferences.",
            type: .featureUpdate,
            priority: .medium,
            actionURL: "/features/notifications"
        )
    }
    
    // MARK: - Helper Methods (Mock implementations)
    
    private func getUserPostCount(_ userId: UUID) async -> Int {
        // In a real app, this would query the database
        return Int.random(in: 1...10)
    }
    
    private func getUserTotalUpvotes(_ userId: UUID) async -> Int {
        // In a real app, this would query the database
        return Int.random(in: 1...50)
    }
}