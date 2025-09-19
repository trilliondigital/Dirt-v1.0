import Foundation
import UIKit
import Combine

// MARK: - Automatic Content Flagging Service
class AutomaticContentFlaggingService: ObservableObject {
    static let shared = AutomaticContentFlaggingService()
    
    private let aiModerationService = AIContentModerationService.shared
    private let queueService = ModerationQueueService.shared
    private let userService = UserService.shared // Assuming this exists
    
    @Published var flaggingStatistics = FlaggingStatistics()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupFlaggingRules()
    }
    
    // MARK: - Public API
    
    /// Automatically processes and flags content based on AI analysis
    func processAndFlag(
        contentId: UUID,
        contentType: ContentType,
        authorId: UUID,
        text: String? = nil,
        images: [UIImage] = []
    ) async -> ContentProcessingResult {
        
        // Step 1: Run AI moderation
        let moderationResult = await queueService.processContent(
            contentId: contentId,
            contentType: contentType,
            authorId: authorId,
            text: text,
            images: images
        )
        
        // Step 2: Apply automatic actions based on results
        let action = await determineAutomaticAction(
            moderationResult: moderationResult,
            authorId: authorId
        )
        
        // Step 3: Execute automatic action
        await executeAutomaticAction(
            action: action,
            contentId: contentId,
            authorId: authorId,
            moderationResult: moderationResult
        )
        
        // Step 4: Update statistics
        await updateFlaggingStatistics(
            moderationResult: moderationResult,
            action: action
        )
        
        return ContentProcessingResult(
            contentId: contentId,
            moderationResult: moderationResult,
            automaticAction: action,
            requiresHumanReview: moderationResult.requiresHumanReview
        )
    }
    
    /// Processes content in batch for efficiency
    func processBatch(_ items: [ContentBatchItem]) async -> [ContentProcessingResult] {
        var results: [ContentProcessingResult] = []
        
        // Process items concurrently with rate limiting
        let semaphore = AsyncSemaphore(value: 5) // Limit concurrent processing
        
        await withTaskGroup(of: ContentProcessingResult.self) { group in
            for item in items {
                group.addTask {
                    await semaphore.wait()
                    defer { semaphore.signal() }
                    
                    return await self.processAndFlag(
                        contentId: item.contentId,
                        contentType: item.contentType,
                        authorId: item.authorId,
                        text: item.text,
                        images: item.images
                    )
                }
            }
            
            for await result in group {
                results.append(result)
            }
        }
        
        return results
    }
    
    /// Gets flagging rules configuration
    func getFlaggingRules() -> FlaggingRulesConfiguration {
        return FlaggingRulesConfiguration(
            autoRejectThreshold: 0.9,
            autoFlagThreshold: 0.7,
            piiAutoReject: true,
            harassmentAutoReject: true,
            hateSpeechAutoReject: true,
            spamAutoFlag: true,
            multipleReportsThreshold: 3,
            newUserStricterRules: true
        )
    }
    
    /// Updates flagging rules (admin function)
    func updateFlaggingRules(_ rules: FlaggingRulesConfiguration) {
        // In production, this would update database configuration
        print("📋 Flagging rules updated: \(rules)")
    }
    
    /// Gets content that needs re-evaluation
    func getContentForReEvaluation(limit: Int = 100) async -> [UUID] {
        // Find content that might need re-evaluation based on:
        // - Updated AI models
        // - Changed flagging rules
        // - User appeals
        
        // Mock implementation - in production would query database
        return []
    }
    
    // MARK: - Private Methods
    
    private func setupFlaggingRules() {
        // Initialize default flagging rules
        let defaultRules = FlaggingRulesConfiguration(
            autoRejectThreshold: 0.9,
            autoFlagThreshold: 0.7,
            piiAutoReject: true,
            harassmentAutoReject: true,
            hateSpeechAutoReject: true,
            spamAutoFlag: true,
            multipleReportsThreshold: 3,
            newUserStricterRules: true
        )
        
        // In production, load from configuration service
        print("🔧 Flagging rules initialized: \(defaultRules)")
    }
    
    private func determineAutomaticAction(
        moderationResult: ModerationResult,
        authorId: UUID
    ) async -> AutomaticAction {
        
        let rules = getFlaggingRules()
        let userReputation = await getUserReputation(authorId: authorId)
        let isNewUser = await isNewUser(authorId: authorId)
        
        // Auto-reject for PII if enabled
        if rules.piiAutoReject && !moderationResult.detectedPII.isEmpty {
            return .autoReject(reason: "Personal information detected")
        }
        
        // Auto-reject for high-confidence severe violations
        if moderationResult.confidence >= rules.autoRejectThreshold {
            if rules.harassmentAutoReject && moderationResult.flags.contains(.harassment) {
                return .autoReject(reason: "Harassment detected")
            }
            
            if rules.hateSpeechAutoReject && moderationResult.flags.contains(.hateSpeech) {
                return .autoReject(reason: "Hate speech detected")
            }
        }
        
        // Auto-flag for medium confidence violations
        if moderationResult.confidence >= rules.autoFlagThreshold {
            if rules.spamAutoFlag && moderationResult.flags.contains(.spam) {
                return .autoFlag(reason: "Potential spam detected")
            }
            
            if moderationResult.flags.contains(.inappropriateContent) {
                return .autoFlag(reason: "Inappropriate content detected")
            }
        }
        
        // Stricter rules for new users
        if rules.newUserStricterRules && isNewUser {
            if moderationResult.confidence >= 0.6 && !moderationResult.flags.isEmpty {
                return .autoFlag(reason: "New user content requires review")
            }
        }
        
        // Lower threshold for users with poor reputation
        if userReputation < 50 && moderationResult.confidence >= 0.5 {
            return .autoFlag(reason: "Low reputation user content flagged")
        }
        
        // Default: approve if no issues found
        if moderationResult.flags.isEmpty {
            return .autoApprove
        }
        
        // Send to human review for uncertain cases
        return .requireHumanReview
    }
    
    private func executeAutomaticAction(
        action: AutomaticAction,
        contentId: UUID,
        authorId: UUID,
        moderationResult: ModerationResult
    ) async {
        
        switch action {
        case .autoApprove:
            await approveContent(contentId: contentId)
            
        case .autoReject(let reason):
            await rejectContent(contentId: contentId, reason: reason)
            await notifyUser(authorId: authorId, action: .rejected, reason: reason)
            
        case .autoFlag(let reason):
            await flagContent(contentId: contentId, reason: reason)
            // Content remains visible but flagged for review
            
        case .requireHumanReview:
            // Already added to queue by ModerationQueueService
            break
        }
        
        // Apply user penalties if needed
        await applyUserPenalties(
            authorId: authorId,
            moderationResult: moderationResult,
            action: action
        )
    }
    
    private func approveContent(contentId: UUID) async {
        // In production, update content status in database
        print("✅ Content auto-approved: \(contentId)")
    }
    
    private func rejectContent(contentId: UUID, reason: String) async {
        // In production, update content status and hide from public view
        print("❌ Content auto-rejected: \(contentId) - \(reason)")
    }
    
    private func flagContent(contentId: UUID, reason: String) async {
        // In production, mark content as flagged but keep visible
        print("🚩 Content auto-flagged: \(contentId) - \(reason)")
    }
    
    private func applyUserPenalties(
        authorId: UUID,
        moderationResult: ModerationResult,
        action: AutomaticAction
    ) async {
        
        guard case .autoReject = action else { return }
        
        // Apply penalties based on violation severity
        switch moderationResult.severity {
        case .critical:
            await applyUserPenalty(authorId: authorId, penalty: .temporaryBan(days: 7))
            
        case .high:
            await applyUserPenalty(authorId: authorId, penalty: .temporaryBan(days: 3))
            
        case .medium:
            await applyUserPenalty(authorId: authorId, penalty: .warning)
            
        case .low:
            // No penalty for low severity auto-rejections
            break
        }
    }
    
    private func applyUserPenalty(authorId: UUID, penalty: UserPenalty) async {
        // In production, update user status in database
        print("⚠️ User penalty applied: \(authorId) - \(penalty)")
    }
    
    private func notifyUser(authorId: UUID, action: ModerationActionType, reason: String) async {
        // In production, send push notification or in-app message
        print("📱 User notified: \(authorId) - \(action.rawValue): \(reason)")
    }
    
    private func getUserReputation(authorId: UUID) async -> Int {
        // In production, fetch from user service
        return Int.random(in: 0...100) // Mock reputation
    }
    
    private func isNewUser(authorId: UUID) async -> Bool {
        // In production, check user creation date
        return Bool.random() // Mock new user status
    }
    
    private func updateFlaggingStatistics(
        moderationResult: ModerationResult,
        action: AutomaticAction
    ) async {
        await MainActor.run {
            flaggingStatistics.totalProcessed += 1
            
            switch action {
            case .autoApprove:
                flaggingStatistics.autoApproved += 1
            case .autoReject:
                flaggingStatistics.autoRejected += 1
            case .autoFlag:
                flaggingStatistics.autoFlagged += 1
            case .requireHumanReview:
                flaggingStatistics.sentToHumanReview += 1
            }
            
            if !moderationResult.detectedPII.isEmpty {
                flaggingStatistics.piiDetected += 1
            }
        }
    }
}

