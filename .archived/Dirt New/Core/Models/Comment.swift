import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let content: String
    let createdAt: Date
    var updatedAt: Date
    var upvotes: Int
    var downvotes: Int
    var isVisible: Bool
    var isReported: Bool
    var reportCount: Int
    
    init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        upvotes: Int = 0,
        downvotes: Int = 0,
        isVisible: Bool = true,
        isReported: Bool = false,
        reportCount: Int = 0
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.isVisible = isVisible
        self.isReported = isReported
        self.reportCount = reportCount
    }
    
    var netScore: Int {
        return upvotes - downvotes
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}