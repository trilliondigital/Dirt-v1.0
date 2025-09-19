import Foundation

// MARK: - Achievement Types
enum AchievementType: String, CaseIterable, Codable {
    case firstPost = "first_post"
    case firstReview = "first_review"
    case helpfulContributor = "helpful_contributor"
    case trustedMember = "trusted_member"
    case communityLeader = "community_leader"
    case moderator = "moderator"
    case veteran = "veteran"
    case topContributor = "top_contributor"
    
    var title: String {
        switch self {
        case .firstPost: return "First Post"
        case .firstReview: return "First Review"
        case .helpfulContributor: return "Helpful Contributor"
        case .trustedMember: return "Trusted Member"
        case .communityLeader: return "Community Leader"
        case .moderator: return "Moderator"
        case .veteran: return "Veteran"
        case .topContributor: return "Top Contributor"
        }
    }
    
    var description: String {
        switch self {
        case .firstPost: return "Created your first discussion post"
        case .firstReview: return "Submitted your first review"
        case .helpfulContributor: return "Received 50+ upvotes on contributions"
        case .trustedMember: return "Reached 100 reputation points"
        case .communityLeader: return "Reached 500 reputation points"
        case .moderator: return "Gained moderation privileges"
        case .veteran: return "Active member for 6+ months"
        case .topContributor: return "Reached 1000 reputation points"
        }
    }
    
    var requiredReputation: Int {
        switch self {
        case .firstPost, .firstReview: return 0
        case .helpfulContributor: return 50
        case .trustedMember: return 100
        case .communityLeader: return 500
        case .moderator: return 100
        case .veteran: return 0 // Time-based
        case .topContributor: return 1000
        }
    }
}

// MARK: - Reputation Action Types
enum ReputationAction: String, CaseIterable, Codable {
    case postUpvote = "post_upvote"
    case postDownvote = "post_downvote"
    case reviewUpvote = "review_upvote"
    case reviewDownvote = "review_downvote"
    case commentUpvote = "comment_upvote"
    case commentDownvote = "comment_downvote"
    case contentReported = "content_reported"
    case contentRemoved = "content_removed"
    case helpfulReview = "helpful_review"
    case qualityPost = "quality_post"
    
    var points: Int {
        switch self {
        case .postUpvote: return 2
        case .postDownvote: return -1
        case .reviewUpvote: return 3
        case .reviewDownvote: return -1
        case .commentUpvote: return 1
        case .commentDownvote: return -1
        case .contentReported: return -5
        case .contentRemoved: return -10
        case .helpfulReview: return 5
        case .qualityPost: return 3
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let type: AchievementType
    let earnedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, type: AchievementType, earnedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.type = type
        self.earnedAt = earnedAt
    }
}

// MARK: - Reputation Event Model
struct ReputationEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let action: ReputationAction
    let points: Int
    let contentId: UUID?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        action: ReputationAction,
        points: Int? = nil,
        contentId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.action = action
        self.points = points ?? action.points
        self.contentId = contentId
        self.createdAt = createdAt
    }
}

// MARK: - Reputation Service Protocol
protocol ReputationServiceProtocol {
    func addReputationPoints(userId: UUID, action: ReputationAction, contentId: UUID?) async throws
    func getUserReputation(userId: UUID) async throws -> Int
    func getUserAchievements(userId: UUID) async throws -> [Achievement]
    func checkAndAwardAchievements(userId: UUID) async throws -> [Achievement]
    func getReputationHistory(userId: UUID, limit: Int) async throws -> [ReputationEvent]
    func canUserPerformAction(userId: UUID, action: UserAction) async throws -> Bool
}

// MARK: - User Action Types
enum UserAction {
    case createPost
    case createReview
    case moderate
    case reportContent
    case uploadMedia
}