// MARK: - Supporting Types

struct ContentBatchItem {
    let contentId: UUID
    let contentType: ContentType
    let authorId: UUID
    let text: String?
    let images: [UIImage]
}

struct ContentProcessingResult {
    let contentId: UUID
    let moderationResult: ModerationResult
    let automaticAction: AutomaticAction
    let requiresHumanReview: Bool
}

enum AutomaticAction {
    case autoApprove
    case autoReject(reason: String)
    case autoFlag(reason: String)
    case requireHumanReview
}

struct FlaggingRulesConfiguration {
    let autoRejectThreshold: Double
    let autoFlagThreshold: Double
    let piiAutoReject: Bool
    let harassmentAutoReject: Bool
    let hateSpeechAutoReject: Bool
    let spamAutoFlag: Bool
    let multipleReportsThreshold: Int
    let newUserStricterRules: Bool
}

enum UserPenalty {
    case warning
    case temporaryBan(days: Int)
    case permanentBan
}

struct FlaggingStatistics {
    var totalProcessed: Int = 0
    var autoApproved: Int = 0
    var autoRejected: Int = 0
    var autoFlagged: Int = 0
    var sentToHumanReview: Int = 0
    var piiDetected: Int = 0
    
    var autoApprovalRate: Double {
        guard totalProcessed > 0 else { return 0 }
        return Double(autoApproved) / Double(totalProcessed)
    }
    
    var humanReviewRate: Double {
        guard totalProcessed > 0 else { return 0 }
        return Double(sentToHumanReview) / Double(totalProcessed)
    }
}

// MARK: - Async Semaphore Helper
actor AsyncSemaphore {
    private var count: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.count = value
    }
    
    func wait() async {
        if count > 0 {
            count -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            count += 1
        } else {
            let waiter = waiters.removeFirst()
            waiter.resume()
        }
    }
}

// MARK: - Mock User Service
class UserService {
    static let shared = UserService()
    private init() {}
    
    // Mock implementation - in production would be actual user service
}