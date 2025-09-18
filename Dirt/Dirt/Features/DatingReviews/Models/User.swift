import Foundation

// MARK: - User Model
struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let anonymousUsername: String
    let phoneNumberHash: String
    let createdAt: Date
    var reputation: Int
    var isVerified: Bool
    var isBanned: Bool
    var banReason: String?
    var lastActiveAt: Date
    var notificationPreferences: NotificationPreferences
    
    init(
        id: UUID = UUID(),
        anonymousUsername: String,
        phoneNumberHash: String,
        createdAt: Date = Date(),
        reputation: Int = 0,
        isVerified: Bool = false,
        isBanned: Bool = false,
        banReason: String? = nil,
        lastActiveAt: Date = Date(),
        notificationPreferences: NotificationPreferences = NotificationPreferences()
    ) {
        self.id = id
        self.anonymousUsername = anonymousUsername
        self.phoneNumberHash = phoneNumberHash
        self.createdAt = createdAt
        self.reputation = reputation
        self.isVerified = isVerified
        self.isBanned = isBanned
        self.banReason = banReason
        self.lastActiveAt = lastActiveAt
        self.notificationPreferences = notificationPreferences
    }
}

// MARK: - User Validation
extension User {
    func validate() throws {
        guard !anonymousUsername.isEmpty else {
            throw DatingReviewValidationError.invalidUsername
        }
        
        guard !phoneNumberHash.isEmpty else {
            throw DatingReviewValidationError.invalidPhoneHash
        }
        
        guard reputation >= 0 else {
            throw DatingReviewValidationError.invalidReputation
        }
    }
    
    var isActive: Bool {
        !isBanned && isVerified
    }
    
    var canPost: Bool {
        isActive && reputation >= 0
    }
    
    var canModerate: Bool {
        isActive && reputation >= 100
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable, Equatable {
    var repliesEnabled: Bool
    var upvotesEnabled: Bool
    var milestonesEnabled: Bool
    var announcementsEnabled: Bool
    var recommendationsEnabled: Bool
    
    init(
        repliesEnabled: Bool = true,
        upvotesEnabled: Bool = true,
        milestonesEnabled: Bool = true,
        announcementsEnabled: Bool = true,
        recommendationsEnabled: Bool = false
    ) {
        self.repliesEnabled = repliesEnabled
        self.upvotesEnabled = upvotesEnabled
        self.milestonesEnabled = milestonesEnabled
        self.announcementsEnabled = announcementsEnabled
        self.recommendationsEnabled = recommendationsEnabled
    }
}

// MARK: - Dating Review Validation Errors
enum DatingReviewValidationError: Error, LocalizedError {
    case invalidUsername
    case invalidPhoneHash
    case invalidReputation
    case invalidContent
    case invalidRating
    case invalidCategory
    
    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Username cannot be empty"
        case .invalidPhoneHash:
            return "Phone number hash is required"
        case .invalidReputation:
            return "Reputation cannot be negative"
        case .invalidContent:
            return "Content cannot be empty"
        case .invalidRating:
            return "Rating must be between 1 and 5"
        case .invalidCategory:
            return "Invalid category selected"
        }
    }
}