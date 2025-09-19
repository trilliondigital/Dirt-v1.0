import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: UUID
    let email: String?
    let username: String?
    let createdAt: Date
    var lastActiveAt: Date
    var isVerified: Bool
    var reputation: Int
    var profileImageURL: String?
    
    // Privacy settings
    var isAnonymous: Bool
    var allowDirectMessages: Bool
    var showOnlineStatus: Bool
    
    // Preferences
    var preferredCategories: [PostCategory]
    var blockedUsers: [UUID]
    var savedPosts: [UUID]
    
    init(
        id: UUID = UUID(),
        email: String? = nil,
        username: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        isVerified: Bool = false,
        reputation: Int = 0,
        profileImageURL: String? = nil,
        isAnonymous: Bool = true,
        allowDirectMessages: Bool = false,
        showOnlineStatus: Bool = false,
        preferredCategories: [PostCategory] = [],
        blockedUsers: [UUID] = [],
        savedPosts: [UUID] = []
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isVerified = isVerified
        self.reputation = reputation
        self.profileImageURL = profileImageURL
        self.isAnonymous = isAnonymous
        self.allowDirectMessages = allowDirectMessages
        self.showOnlineStatus = showOnlineStatus
        self.preferredCategories = preferredCategories
        self.blockedUsers = blockedUsers
        self.savedPosts = savedPosts
    }
    
    var displayName: String {
        if isAnonymous {
            return "Anonymous User"
        }
        return username ?? "User"
    }
    
    var reputationLevel: ReputationLevel {
        switch reputation {
        case 0..<100:
            return .newcomer
        case 100..<500:
            return .contributor
        case 500..<1000:
            return .trusted
        case 1000..<2500:
            return .expert
        default:
            return .legend
        }
    }
}

enum ReputationLevel: String, CaseIterable {
    case newcomer = "Newcomer"
    case contributor = "Contributor"
    case trusted = "Trusted"
    case expert = "Expert"
    case legend = "Legend"
    
    var color: String {
        switch self {
        case .newcomer:
            return "gray"
        case .contributor:
            return "blue"
        case .trusted:
            return "green"
        case .expert:
            return "orange"
        case .legend:
            return "purple"
        }
    }
    
    var iconName: String {
        switch self {
        case .newcomer:
            return "person"
        case .contributor:
            return "person.badge.plus"
        case .trusted:
            return "checkmark.seal"
        case .expert:
            return "star"
        case .legend:
            return "crown"
        }
    }
}