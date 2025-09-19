import Foundation
import UserNotifications

// MARK: - Reputation Notification Service
class ReputationNotificationService: ObservableObject {
    static let shared = ReputationNotificationService()
    
    @Published var pendingNotifications: [ReputationNotification] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Notification Management
    
    func scheduleAchievementNotification(for achievement: Achievement, username: String) async {
        let notification = ReputationNotification(
            id: UUID(),
            type: .achievement(achievement.type),
            title: "Achievement Unlocked! 🏆",
            message: "Congratulations! You've earned the \"\(achievement.type.title)\" achievement.",
            scheduledAt: Date()
        )
        
        await scheduleNotification(notification)
    }
    
    func scheduleMilestoneNotification(userId: UUID, newReputation: Int, username: String) async {
        guard let milestone = getReputationMilestone(newReputation) else { return }
        
        let notification = ReputationNotification(
            id: UUID(),
            type: .milestone(milestone),
            title: "Reputation Milestone! ⭐",
            message: "You've reached \(newReputation) reputation points and are now a \(milestone.title)!",
            scheduledAt: Date()
        )
        
        await scheduleNotification(notification)
    }
    
    func scheduleFeatureUnlockNotification(feature: UnlockedFeature, username: String) async {
        let notification = ReputationNotification(
            id: UUID(),
            type: .featureUnlock(feature),
            title: "New Feature Unlocked! 🔓",
            message: "Your reputation has unlocked: \(feature.description)",
            scheduledAt: Date()
        )
        
        await scheduleNotification(notification)
    }
    
    private func scheduleNotification(_ notification: ReputationNotification) async {
        // Add to pending notifications
        await MainActor.run {
            pendingNotifications.append(notification)
        }
        
        // Create system notification
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        content.badge = NSNumber(value: pendingNotifications.count)
        
        // Add custom data
        content.userInfo = [
            "notificationId": notification.id.uuidString,
            "type": notification.type.rawValue
        ]
        
        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Milestone Detection
    
    private func getReputationMilestone(_ reputation: Int) -> ReputationMilestone? {
        let milestones: [Int: ReputationMilestone] = [
            50: .contributor,
            100: .trusted,
            250: .veteran,
            500: .expert,
            1000: .legend
        ]
        
        return milestones[reputation]
    }
    
    // MARK: - Notification Handling
    
    func markNotificationAsRead(_ notificationId: UUID) {
        pendingNotifications.removeAll { $0.id == notificationId }
        
        // Remove from notification center
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationId.uuidString])
    }
    
    func clearAllNotifications() {
        pendingNotifications.removeAll()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
}

// MARK: - Reputation Notification Model

struct ReputationNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let scheduledAt: Date
    var isRead: Bool = false
    
    enum NotificationType: String, Codable {
        case achievement
        case milestone
        case featureUnlock
        
        init(achievement: AchievementType) {
            self = .achievement
        }
        
        init(milestone: ReputationMilestone) {
            self = .milestone
        }
        
        init(feature: UnlockedFeature) {
            self = .featureUnlock
        }
    }
}

// MARK: - Reputation Milestone Enum

enum ReputationMilestone: String, CaseIterable, Codable {
    case newcomer = "newcomer"
    case contributor = "contributor"
    case trusted = "trusted"
    case veteran = "veteran"
    case expert = "expert"
    case legend = "legend"
    
    var title: String {
        switch self {
        case .newcomer: return "Newcomer"
        case .contributor: return "Contributor"
        case .trusted: return "Trusted Member"
        case .veteran: return "Veteran"
        case .expert: return "Expert"
        case .legend: return "Legend"
        }
    }
    
    var description: String {
        switch self {
        case .newcomer: return "Welcome to the community!"
        case .contributor: return "You're making valuable contributions"
        case .trusted: return "The community trusts your input"
        case .veteran: return "You're a seasoned community member"
        case .expert: return "Your expertise is highly valued"
        case .legend: return "You're a legendary contributor!"
        }
    }
    
    var requiredReputation: Int {
        switch self {
        case .newcomer: return 0
        case .contributor: return 50
        case .trusted: return 100
        case .veteran: return 250
        case .expert: return 500
        case .legend: return 1000
        }
    }
    
    var color: String {
        switch self {
        case .newcomer: return "gray"
        case .contributor: return "blue"
        case .trusted: return "green"
        case .veteran: return "orange"
        case .expert: return "purple"
        case .legend: return "gold"
        }
    }
    
