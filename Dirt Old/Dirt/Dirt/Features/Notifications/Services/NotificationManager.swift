import Foundation
import SwiftUI
import UserNotifications

// MARK: - Notification Manager

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var totalUnreadCount: Int = 0
    @Published var isInitialized: Bool = false
    
    private let pushNotificationService = PushNotificationService.shared
    private let communityAnnouncementService = CommunityAnnouncementService.shared
    private let reputationNotificationService = ReputationNotificationService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
        Task {
            await initialize()
        }
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        // Setup notification categories
        pushNotificationService.setupNotificationCategories()
        
        // Check authorization status
        await pushNotificationService.checkAuthorizationStatus()
        
        // Update total unread count
        updateTotalUnreadCount()
        
        isInitialized = true
    }
    
    private func setupObservers() {
        // Observe push notification unread count
        pushNotificationService.$unreadCount
            .sink { [weak self] _ in
                self?.updateTotalUnreadCount()
            }
            .store(in: &cancellables)
        
        // Observe community announcement unread count
        communityAnnouncementService.$unreadAnnouncementCount
            .sink { [weak self] _ in
                self?.updateTotalUnreadCount()
            }
            .store(in: &cancellables)
        
        // Observe reputation notification count
        reputationNotificationService.$pendingNotifications
            .sink { [weak self] _ in
                self?.updateTotalUnreadCount()
            }
            .store(in: &cancellables)
    }
    
    private func updateTotalUnreadCount() {
        totalUnreadCount = pushNotificationService.unreadCount +
                          communityAnnouncementService.unreadAnnouncementCount +
                          reputationNotificationService.pendingNotifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        return await pushNotificationService.requestAuthorization()
    }
    
    func checkNotificationPermission() async -> UNAuthorizationStatus {
        await pushNotificationService.checkAuthorizationStatus()
        return pushNotificationService.authorizationStatus
    }
    
    // MARK: - Content Interaction Notifications
    
    func handleReply(
        to contentId: UUID,
        contentType: ContentType,
        from authorId: UUID,
        authorUsername: String,
        targetUserId: UUID
    ) async {
        // Don't notify if replying to own content
        guard authorId != targetUserId else { return }
        
        await pushNotificationService.notifyReply(
            userId: targetUserId,
            from: authorUsername,
            contentId: contentId,
            contentType: contentType
        )
        
        // Track interaction for reputation system
        await trackInteraction(
            type: .reply,
            fromUserId: authorId,
            toUserId: targetUserId,
            contentId: contentId
        )
    }
    
    func handleUpvote(
        on contentId: UUID,
        contentType: ContentType,
        from authorId: UUID,
        targetUserId: UUID,
        newUpvoteCount: Int
    ) async {
        // Don't notify if upvoting own content
        guard authorId != targetUserId else { return }
        
        await pushNotificationService.notifyUpvote(
            userId: targetUserId,
            contentId: contentId,
            contentType: contentType,
            upvoteCount: newUpvoteCount
        )
        
        // Track interaction for reputation system
        await trackInteraction(
            type: .upvote,
            fromUserId: authorId,
            toUserId: targetUserId,
            contentId: contentId
        )
    }
    
    func handleMention(
        in contentId: UUID,
        contentType: ContentType,
        from authorId: UUID,
        authorUsername: String,
        mentionedUserId: UUID
    ) async {
        // Don't notify if mentioning self
        guard authorId != mentionedUserId else { return }
        
        await pushNotificationService.notifyMention(
            userId: mentionedUserId,
            from: authorUsername,
            contentId: contentId,
            contentType: contentType
        )
        
        // Track interaction for reputation system
        await trackInteraction(
            type: .mention,
            fromUserId: authorId,
            toUserId: mentionedUserId,
            contentId: contentId
        )
    }
    
    // MARK: - Reputation Notifications
    
    func handleReputationChange(
        userId: UUID,
        username: String,
        oldReputation: Int,
        newReputation: Int,
        action: ReputationAction
    ) async {
        // Check for milestone notifications
        if shouldNotifyMilestone(oldReputation: oldReputation, newReputation: newReputation) {
            if let milestone = getReputationMilestone(newReputation) {
                await pushNotificationService.notifyMilestone(
                    userId: userId,
                    level: milestone.title,
                    reputation: newReputation
                )
            }
        }
        
        // Check for feature unlocks
        let unlockedFeatures = getNewlyUnlockedFeatures(
            oldReputation: oldReputation,
            newReputation: newReputation
        )
        
        for feature in unlockedFeatures {
            await pushNotificationService.notifyFeatureUnlock(
                userId: userId,
                feature: feature.description
            )
        }
        
        // Check for achievements
        let newAchievements = await checkForNewAchievements(
            userId: userId,
            action: action,
            newReputation: newReputation
        )
        
        for achievement in newAchievements {
            await pushNotificationService.notifyAchievement(
                userId: userId,
                achievementType: achievement.type.title
            )
        }
    }
    
    // MARK: - Moderation Notifications
    
    func handleModerationAction(
        userId: UUID,
        contentId: UUID,
        action: ModerationAction,
        reason: String
    ) async {
        let actionText = action.displayName.lowercased()
        
        await pushNotificationService.notifyModeration(
            userId: userId,
            action: actionText,
            reason: reason,
            contentId: contentId
        )
    }
    
    // MARK: - Community Announcements
    
    func broadcastAnnouncement(
        title: String,
        message: String,
        type: AnnouncementType,
        priority: AnnouncementPriority = .normal,
        targetAudience: AnnouncementAudience = .all,
        expiresAt: Date? = nil,
        actionButton: AnnouncementAction? = nil
    ) async {
        await communityAnnouncementService.createAnnouncement(
            title: title,
            message: message,
            type: type,
            priority: priority,
            targetAudience: targetAudience,
            expiresAt: expiresAt,
            actionButton: actionButton
        )
    }
    
    // MARK: - Content Recommendations
    
    func sendContentRecommendations(
        userId: UUID,
        recommendations: [ContentRecommendation]
    ) async {
        for recommendation in recommendations {
            await pushNotificationService.notifyRecommendation(
                userId: userId,
                contentType: recommendation.contentType,
                category: recommendation.category
            )
        }
    }
    
    // MARK: - Batch Operations
    
    func markAllAsRead() async {
        pushNotificationService.markAllAsRead()
        communityAnnouncementService.markAllAnnouncementsAsRead()
        reputationNotificationService.clearAllNotifications()
    }
    
    func clearAllNotifications() async {
        pushNotificationService.clearAllNotifications()
        communityAnnouncementService.markAllAnnouncementsAsRead()
        reputationNotificationService.clearAllNotifications()
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        pushNotificationService.updateNotificationSettings(settings)
    }
    
    func getNotificationSettings() -> NotificationSettings {
        return pushNotificationService.notificationSettings
    }
    
    // MARK: - Helper Methods
    
    private func trackInteraction(
        type: InteractionType,
        fromUserId: UUID,
        toUserId: UUID,
        contentId: UUID
    ) async {
        // This would integrate with your analytics/tracking system
        print("Tracked interaction: \(type) from \(fromUserId) to \(toUserId) on \(contentId)")
    }
    
    private func shouldNotifyMilestone(oldReputation: Int, newReputation: Int) -> Bool {
        let milestones = [50, 100, 250, 500, 1000, 2500, 5000, 10000]
        
        for milestone in milestones {
            if oldReputation < milestone && newReputation >= milestone {
                return true
            }
        }
        
        return false
    }
    
    private func getReputationMilestone(_ reputation: Int) -> ReputationMilestone? {
        let milestones: [(Int, ReputationMilestone)] = [
            (50, .contributor),
            (100, .trusted),
            (250, .veteran),
            (500, .expert),
            (1000, .legend)
        ]
        
        for (threshold, milestone) in milestones.reversed() {
            if reputation >= threshold {
                return milestone
            }
        }
        
        return nil
    }
    
    private func getNewlyUnlockedFeatures(oldReputation: Int, newReputation: Int) -> [UnlockedFeature] {
        return UnlockedFeature.allCases.filter { feature in
            oldReputation < feature.requiredReputation && newReputation >= feature.requiredReputation
        }
    }
    
    private func checkForNewAchievements(
        userId: UUID,
        action: ReputationAction,
        newReputation: Int
    ) async -> [Achievement] {
        // This would integrate with your achievement system
        // For now, return empty array
        return []
    }
}

