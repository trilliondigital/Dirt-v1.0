import Foundation

// MARK: - Review Model
struct Review: Codable, Identifiable, Equatable {
    let id: UUID
    let authorId: UUID
    let profileScreenshots: [String] // URLs to blurred images
    let ratings: ReviewRatings
    let content: String
    let tags: [String]
    let datingApp: DatingApp
    let createdAt: Date
    var upvotes: Int
    var downvotes: Int
    var commentCount: Int
    var isModerated: Bool
    var moderationStatus: ModerationStatus
    
    init(
        id: UUID = UUID(),
        authorId: UUID,
        profileScreenshots: [String],
        ratings: ReviewRatings,
        content: String,
        tags: [String],
        datingApp: DatingApp,
        createdAt: Date = Date(),
        upvotes: Int = 0,
        downvotes: Int = 0,
        commentCount: Int = 0,
        isModerated: Bool = false,
        moderationStatus: ModerationStatus = .pending
    ) {
        self.id = id
        self.authorId = authorId
        self.profileScreenshots = profileScreenshots
        self.ratings = ratings
        self.content = content
        self.tags = tags
        self.datingApp = datingApp
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.commentCount = commentCount
        self.isModerated = isModerated
        self.moderationStatus = moderationStatus
    }
}

// MARK: - Review Ratings
struct ReviewRatings: Codable, Equatable {
    let photos: Int // 1-5
    let bio: Int // 1-5
    let conversation: Int // 1-5
    let overall: Int // 1-5
    
    init(photos: Int, bio: Int, conversation: Int, overall: Int) {
        self.photos = photos
        self.bio = bio
        self.conversation = conversation
        self.overall = overall
    }
    
    var averageRating: Double {
        Double(photos + bio + conversation + overall) / 4.0
    }
}

// MARK: - Dating Apps
enum DatingApp: String, CaseIterable, Codable {
    case tinder = "Tinder"
    case bumble = "Bumble"
    case hinge = "Hinge"
    case coffeeMeetsBagel = "Coffee Meets Bagel"
    case okcupid = "OkCupid"
    case match = "Match"
    case eharmony = "eHarmony"
    case plentyOfFish = "Plenty of Fish"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Moderation Status
enum ModerationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case flagged = "flagged"
    case underReview = "under_review"
}

// MARK: - Review Validation
extension Review {
    func validate() throws {
        guard !content.isEmpty else {
            throw DatingReviewValidationError.invalidContent
        }
        
        try ratings.validate()
        
        guard !profileScreenshots.isEmpty else {
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
}

// MARK: - Review Ratings Validation
extension ReviewRatings {
    func validate() throws {
        guard (1...5).contains(photos) else {
            throw DatingReviewValidationError.invalidRating
        }
        
        guard (1...5).contains(bio) else {
            throw DatingReviewValidationError.invalidRating
        }
        
        guard (1...5).contains(conversation) else {
            throw DatingReviewValidationError.invalidRating
        }
        
        guard (1...5).contains(overall) else {
            throw DatingReviewValidationError.invalidRating
        }
    }
}

// MARK: - Review Tags
enum ReviewTag: String, CaseIterable {
    case redFlag = "Red Flag"
    case greenFlag = "Green Flag"
    case catfish = "Catfish"
    case authentic = "Authentic"
    case goodConversation = "Good Conversation"
    case poorConversation = "Poor Conversation"
    case misleadingPhotos = "Misleading Photos"
    case accuratePhotos = "Accurate Photos"
    case respectful = "Respectful"
    case disrespectful = "Disrespectful"
    case ghosted = "Ghosted"
    case metInPerson = "Met in Person"
    case longTermPotential = "Long Term Potential"
    case hookupOnly = "Hookup Only"
    
    var displayName: String {
        return rawValue
    }
    
    var isPositive: Bool {
        switch self {
        case .greenFlag, .authentic, .goodConversation, .accuratePhotos, .respectful, .metInPerson, .longTermPotential:
            return true
        case .redFlag, .catfish, .poorConversation, .misleadingPhotos, .disrespectful, .ghosted, .hookupOnly:
            return false
        }
    }
}