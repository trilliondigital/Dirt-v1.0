import Foundation

// MARK: - Comment Model
struct Comment: Codable, Identifiable, Equatable {
    let id: UUID
    let authorId: UUID
    let parentId: UUID? // For threading - can be another comment ID
    let contentId: UUID // Post or Review ID
    let contentType: ContentType
    let content: String
    let createdAt: Date
    var upvotes: Int
    var downvotes: Int
    var replyCount: Int
    var isModerated: Bool
    var moderationStatus: ModerationStatus
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        parentId: UUID? = nil,
        contentId: UUID,
        contentType: ContentType,
        content: String,
        createdAt: Date = Date(),
        upvotes: Int = 0,
        downvotes: Int = 0,
        replyCount: Int = 0,
        isModerated: Bool = false,
        moderationStatus: ModerationStatus = .pending
    ) {
        self.id = id
        self.authorId = authorId
        self.parentId = parentId
        self.contentId = contentId
        self.contentType = contentType
        self.content = content
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.replyCount = replyCount
        self.isModerated = isModerated
        self.moderationStatus = moderationStatus
    }
}

// ContentType is defined in ModerationModels.swift

// MARK: - Comment Validation
extension Comment {
    func validate() throws {
        guard !content.isEmpty else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard content.count <= 2000 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        // Check for threading depth (max 3 levels)
        if parentId != nil {
            // This would need to be validated against the database
            // to ensure we don't exceed maximum threading depth
        }
    }
    
    var netScore: Int {
        upvotes - downvotes
    }
    
    var isVisible: Bool {
        moderationStatus == .approved && !isModerated
    }
    
    var isReply: Bool {
        parentId != nil
    }
    
    var isTopLevel: Bool {
        parentId == nil
    }
}

// MARK: - Comment Thread Helper
struct CommentThread {
    let topLevelComment: Comment
    var replies: [Comment]
    
    init(topLevelComment: Comment, replies: [Comment] = []) {
        self.topLevelComment = topLevelComment
        self.replies = replies
    }
    
    var totalComments: Int {
        1 + replies.count
    }
    
    var netScore: Int {
        topLevelComment.netScore + replies.reduce(0) { $0 + $1.netScore }
    }
}

// MARK: - Vote Type
enum VoteType: String, Codable, CaseIterable {
    case upvote = "upvote"
    case downvote = "downvote"
    case none = "none"
    
    var value: Int {
        switch self {
        case .upvote:
            return 1
        case .downvote:
            return -1
        case .none:
            return 0
        }
    }
}

// MARK: - User Vote Model
struct UserVote: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let contentId: UUID
    let contentType: ContentType
    let voteType: VoteType
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        contentId: UUID,
        contentType: ContentType,
        voteType: VoteType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.contentId = contentId
        self.contentType = contentType
        self.voteType = voteType
        self.createdAt = createdAt
    }
}

// MARK: - Report Model
struct Report: Codable, Identifiable {
    let id: UUID
    let reporterId: UUID
    let contentId: UUID
    let contentType: ContentType
    let reason: DatingReviewReportReason
    let additionalContext: String?
    let createdAt: Date
    var status: DatingReviewReportStatus
    var reviewedBy: UUID?
    var reviewedAt: Date?
    
    init(
        id: UUID = UUID(),
        reporterId: UUID,
        contentId: UUID,
        contentType: ContentType,
        reason: DatingReviewReportReason,
        additionalContext: String? = nil,
        createdAt: Date = Date(),
        status: DatingReviewReportStatus = .pending,
        reviewedBy: UUID? = nil,
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.reporterId = reporterId
        self.contentId = contentId
        self.contentType = contentType
        self.reason = reason
        self.additionalContext = additionalContext
        self.createdAt = createdAt
        self.status = status
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
    }
}

// MARK: - Dating Review Report Reason
enum DatingReviewReportReason: String, CaseIterable, Codable {
    case harassment = "Harassment"
    case spam = "Spam"
    case personalInfo = "Personal Information"
    case inappropriate = "Inappropriate Content"
    case misinformation = "Misinformation"
    case violence = "Violence or Threats"
    case hate = "Hate Speech"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .harassment:
            return "Bullying, harassment, or targeted attacks"
        case .spam:
            return "Repetitive or promotional content"
        case .personalInfo:
            return "Contains personal information"
        case .inappropriate:
            return "Sexually explicit or inappropriate content"
        case .misinformation:
            return "False or misleading information"
        case .violence:
            return "Threats of violence or harm"
        case .hate:
            return "Hate speech or discrimination"
        case .other:
            return "Other violation of community guidelines"
        }
    }
}

// MARK: - Dating Review Report Status
enum DatingReviewReportStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case reviewed = "reviewed"
    case actionTaken = "action_taken"
    case dismissed = "dismissed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .reviewed:
            return "Reviewed"
        case .actionTaken:
            return "Action Taken"
        case .dismissed:
            return "Dismissed"
        }
    }
}