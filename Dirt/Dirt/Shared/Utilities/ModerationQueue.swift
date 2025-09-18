import Foundation

// MARK: - ModerationQueue (stub)
// Tracks reported items locally and applies a simple auto-hide threshold policy.
struct ModerationItem: Identifiable, Codable {
    let id: UUID
    let reason: String
    let createdAt: Date
    var count: Int
}

final class ModerationQueue: ObservableObject {
    static let shared = ModerationQueue()
    @Published private(set) var items: [UUID: ModerationItem] = [:]
    
    // Auto-hide after N reports (local policy; tune later)
    var autoHideThreshold: Int = 1
    
    private init() {}
    
    func enqueue(postId: UUID, reason: String) {
        if var existing = items[postId] {
            existing.count += 1
            items[postId] = existing
        } else {
            items[postId] = ModerationItem(id: postId, reason: reason, createdAt: Date(), count: 1)
        }
    }
    
    func shouldAutoHide(postId: UUID) -> Bool {
        guard let item = items[postId] else { return false }
        return item.count >= autoHideThreshold
    }
}