// MARK: - Supporting Types

enum InteractionType: String, CaseIterable {
    case reply = "reply"
    case upvote = "upvote"
    case mention = "mention"
    case share = "share"
    case report = "report"
}

enum ModerationAction: String, CaseIterable {
    case approved = "approved"
    case rejected = "rejected"
    case flagged = "flagged"
    case removed = "removed"
    case warned = "warned"
    case banned = "banned"
    
    var displayName: String {
        switch self {
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .flagged:
            return "Flagged"
        case .removed:
            return "Removed"
        case .warned:
            return "Warned"
        case .banned:
            return "Banned"
        }
    }
}

struct ContentRecommendation {
    let contentType: ContentType
    let category: String
    let reason: String
    let contentIds: [UUID]
}

// MARK: - Reputation Action (if not already defined)

enum ReputationAction: String, CaseIterable {
    case postCreated = "post_created"
    case reviewCreated = "review_created"
    case commentCreated = "comment_created"
    case upvoteReceived = "upvote_received"
    case downvoteReceived = "downvote_received"
    case contentReported = "content_reported"
    case contentApproved = "content_approved"
    case helpfulVote = "helpful_vote"
    case moderationAction = "moderation_action"
    
    var points: Int {
        switch self {
        case .postCreated:
            return 5
        case .reviewCreated:
            return 10
        case .commentCreated:
            return 2
        case .upvoteReceived:
            return 1
        case .downvoteReceived:
            return -1
        case .contentReported:
            return -5
        case .contentApproved:
            return 3
        case .helpfulVote:
            return 2
        case .moderationAction:
            return 10
        }
    }
}

