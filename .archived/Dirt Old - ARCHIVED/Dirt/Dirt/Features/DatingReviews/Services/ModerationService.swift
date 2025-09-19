import Foundation
import Combine

// MARK: - Moderation Service
class ModerationService: ObservableObject {
    static let shared = ModerationService()
    
    @Published var moderators: [Moderator] = []
    @Published var appeals: [Appeal] = []
    @Published var userPenalties: [UserPenalty] = []
    
    private let queueService = ModerationQueueService.shared
    private let flaggingService = AutomaticContentFlaggingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
    }
    
    // MARK: - Moderator Management
    
    /// Gets all active moderators
    func getActiveModerators() -> [Moderator] {
        return moderators.filter { $0.isActive }
    }
    
    /// Assigns moderator to content
    func assignModerator(contentId: UUID, moderatorId: UUID) async -> Bool {
        guard let moderator = moderators.first(where: { $0.id == moderatorId }),
              moderator.isActive else {
            return false
        }
        
        // In production, this would update the database
        print("Assigned moderator \(moderatorId) to content \(contentId)")
        return true
    }
    
    /// Gets moderator workload
    func getModeratorWorkload(moderatorId: UUID) -> ModeratorWorkload {
        let assignedItems = queueService.queueItems.filter { item in
            // In production, check if moderator is assigned to this item
            return Bool.random() // Mock assignment
        }
        
        return ModeratorWorkload(
            moderatorId: moderatorId,
            assignedItems: assignedItems.count,
            completedToday: Int.random(in: 5...25),
            averageTimePerItem: Int.random(in: 120...300) // seconds
        )
    }
    
    // MARK: - User Penalty System
    
    /// Applies penalty to user
    func applyUserPenalty(
        userId: UUID,
        penalty: UserPenaltyType,
        reason: String,
        moderatorId: UUID,
        contentId: UUID? = nil
    ) async {
        
        let userPenalty = UserPenalty(
            id: UUID(),
            userId: userId,
            penaltyType: penalty,
            reason: reason,
            moderatorId: moderatorId,
            contentId: contentId,
            createdAt: Date(),
            expiresAt: calculateExpirationDate(for: penalty),
            isActive: true
        )
        
        await MainActor.run {
            userPenalties.append(userPenalty)
        }
        
        // Apply the penalty effects
        await applyPenaltyEffects(userPenalty)
        
        // Notify user of penalty
        await notifyUserOfPenalty(userPenalty)
        
        // Log penalty action
        await logPenaltyAction(userPenalty)
    }
    
    /// Gets active penalties for user
    func getActivePenalties(for userId: UUID) -> [UserPenalty] {
        return userPenalties.filter { penalty in
            penalty.userId == userId &&
            penalty.isActive &&
            (penalty.expiresAt == nil || penalty.expiresAt! > Date())
        }
    }
    
    /// Removes penalty (for appeals or admin action)
    func removePenalty(penaltyId: UUID, reason: String) async {
        guard let index = userPenalties.firstIndex(where: { $0.id == penaltyId }) else {
            return
        }
        
        await MainActor.run {
            userPenalties[index].isActive = false
        }
        
        print("Penalty \(penaltyId) removed: \(reason)")
    }
    
    // MARK: - Appeal System
    
    /// Submits an appeal for moderation decision
    func submitAppeal(
        userId: UUID,
        contentId: UUID,
        moderationActionId: UUID,
        reason: String,
        evidence: String? = nil
    ) async -> Appeal {
        
        let appeal = Appeal(
            id: UUID(),
            userId: userId,
            contentId: contentId,
            moderationActionId: moderationActionId,
            reason: reason,
            evidence: evidence,
            status: .pending,
            submittedAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            decision: nil,
            decisionReason: nil
        )
        
        await MainActor.run {
            appeals.append(appeal)
        }
        
        // Notify moderators of new appeal
        await notifyModeratorsOfAppeal(appeal)
        
        return appeal
    }
    
    /// Reviews an appeal
    func reviewAppeal(
        appealId: UUID,
        moderatorId: UUID,
        decision: AppealDecision,
        reason: String
    ) async -> Bool {
        
        guard let index = appeals.firstIndex(where: { $0.id == appealId }) else {
            return false
        }
        
        let appeal = appeals[index]
        
        await MainActor.run {
            appeals[index] = Appeal(
                id: appeal.id,
                userId: appeal.userId,
                contentId: appeal.contentId,
                moderationActionId: appeal.moderationActionId,
                reason: appeal.reason,
                evidence: appeal.evidence,
                status: decision == .approved ? .approved : .rejected,
                submittedAt: appeal.submittedAt,
                reviewedAt: Date(),
                reviewedBy: moderatorId,
                decision: decision,
                decisionReason: reason
            )
        }
        
        // Apply appeal decision
        await applyAppealDecision(appeals[index])
        
        // Notify user of appeal result
        await notifyUserOfAppealResult(appeals[index])
        
        return true
    }
    
    /// Gets pending appeals
    func getPendingAppeals() -> [Appeal] {
        return appeals.filter { $0.status == .pending }
    }
    
    // MARK: - Content Approval Workflow
    
    /// Processes content through approval workflow
    func processContentApproval(
        contentId: UUID,
        moderatorId: UUID,
        action: ModerationActionType,
        reason: String,
        notes: String? = nil
    ) async -> ContentApprovalResult {
        
        // Check if moderator has permission for this action
        guard await hasPermissionForAction(moderatorId: moderatorId, action: action) else {
            return ContentApprovalResult(
                success: false,
                error: "Moderator does not have permission for this action"
            )
        }
        
        // Apply the moderation action
        let success = await applyModerationAction(
            contentId: contentId,
            moderatorId: moderatorId,
            action: action,
            reason: reason,
            notes: notes
        )
        
        if success {
            // Update queue
            if let queueItem = queueService.queueItems.first(where: { $0.contentId == contentId }) {
                await queueService.updateQueueItem(
                    itemId: queueItem.id,
                    action: action,
                    moderatorId: moderatorId,
                    reason: reason,
                    notes: notes
                )
            }
            
            // Apply user penalties if needed
            if [.reject, .ban, .delete].contains(action) {
                await applyAutomaticPenalties(
                    contentId: contentId,
                    action: action,
                    moderatorId: moderatorId
                )
            }
            
            return ContentApprovalResult(success: true)
        } else {
            return ContentApprovalResult(
                success: false,
                error: "Failed to apply moderation action"
            )
        }
    }
    
    // MARK: - Moderation Analytics
    
    /// Gets moderation performance metrics
    func getModerationMetrics(for moderatorId: UUID, timeRange: TimeRange) async -> ModerationMetrics {
        // In production, this would query the database
        return ModerationMetrics(
            moderatorId: moderatorId,
            timeRange: timeRange,
            totalReviewed: Int.random(in: 50...200),
            approved: Int.random(in: 30...150),
            rejected: Int.random(in: 10...50),
            averageTimePerReview: Int.random(in: 120...600),
            accuracyScore: Double.random(in: 0.8...0.98),
            appealsOverturned: Int.random(in: 0...5)
        )
    }
    
    /// Gets system-wide moderation statistics
    func getSystemModerationStats(timeRange: TimeRange) async -> SystemModerationStats {
        return SystemModerationStats(
            timeRange: timeRange,
            totalContentProcessed: Int.random(in: 1000...5000),
            autoApproved: Int.random(in: 800...4000),
            autoRejected: Int.random(in: 100...500),
            humanReviewed: Int.random(in: 100...500),
            averageQueueTime: Int.random(in: 300...1800),
            aiAccuracy: Double.random(in: 0.85...0.95),
            falsePositiveRate: Double.random(in: 0.05...0.15)
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateExpirationDate(for penalty: UserPenaltyType) -> Date? {
        switch penalty {
        case .warning:
            return nil // Warnings don't expire
        case .temporaryBan(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: Date())
        case .permanentBan:
            return nil // Permanent bans don't expire
        case .restrictedPosting(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: Date())
        case .shadowBan(let days):
            return Calendar.current.date(byAdding: .day, value: days, to: Date())
        }
    }
    
    private func applyPenaltyEffects(_ penalty: UserPenalty) async {
        // In production, this would update user permissions in the database
        print("Applied penalty \(penalty.penaltyType) to user \(penalty.userId)")
    }
    
    private func notifyUserOfPenalty(_ penalty: UserPenalty) async {
        // In production, this would send a notification to the user
        print("Notified user \(penalty.userId) of penalty: \(penalty.reason)")
    }
    
    private func logPenaltyAction(_ penalty: UserPenalty) async {
        // In production, this would log the action for audit purposes
        print("Logged penalty action: \(penalty.id)")
    }
    
    private func notifyModeratorsOfAppeal(_ appeal: Appeal) async {
        // In production, this would notify available moderators
        print("Notified moderators of new appeal: \(appeal.id)")
    }
    
    private func applyAppealDecision(_ appeal: Appeal) async {
        guard let decision = appeal.decision else { return }
        
        switch decision {
        case .approved:
            // Reverse the original moderation action
            print("Reversing moderation action for appeal \(appeal.id)")
            
            // Remove any penalties applied
            let penalties = getActivePenalties(for: appeal.userId)
            for penalty in penalties {
                if penalty.contentId == appeal.contentId {
                    await removePenalty(penaltyId: penalty.id, reason: "Appeal approved")
                }
            }
            
        case .rejected:
            // Uphold the original decision
            print("Upholding original moderation decision for appeal \(appeal.id)")
        }
    }
    
    private func notifyUserOfAppealResult(_ appeal: Appeal) async {
        // In production, this would send a notification to the user
        print("Notified user \(appeal.userId) of appeal result: \(appeal.decision?.rawValue ?? "unknown")")
    }
    
    private func hasPermissionForAction(moderatorId: UUID, action: ModerationActionType) async -> Bool {
        guard let moderator = moderators.first(where: { $0.id == moderatorId }) else {
            return false
        }
        
        // Check if moderator has permission for this action based on their role
        switch action {
        case .ban, .delete:
            return moderator.role == .admin || moderator.role == .senior
        case .approve, .reject, .flag, .edit, .warn:
            return moderator.isActive
        }
    }
    
    private func applyModerationAction(
        contentId: UUID,
        moderatorId: UUID,
        action: ModerationActionType,
        reason: String,
        notes: String?
    ) async -> Bool {
        
        // In production, this would update the content status in the database
        print("Applied moderation action \(action.rawValue) to content \(contentId)")
        
        // Log the action
        let moderationAction = ModerationAction(
            id: UUID(),
            contentId: contentId,
            moderatorId: moderatorId,
            action: action,
            reason: reason,
            notes: notes,
            createdAt: Date()
        )
        
        // In production, save to database
        print("Logged moderation action: \(moderationAction.id)")
        
        return true
    }
    
    private func applyAutomaticPenalties(
        contentId: UUID,
        action: ModerationActionType,
        moderatorId: UUID
    ) async {
        
        // Get the content to determine penalty severity
        guard let queueItem = queueService.queueItems.first(where: { $0.contentId == contentId }) else {
            return
        }
        
        let severity = queueItem.moderationResult.severity
        let flags = queueItem.moderationResult.flags
        
        // Determine appropriate penalty
        let penalty: UserPenaltyType
        
        if flags.contains(.hateSpeech) || flags.contains(.harassment) {
            penalty = .temporaryBan(days: 7)
        } else if severity == .high {
            penalty = .temporaryBan(days: 3)
        } else if severity == .medium {
            penalty = .restrictedPosting(days: 1)
        } else {
            penalty = .warning
        }
        
        await applyUserPenalty(
            userId: queueItem.authorId,
            penalty: penalty,
            reason: "Automatic penalty for \(action.rawValue) action",
            moderatorId: moderatorId,
            contentId: contentId
        )
    }
    
    private func loadMockData() {
        // Load mock moderators
        moderators = [
            Moderator(
                id: UUID(),
                username: "mod_alice",
                role: .admin,
                isActive: true,
                joinedAt: Date().addingTimeInterval(-86400 * 30),
                totalReviews: 1250,
                accuracyScore: 0.94
            ),
            Moderator(
                id: UUID(),
                username: "mod_bob",
                role: .senior,
                isActive: true,
                joinedAt: Date().addingTimeInterval(-86400 * 60),
                totalReviews: 2100,
                accuracyScore: 0.91
            ),
            Moderator(
                id: UUID(),
                username: "mod_charlie",
                role: .standard,
                isActive: true,
                joinedAt: Date().addingTimeInterval(-86400 * 15),
                totalReviews: 450,
                accuracyScore: 0.88
            )
        ]
    }
}

// MARK: - Supporting Types

struct Moderator {
    let id: UUID
    let username: String
    let role: ModeratorRole
    let isActive: Bool
    let joinedAt: Date
    let totalReviews: Int
    let accuracyScore: Double
}

enum ModeratorRole: String, CaseIterable {
    case standard = "standard"
    case senior = "senior"
    case admin = "admin"
}

struct ModeratorWorkload {
    let moderatorId: UUID
    let assignedItems: Int
    let completedToday: Int
    let averageTimePerItem: Int
}

struct UserPenalty {
    let id: UUID
    let userId: UUID
    let penaltyType: UserPenaltyType
    let reason: String
    let moderatorId: UUID
    let contentId: UUID?
    let createdAt: Date
    let expiresAt: Date?
    let isActive: Bool
}

enum UserPenaltyType {
    case warning
    case temporaryBan(days: Int)
    case permanentBan
    case restrictedPosting(days: Int)
    case shadowBan(days: Int)
}

struct Appeal {
    let id: UUID
    let userId: UUID
    let contentId: UUID
    let moderationActionId: UUID
    let reason: String
    let evidence: String?
    let status: AppealStatus
    let submittedAt: Date
    let reviewedAt: Date?
    let reviewedBy: UUID?
    let decision: AppealDecision?
    let decisionReason: String?
}

enum AppealStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
}

enum AppealDecision: String, CaseIterable {
    case approved = "approved"
    case rejected = "rejected"
}

struct ContentApprovalResult {
    let success: Bool
    let error: String?
    
    init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

struct ModerationMetrics {
    let moderatorId: UUID
    let timeRange: TimeRange
    let totalReviewed: Int
    let approved: Int
    let rejected: Int
    let averageTimePerReview: Int
    let accuracyScore: Double
    let appealsOverturned: Int
}

struct SystemModerationStats {
    let timeRange: TimeRange
    let totalContentProcessed: Int
    let autoApproved: Int
    let autoRejected: Int
    let humanReviewed: Int
    let averageQueueTime: Int
    let aiAccuracy: Double
    let falsePositiveRate: Double
}