// MARK: - Reputation Service Implementation
class ReputationService: ReputationServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "user_achievements"
    private let reputationEventsKey = "reputation_events"
    private let userReputationKey = "user_reputation"
    
    // MARK: - Reputation Management
    
    func addReputationPoints(userId: UUID, action: ReputationAction, contentId: UUID? = nil) async throws {
        let event = ReputationEvent(
            userId: userId,
            action: action,
            contentId: contentId
        )
        
        // Store the reputation event
        try await storeReputationEvent(event)
        
        // Update user's total reputation
        let currentReputation = try await getUserReputation(userId: userId)
        let newReputation = max(0, currentReputation + event.points) // Reputation can't go below 0
        try await updateUserReputation(userId: userId, reputation: newReputation)
        
        // Check for new achievements
        let newAchievements = try await checkAndAwardAchievements(userId: userId)
        
        // Log reputation change
        print("User \(userId) reputation changed by \(event.points) points (action: \(action.rawValue))")
        if !newAchievements.isEmpty {
            print("New achievements earned: \(newAchievements.map { $0.type.title })")
        }
    }
    
    func getUserReputation(userId: UUID) async throws -> Int {
        let key = "\(userReputationKey)_\(userId.uuidString)"
        return userDefaults.integer(forKey: key)
    }
    
    private func updateUserReputation(userId: UUID, reputation: Int) async throws {
        let key = "\(userReputationKey)_\(userId.uuidString)"
        userDefaults.set(reputation, forKey: key)
    }
    
    // MARK: - Achievement Management
    
    func getUserAchievements(userId: UUID) async throws -> [Achievement] {
        let key = "\(achievementsKey)_\(userId.uuidString)"
        guard let data = userDefaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([Achievement].self, from: data)
    }
    
    func checkAndAwardAchievements(userId: UUID) async throws -> [Achievement] {
        let currentAchievements = try await getUserAchievements(userId: userId)
        let currentAchievementTypes = Set(currentAchievements.map { $0.type })
        var newAchievements: [Achievement] = []
        
        let reputation = try await getUserReputation(userId: userId)
        let reputationHistory = try await getReputationHistory(userId: userId, limit: 1000)
        
        // Check reputation-based achievements
        for achievementType in AchievementType.allCases {
            guard !currentAchievementTypes.contains(achievementType) else { continue }
            
            let shouldAward = await shouldAwardAchievement(
                type: achievementType,
                userId: userId,
                reputation: reputation,
                reputationHistory: reputationHistory
            )
            
            if shouldAward {
                let achievement = Achievement(userId: userId, type: achievementType)
                newAchievements.append(achievement)
            }
        }
        
        // Store new achievements
        if !newAchievements.isEmpty {
            let allAchievements = currentAchievements + newAchievements
            try await storeUserAchievements(userId: userId, achievements: allAchievements)
        }
        
        return newAchievements
    }
    
    private func shouldAwardAchievement(
        type: AchievementType,
        userId: UUID,
        reputation: Int,
        reputationHistory: [ReputationEvent]
    ) async -> Bool {
        switch type {
        case .firstPost:
            return reputationHistory.contains { $0.action == .postUpvote || $0.action == .qualityPost }
        case .firstReview:
            return reputationHistory.contains { $0.action == .reviewUpvote || $0.action == .helpfulReview }
        case .helpfulContributor:
            let upvotes = reputationHistory.filter { 
                $0.action == .postUpvote || $0.action == .reviewUpvote || $0.action == .commentUpvote 
            }.count
            return upvotes >= 50
        case .trustedMember:
            return reputation >= 100
        case .communityLeader:
            return reputation >= 500
        case .moderator:
            return reputation >= 100 // Additional moderation privileges check would be needed
        case .veteran:
            // Check if user has been active for 6+ months
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            return reputationHistory.first?.createdAt ?? Date() <= sixMonthsAgo
        case .topContributor:
            return reputation >= 1000
        }
    }
    
    // MARK: - Permission Checks
    
    func canUserPerformAction(userId: UUID, action: UserAction) async throws -> Bool {
        let reputation = try await getUserReputation(userId: userId)
        
        switch action {
        case .createPost, .createReview:
            return reputation >= 0 // Basic requirement
        case .moderate:
            return reputation >= 100
        case .reportContent:
            return reputation >= 10 // Prevent spam reporting
        case .uploadMedia:
            return reputation >= 5 // Prevent spam uploads
        }
    }
    
    // MARK: - History and Events
    
    func getReputationHistory(userId: UUID, limit: Int = 50) async throws -> [ReputationEvent] {
        let key = "\(reputationEventsKey)_\(userId.uuidString)"
        guard let data = userDefaults.data(forKey: key) else { return [] }
        let events = try JSONDecoder().decode([ReputationEvent].self, from: data)
        return Array(events.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }
    
    private func storeReputationEvent(_ event: ReputationEvent) async throws {
        let key = "\(reputationEventsKey)_\(event.userId.uuidString)"
        var events = try await getReputationHistory(userId: event.userId, limit: 1000)
        events.append(event)
        
        // Keep only the last 1000 events to prevent unlimited growth
        if events.count > 1000 {
            events = Array(events.suffix(1000))
        }
        
        let data = try JSONEncoder().encode(events)
        userDefaults.set(data, forKey: key)
    }
    
    private func storeUserAchievements(userId: UUID, achievements: [Achievement]) async throws {
        let key = "\(achievementsKey)_\(userId.uuidString)"
        let data = try JSONEncoder().encode(achievements)
        userDefaults.set(data, forKey: key)
    }
}

// MARK: - Reputation Service Extensions

extension ReputationService {
    
    // Convenience methods for common reputation actions
    
    func handleContentUpvote(userId: UUID, contentId: UUID, contentType: ReputationContentType) async throws {
        let action: ReputationAction
        switch contentType {
        case .post:
            action = .postUpvote
        case .review:
            action = .reviewUpvote
        case .comment:
            action = .commentUpvote
        }
        
        try await addReputationPoints(userId: userId, action: action, contentId: contentId)
    }
    
    func handleContentDownvote(userId: UUID, contentId: UUID, contentType: ReputationContentType) async throws {
        let action: ReputationAction
        switch contentType {
        case .post:
            action = .postDownvote
        case .review:
            action = .reviewDownvote
        case .comment:
            action = .commentDownvote
        }
        
        try await addReputationPoints(userId: userId, action: action, contentId: contentId)
    }
    
    func handleContentReport(userId: UUID, contentId: UUID) async throws {
        try await addReputationPoints(userId: userId, action: .contentReported, contentId: contentId)
    }
    
    func handleContentRemoval(userId: UUID, contentId: UUID) async throws {
        try await addReputationPoints(userId: userId, action: .contentRemoved, contentId: contentId)
    }
    
    func handleQualityContent(userId: UUID, contentId: UUID, contentType: ReputationContentType) async throws {
        let action: ReputationAction = contentType == .review ? .helpfulReview : .qualityPost
        try await addReputationPoints(userId: userId, action: action, contentId: contentId)
    }
}

// MARK: - Reputation Content Type Enum
enum ReputationContentType {
    case post
    case review
    case comment
}