// MARK: - Achievement Type (if not already defined)

struct Achievement {
    let id: UUID
    let type: AchievementType
    let unlockedAt: Date
    let userId: UUID
}

enum AchievementType: String, CaseIterable {
    case firstPost = "first_post"
    case firstReview = "first_review"
    case firstUpvote = "first_upvote"
    case tenUpvotes = "ten_upvotes"
    case hundredUpvotes = "hundred_upvotes"
    case helpfulMember = "helpful_member"
    case trustedContributor = "trusted_contributor"
    case communityModerator = "community_moderator"
    
    var title: String {
        switch self {
        case .firstPost:
            return "First Post"
        case .firstReview:
            return "First Review"
        case .firstUpvote:
            return "First Upvote"
        case .tenUpvotes:
            return "Popular Contributor"
        case .hundredUpvotes:
            return "Community Favorite"
        case .helpfulMember:
            return "Helpful Member"
        case .trustedContributor:
            return "Trusted Contributor"
        case .communityModerator:
            return "Community Moderator"
        }
    }
    
    var description: String {
        switch self {
        case .firstPost:
            return "Created your first post"
        case .firstReview:
            return "Submitted your first review"
        case .firstUpvote:
            return "Received your first upvote"
        case .tenUpvotes:
            return "Received 10 upvotes"
        case .hundredUpvotes:
            return "Received 100 upvotes"
        case .helpfulMember:
            return "Consistently helpful to the community"
        case .trustedContributor:
            return "Trusted by the community"
        case .communityModerator:
            return "Helping moderate the community"
        }
    }
}

// MARK: - Combine Import

import Combine