    var icon: String {
        switch self {
        case .newcomer: return "person"
        case .contributor: return "person.badge.plus"
        case .trusted: return "checkmark.shield"
        case .veteran: return "star.circle"
        case .expert: return "crown"
        case .legend: return "trophy"
        }
    }
}

// MARK: - Unlocked Feature Enum

enum UnlockedFeature: String, CaseIterable, Codable {
    case reporting = "reporting"
    case mediaUpload = "media_upload"
    case moderation = "moderation"
    case advancedSearch = "advanced_search"
    case customProfile = "custom_profile"
    
    var description: String {
        switch self {
        case .reporting: return "Report inappropriate content"
        case .mediaUpload: return "Upload images and media"
        case .moderation: return "Help moderate community content"
        case .advancedSearch: return "Access advanced search filters"
        case .customProfile: return "Customize your profile appearance"
        }
    }
    
    var requiredReputation: Int {
        switch self {
        case .reporting: return 10
        case .mediaUpload: return 5
        case .moderation: return 100
        case .advancedSearch: return 50
        case .customProfile: return 250
        }
    }
    
    var icon: String {
        switch self {
        case .reporting: return "exclamationmark.triangle"
        case .mediaUpload: return "photo"
        case .moderation: return "shield"
        case .advancedSearch: return "magnifyingglass"
        case .customProfile: return "person.crop.circle"
        }
    }
}

// MARK: - Reputation Notification Extensions

extension ReputationNotification.NotificationType {
    static func achievement(_ type: AchievementType) -> Self {
        return .achievement
    }
    
    static func milestone(_ milestone: ReputationMilestone) -> Self {
        return .milestone
    }
    
    static func featureUnlock(_ feature: UnlockedFeature) -> Self {
        return .featureUnlock
    }
}

// MARK: - Enhanced Reputation Service Integration

extension ReputationService {
    
    func addReputationPointsWithNotifications(
        userId: UUID, 
        action: ReputationAction, 
        contentId: UUID? = nil,
        username: String
    ) async throws {
        let oldReputation = try await getUserReputation(userId: userId)
        
        // Add reputation points
        try await addReputationPoints(userId: userId, action: action, contentId: contentId)
        
        let newReputation = try await getUserReputation(userId: userId)
        
        // Check for new achievements and send notifications
        let newAchievements = try await checkAndAwardAchievements(userId: userId)
        for achievement in newAchievements {
            await ReputationNotificationService.shared.scheduleAchievementNotification(
                for: achievement, 
                username: username
            )
        }
        
        // Check for milestone notifications
        if shouldNotifyMilestone(oldReputation: oldReputation, newReputation: newReputation) {
            await ReputationNotificationService.shared.scheduleMilestoneNotification(
                userId: userId,
                newReputation: newReputation,
                username: username
            )
        }
        
        // Check for feature unlocks
        let unlockedFeatures = getNewlyUnlockedFeatures(
            oldReputation: oldReputation, 
            newReputation: newReputation
        )
        
        for feature in unlockedFeatures {
            await ReputationNotificationService.shared.scheduleFeatureUnlockNotification(
                feature: feature,
                username: username
            )
        }
    }
    
    private func shouldNotifyMilestone(oldReputation: Int, newReputation: Int) -> Bool {
        let milestones = [50, 100, 250, 500, 1000]
        
        for milestone in milestones {
            if oldReputation < milestone && newReputation >= milestone {
                return true
            }
        }
        
        return false
    }
    
    private func getNewlyUnlockedFeatures(oldReputation: Int, newReputation: Int) -> [UnlockedFeature] {
        return UnlockedFeature.allCases.filter { feature in
            oldReputation < feature.requiredReputation && newReputation >= feature.requiredReputation
        }
    }
}

// MARK: - Notification View Component

struct ReputationNotificationView: View {
    let notification: ReputationNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Notification Icon
            Image(systemName: notificationIcon)
                .font(.title2)
                .foregroundColor(notificationColor)
                .frame(width: 30)
            
            // Notification Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text(notification.scheduledAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .achievement:
            return "trophy.circle.fill"
        case .milestone:
            return "star.circle.fill"
        case .featureUnlock:
            return "lock.open.fill"
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .achievement:
            return .gold
        case .milestone:
            return .blue
        case .featureUnlock:
            return .green
        }
    }
}

struct ReputationNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        ReputationNotificationView(
            notification: ReputationNotification(
                id: UUID(),
                type: .achievement,
                title: "Achievement Unlocked!",
                message: "You've earned the First Post achievement.",
                scheduledAt: Date()
            ),
            onDismiss: {}
        )
        .padding()
    }
}