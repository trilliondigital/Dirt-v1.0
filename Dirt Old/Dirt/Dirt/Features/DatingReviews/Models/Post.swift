import Foundation

// MARK: - Dating Review Post Model
struct DatingReviewPost: Codable, Identifiable, Equatable {
    let id: UUID
    let authorId: UUID
    let title: String
    let content: String
    let category: PostCategory
    let tags: [String]
    let createdAt: Date
    var upvotes: Int
    var downvotes: Int
    var commentCount: Int
    var isModerated: Bool
    var moderationStatus: ModerationStatus
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        title: String,
        content: String,
        category: PostCategory,
        tags: [String] = [],
        createdAt: Date = Date(),
        upvotes: Int = 0,
        downvotes: Int = 0,
        commentCount: Int = 0,
        isModerated: Bool = false,
        moderationStatus: ModerationStatus = .pending
    ) {
        self.id = id
        self.authorId = authorId
        self.title = title
        self.content = content
        self.category = category
        self.tags = tags
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.commentCount = commentCount
        self.isModerated = isModerated
        self.moderationStatus = moderationStatus
    }
}

// MARK: - Post Categories
enum PostCategory: String, CaseIterable, Codable {
    case advice = "Advice"
    case experience = "Experience"
    case question = "Question"
    case strategy = "Strategy"
    case success = "Success Story"
    case rant = "Rant"
    case general = "General Discussion"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .advice:
            return "Share dating advice and tips"
        case .experience:
            return "Share your dating experiences"
        case .question:
            return "Ask the community for help"
        case .strategy:
            return "Discuss dating strategies and approaches"
        case .success:
            return "Share your success stories"
        case .rant:
            return "Vent about dating frustrations"
        case .general:
            return "General dating discussions"
        }
    }
    
    var iconName: String {
        switch self {
        case .advice:
            return "lightbulb"
        case .experience:
            return "person.2"
        case .question:
            return "questionmark.circle"
        case .strategy:
            return "target"
        case .success:
            return "star"
        case .rant:
            return "exclamationmark.bubble"
        case .general:
            return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Post Validation
extension DatingReviewPost {
    func validate() throws {
        guard !title.isEmpty else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard !content.isEmpty else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard title.count <= 200 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard content.count <= 10000 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        // Validate tags
        for tag in tags {
            guard !tag.isEmpty else {
                throw DatingReviewValidationError.invalidContent
            }
        }
    }
    
    var netScore: Int {
        upvotes - downvotes
    }
    
    var isVisible: Bool {
        moderationStatus == .approved && !isModerated
    }
    
    var engagementScore: Double {
        let totalVotes = upvotes + downvotes
        let commentWeight = commentCount * 2
        let timeDecay = max(0.1, 1.0 - (Date().timeIntervalSince(createdAt) / (24 * 60 * 60))) // Decay over 24 hours
        
        return Double(netScore + commentWeight) * timeDecay
    }
}

// MARK: - Post Tags
enum PostTag: String, CaseIterable {
    case dating101 = "Dating 101"
    case onlineDating = "Online Dating"
    case firstDate = "First Date"
    case relationships = "Relationships"
    case breakup = "Breakup"
    case confidence = "Confidence"
    case communication = "Communication"
    case redFlags = "Red Flags"
    case greenFlags = "Green Flags"
    case texting = "Texting"
    case photos = "Photos"
    case profile = "Profile"
    case approach = "Approach"
    case rejection = "Rejection"
    case success = "Success"
    case failure = "Failure"
    case tinder = "Tinder"
    case bumble = "Bumble"
    case hinge = "Hinge"
    case irl = "IRL"
    
    var displayName: String {
        return rawValue
    }
}