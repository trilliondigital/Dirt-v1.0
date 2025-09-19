import Foundation
import Combine

// MARK: - Moderation Queue Service
class ModerationQueueService: ObservableObject {
    static let shared = ModerationQueueService()
    
    @Published var queueItems: [ModerationQueueItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let aiModerationService = AIContentModerationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize with mock data for development
        loadMockQueueItems()
    }
    
    // MARK: - Public API
    
    /// Adds content to moderation queue
    func addToQueue(
        contentId: UUID,
        contentType: ContentType,
        authorId: UUID,
        content: String? = nil,
        imageUrls: [String] = [],
        moderationResult: ModerationResult,
        reportCount: Int = 0
    ) async {
        let priority = determinePriority(
            moderationResult: moderationResult,
            reportCount: reportCount
        )
        
        let queueItem = ModerationQueueItem(
            id: UUID(),
            contentId: contentId,
            contentType: contentType,
            authorId: authorId,
            content: content,
            imageUrls: imageUrls,
            moderationResult: moderationResult,
            reportCount: reportCount,
            priority: priority,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await MainActor.run {
            queueItems.append(queueItem)
            sortQueue()
        }
        
        // Notify moderators if high priority
        if queueItem.isHighPriority {
            await notifyModerators(for: queueItem)
        }
    }
    
    /// Processes content automatically and adds to queue if needed
    func processContent(
        contentId: UUID,
        contentType: ContentType,
        authorId: UUID,
        text: String? = nil,
        images: [UIImage] = []
    ) async -> ModerationResult {
        
        var moderationResult: ModerationResult
        
        // Determine moderation approach based on content type
        switch contentType {
        case .review:
            if let text = text {
                moderationResult = await aiModerationService.moderateReview(
                    text: text,
                    images: images
                )
            } else {
                // Image-only review
                if let firstImage = images.first {
                    moderationResult = await aiModerationService.moderateImage(firstImage)
                } else {
                    // No content to moderate
                    moderationResult = createApprovedResult(contentId: contentId, contentType: contentType)
                }
            }
            
        case .post, .comment:
            if let text = text {
                moderationResult = await aiModerationService.moderateText(text)
            } else {
                moderationResult = createApprovedResult(contentId: contentId, contentType: contentType)
            }
            
        case .image:
            if let image = images.first {
                moderationResult = await aiModerationService.moderateImage(image)
            } else {
                moderationResult = createApprovedResult(contentId: contentId, contentType: contentType)
            }
        }
        
        // Add to queue if requires human review or is flagged
        if moderationResult.requiresHumanReview || 
           moderationResult.status == .flagged || 
           moderationResult.status == .rejected {
            
            let imageUrls = images.enumerated().map { index, _ in
                "temp_image_\(contentId)_\(index).jpg"
            }
            
            await addToQueue(
                contentId: contentId,
                contentType: contentType,
                authorId: authorId,
                content: text,
                imageUrls: imageUrls,
                moderationResult: moderationResult
            )
        }
        
        return moderationResult
    }
    
    /// Retrieves queue items with filtering and sorting
    func getQueueItems(
        priority: ModerationPriority? = nil,
        contentType: ContentType? = nil,
        status: ModerationStatus? = nil,
        limit: Int = 50
    ) -> [ModerationQueueItem] {
        
        var filteredItems = queueItems
        
        if let priority = priority {
            filteredItems = filteredItems.filter { $0.priority == priority }
        }
        
        if let contentType = contentType {
            filteredItems = filteredItems.filter { $0.contentType == contentType }
        }
        
        if let status = status {
            filteredItems = filteredItems.filter { $0.moderationResult.status == status }
        }
        
        return Array(filteredItems.prefix(limit))
    }
    
    /// Removes item from queue after moderation
    func removeFromQueue(itemId: UUID) {
        queueItems.removeAll { $0.id == itemId }
    }
    
    /// Updates queue item with moderation action
    func updateQueueItem(
        itemId: UUID,
        action: ModerationActionType,
        moderatorId: UUID,
        reason: String,
        notes: String? = nil
    ) async {
        
        guard let index = queueItems.firstIndex(where: { $0.id == itemId }) else {
            return
        }
        
        var item = queueItems[index]
        
        // Update moderation result based on action
        let newStatus: ModerationStatus
        switch action {
        case .approve:
            newStatus = .approved
        case .reject, .delete:
            newStatus = .rejected
        case .flag:
            newStatus = .flagged
        case .edit:
            newStatus = .underReview
        case .ban, .warn:
            newStatus = .rejected
        }
        
        // Create updated moderation result
        let updatedResult = ModerationResult(
            contentId: item.moderationResult.contentId,
            contentType: item.moderationResult.contentType,
            status: newStatus,
            flags: item.moderationResult.flags,
            confidence: item.moderationResult.confidence,
            severity: item.moderationResult.severity,
            reason: reason,
            detectedPII: item.moderationResult.detectedPII,
            createdAt: item.moderationResult.createdAt,
            reviewedAt: Date(),
            reviewedBy: moderatorId,
            notes: notes
        )
        
        // Update queue item
        item = ModerationQueueItem(
            id: item.id,
            contentId: item.contentId,
            contentType: item.contentType,
            authorId: item.authorId,
            content: item.content,
            imageUrls: item.imageUrls,
            moderationResult: updatedResult,
            reportCount: item.reportCount,
            priority: item.priority,
            createdAt: item.createdAt,
            updatedAt: Date()
        )
        
        await MainActor.run {
            queueItems[index] = item
        }
        
        // Log moderation action
        await logModerationAction(
            contentId: item.contentId,
            moderatorId: moderatorId,
            action: action,
            reason: reason,
            notes: notes
        )
        
        // Remove from queue if final action
        if [.approve, .reject, .delete].contains(action) {
            await MainActor.run {
                removeFromQueue(itemId: itemId)
            }
        }
    }
    
    /// Gets queue statistics for dashboard
    func getQueueStatistics() -> ModerationQueueStatistics {
        let totalItems = queueItems.count
        let highPriorityItems = queueItems.filter { $0.isHighPriority }.count
        let pendingItems = queueItems.filter { $0.moderationResult.status == .pending }.count
        let flaggedItems = queueItems.filter { $0.moderationResult.status == .flagged }.count
        
        let averageWaitTime = calculateAverageWaitTime()
        
        return ModerationQueueStatistics(
            totalItems: totalItems,
            highPriorityItems: highPriorityItems,
            pendingItems: pendingItems,
            flaggedItems: flaggedItems,
            averageWaitTimeMinutes: averageWaitTime
        )
    }
    
    // MARK: - Private Methods
    
    private func determinePriority(
        moderationResult: ModerationResult,
        reportCount: Int
    ) -> ModerationPriority {
        
        // Critical priority for severe violations or multiple reports
        if moderationResult.severity == .critical || reportCount >= 5 {
            return .critical
        }
        
        // High priority for high severity or multiple reports
        if moderationResult.severity == .high || reportCount >= 3 {
            return .high
        }
        
        // Medium priority for medium severity or some reports
        if moderationResult.severity == .medium || reportCount >= 1 {
            return .medium
        }
        
        return .low
    }
    
    private func sortQueue() {
        queueItems.sort { item1, item2 in
            // First sort by priority
            if item1.priority.sortOrder != item2.priority.sortOrder {
                return item1.priority.sortOrder < item2.priority.sortOrder
            }
            
            // Then by creation date (oldest first)
            return item1.createdAt < item2.createdAt
        }
    }
    
    private func createApprovedResult(
        contentId: UUID,
        contentType: ContentType
    ) -> ModerationResult {
        return ModerationResult(
            contentId: contentId,
            contentType: contentType,
            status: .approved,
            flags: [],
            confidence: 1.0,
            severity: .low,
            reason: nil,
            detectedPII: [],
            createdAt: Date(),
            reviewedAt: Date(),
            reviewedBy: nil,
            notes: "Auto-approved - no violations detected"
        )
    }
    
    private func notifyModerators(for item: ModerationQueueItem) async {
        // In production, this would send push notifications to moderators
        print("🚨 High priority moderation item: \(item.id)")
        print("Content Type: \(item.contentType.rawValue)")
        print("Flags: \(item.moderationResult.flags.map { $0.description }.joined(separator: ", "))")
    }
    
    private func logModerationAction(
        contentId: UUID,
        moderatorId: UUID,
        action: ModerationActionType,
        reason: String,
        notes: String?
    ) async {
        let moderationAction = ModerationAction(
            id: UUID(),
            contentId: contentId,
            moderatorId: moderatorId,
            action: action,
            reason: reason,
            notes: notes,
            createdAt: Date()
        )
        
        // In production, this would be saved to database
        print("📝 Moderation action logged: \(action.rawValue) for content \(contentId)")
    }
    
    private func calculateAverageWaitTime() -> Int {
        let now = Date()
        let waitTimes = queueItems.map { item in
            Int(now.timeIntervalSince(item.createdAt) / 60) // Convert to minutes
        }
        
        guard !waitTimes.isEmpty else { return 0 }
        
        return waitTimes.reduce(0, +) / waitTimes.count
    }
    
    private func loadMockQueueItems() {
        // Mock data for development
        let mockItems = [
            createMockQueueItem(
                contentType: .review,
                flags: [.personalInformation],
                priority: .high,
                content: "This person's phone number is 555-123-4567"
            ),
            createMockQueueItem(
                contentType: .post,
                flags: [.harassment],
                priority: .critical,
                content: "Hate speech content example"
            ),
            createMockQueueItem(
                contentType: .comment,
                flags: [.spam],
                priority: .low,
                content: "CLICK HERE FOR AMAZING DEALS!!!"
            )
        ]
        
        queueItems = mockItems
    }
    
    private func createMockQueueItem(
        contentType: ContentType,
        flags: [ModerationFlag],
        priority: ModerationPriority,
        content: String
    ) -> ModerationQueueItem {
        
        let moderationResult = ModerationResult(
            contentId: UUID(),
            contentType: contentType,
            status: .pending,
            flags: flags,
            confidence: 0.85,
            severity: flags.first?.severity ?? .low,
            reason: flags.first?.description,
            detectedPII: [],
            createdAt: Date().addingTimeInterval(-Double.random(in: 300...3600)),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
        
        return ModerationQueueItem(
            id: UUID(),
            contentId: moderationResult.contentId,
            contentType: contentType,
            authorId: UUID(),
            content: content,
            imageUrls: [],
            moderationResult: moderationResult,
            reportCount: Int.random(in: 0...3),
            priority: priority,
            createdAt: moderationResult.createdAt,
            updatedAt: moderationResult.createdAt
        )
    }
}

// MARK: - Moderation Queue Statistics
struct ModerationQueueStatistics {
    let totalItems: Int
    let highPriorityItems: Int
    let pendingItems: Int
    let flaggedItems: Int
    let averageWaitTimeMinutes: Int
}