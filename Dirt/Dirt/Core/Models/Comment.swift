import Foundation

struct Comment: Codable, Identifiable, Equatable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let content: String
    let createdAt: Date
    var updatedAt: Date
    var likeCount: Int
    var replyCount: Int
    var isVisible: Bool
    var isReported: Bool
    var reportCount: Int
    var replies: [Comment]
    
    init(
        id: UUID = UUID(),
        postId: UUID,
        authorId: UUID,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        likeCount: Int = 0,
        replyCount: Int = 0,
        isVisible: Bool = true,
        isReported: Bool = false,
        reportCount: Int = 0,
        replies: [Comment] = []
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.isVisible = isVisible
        self.isReported = isReported
        self.reportCount = reportCount
        self.replies = replies
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var hasReplies: Bool {
        return !replies.isEmpty
    }
    
    var isLongContent: Bool {
        return content.count > 200
    }
}

// MARK: - Comment Extensions

extension Comment {
    static func mockComment(
        postId: UUID,
        content: String,
        likeCount: Int = 0,
        replyCount: Int = 0,
        replies: [Comment] = []
    ) -> Comment {
        Comment(
            postId: postId,
            authorId: UUID(),
            content: content,
            likeCount: likeCount,
            replyCount: replyCount,
            replies: replies
        )
    }
}

// MARK: - Comment Sorting

extension Array where Element == Comment {
    func sortedByPopularity() -> [Comment] {
        return sorted { $0.likeCount > $1.likeCount }
    }
    
    func sortedByRecent() -> [Comment] {
        return sorted { $0.createdAt > $1.createdAt }
    }
    
    func sortedByOldest() -> [Comment] {
        return sorted { $0.createdAt < $1.createdAt }
    }
}