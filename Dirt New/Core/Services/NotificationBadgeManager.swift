import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Combine

@MainActor
class NotificationBadgeManager: ObservableObject {
    static let shared = NotificationBadgeManager()
    
    @Published var totalBadgeCount: Int = 0
    @Published var categoryBadgeCounts: [NotificationCategory: Int] = [:]
    @Published var typeBadgeCounts: [NotificationType: Int] = [:]
    
    private let pushNotificationService = PushNotificationService.shared
    private let communityAnnouncementService = CommunityAnnouncementService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
        updateBadgeCounts()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe push notification changes
        pushNotificationService.$notifications
            .combineLatest(communityAnnouncementService.$announcements)
            .sink { [weak self] _, _ in
                self?.updateBadgeCounts()
            }
            .store(in: &cancellables)
        
        // Observe preference changes
        pushNotificationService.$preferences
            .sink { [weak self] _ in
                self?.updateAppBadge()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Badge Count Management
    
    private func updateBadgeCounts() {
        let unreadNotifications = pushNotificationService.notifications.filter { !$0.isRead }
        let unreadAnnouncements = communityAnnouncementService.getUnreadAnnouncements()
        
        // Update total count
        totalBadgeCount = unreadNotifications.count + unreadAnnouncements.count
        
        // Update category counts
        var categoryCounts: [NotificationCategory: Int] = [:]
        for category in NotificationCategory.allCases {
            let categoryCount = unreadNotifications.filter { $0.type.category == category }.count
            categoryCounts[category] = categoryCount
        }
        
        // Add community announcements to community category
        categoryCounts[.community, default: 0] += unreadAnnouncements.count
        
        categoryBadgeCounts = categoryCounts
        
        // Update type counts
        var typeCounts: [NotificationType: Int] = [:]
        for type in NotificationType.allCases {
            let typeCount = unreadNotifications.filter { $0.type == type }.count
            typeCounts[type] = typeCount
        }
        
        typeBadgeCounts = typeCounts
        
        // Update app badge
        updateAppBadge()
    }
    
    private func updateAppBadge() {
        let preferences = pushNotificationService.preferences
        
        #if canImport(UIKit)
        if preferences.badgeEnabled && preferences.isEnabled {
            UIApplication.shared.applicationIconBadgeNumber = totalBadgeCount
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        #endif
    }
    
    // MARK: - Badge Count Getters
    
    func getBadgeCount(for category: NotificationCategory) -> Int {
        return categoryBadgeCounts[category] ?? 0
    }
    
    func getBadgeCount(for type: NotificationType) -> Int {
        return typeBadgeCounts[type] ?? 0
    }
    
    func getUnreadCount(for categories: [NotificationCategory]) -> Int {
        return categories.reduce(0) { total, category in
            total + getBadgeCount(for: category)
        }
    }
    
    func getUnreadCount(for types: [NotificationType]) -> Int {
        return types.reduce(0) { total, type in
            total + getBadgeCount(for: type)
        }
    }
    
    // MARK: - Badge Display Helpers
    
    func shouldShowBadge(for category: NotificationCategory) -> Bool {
        let preferences = pushNotificationService.preferences
        return preferences.isEnabled && 
               preferences.isCategoryEnabled(category) && 
               getBadgeCount(for: category) > 0
    }
    
    func shouldShowBadge(for type: NotificationType) -> Bool {
        let preferences = pushNotificationService.preferences
        return preferences.isEnabled && 
               preferences.isTypeEnabled(type) && 
               getBadgeCount(for: type) > 0
    }
    
    func getBadgeText(for count: Int, maxCount: Int = 99) -> String {
        if count > maxCount {
            return "\(maxCount)+"
        }
        return "\(count)"
    }
    
    // MARK: - Badge Actions
    
    func clearBadge(for category: NotificationCategory) {
        let notificationsToMark = pushNotificationService.notifications.filter { 
            !$0.isRead && $0.type.category == category 
        }
        
        for notification in notificationsToMark {
            pushNotificationService.markAsRead(notification.id)
        }
        
        if category == .community {
            communityAnnouncementService.markAllAnnouncementsAsRead()
        }
    }
    
    func clearBadge(for type: NotificationType) {
        let notificationsToMark = pushNotificationService.notifications.filter { 
            !$0.isRead && $0.type == type 
        }
        
        for notification in notificationsToMark {
            pushNotificationService.markAsRead(notification.id)
        }
    }
    
    func clearAllBadges() {
        pushNotificationService.markAllAsRead()
        communityAnnouncementService.markAllAnnouncementsAsRead()
    }
    
    // MARK: - Smart Badge Management
    
    func getSmartBadgeCount() -> Int {
        let preferences = pushNotificationService.preferences
        
        // If notifications are disabled, return 0
        guard preferences.isEnabled else { return 0 }
        
        // Count only enabled categories
        var count = 0
        for category in NotificationCategory.allCases {
            if preferences.isCategoryEnabled(category) {
                count += getBadgeCount(for: category)
            }
        }
        
        return count
    }
    
    func getPriorityBadgeCount() -> Int {
        let unreadNotifications = pushNotificationService.notifications.filter { !$0.isRead }
        let highPriorityCount = unreadNotifications.filter { 
            $0.type.priority == .high || $0.type.priority == .urgent 
        }.count
        
        let urgentAnnouncements = communityAnnouncementService.getUnreadAnnouncements().filter {
            $0.priority == .high || $0.priority == .urgent
        }.count
        
        return highPriorityCount + urgentAnnouncements
    }
    
    // MARK: - Badge Animation Support
    
    func animateBadgeUpdate(for category: NotificationCategory) {
        // This could trigger haptic feedback or animations
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
    
    func animateBadgeIncrease() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
    
    func animateBadgeDecrease() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}

// MARK: - Badge View Components

struct NotificationBadge: View {
    let count: Int
    let maxCount: Int
    let showCount: Bool
    let size: BadgeSize
    let style: BadgeStyle
    
    init(
        count: Int,
        maxCount: Int = 99,
        showCount: Bool = true,
        size: BadgeSize = .medium,
        style: BadgeStyle = .red
    ) {
        self.count = count
        self.maxCount = maxCount
        self.showCount = showCount
        self.size = size
        self.style = style
    }
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(style.backgroundColor)
                    .frame(width: badgeSize, height: badgeSize)
                
                if showCount {
                    Text(displayText)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(style.textColor)
                        .minimumScaleFactor(0.8)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: count)
        }
    }
    
    private var displayText: String {
        if count > maxCount {
            return "\(maxCount)+"
        }
        return "\(count)"
    }
    
    private var badgeSize: CGFloat {
        if !showCount {
            return size.dotSize
        }
        
        switch size {
        case .small:
            return count > 9 ? 18 : 14
        case .medium:
            return count > 9 ? 20 : 16
        case .large:
            return count > 9 ? 24 : 20
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small:
            return count > 9 ? 9 : 10
        case .medium:
            return count > 9 ? 10 : 11
        case .large:
            return count > 9 ? 11 : 12
        }
    }
}

struct CategoryBadge: View {
    let category: NotificationCategory
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    var body: some View {
        NotificationBadge(
            count: badgeManager.getBadgeCount(for: category),
            style: .category(category)
        )
    }
}

struct TypeBadge: View {
    let type: NotificationType
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    var body: some View {
        NotificationBadge(
            count: badgeManager.getBadgeCount(for: type),
            size: .small,
            style: .type(type)
        )
    }
}

// MARK: - Badge Enums

enum BadgeSize {
    case small
    case medium
    case large
    
    var dotSize: CGFloat {
        switch self {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        }
    }
}

enum BadgeStyle {
    case red
    case blue
    case green
    case orange
    case purple
    case category(NotificationCategory)
    case type(NotificationType)
    
    var backgroundColor: Color {
        switch self {
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .category(let category):
            switch category {
            case .interaction:
                return .blue
            case .milestone:
                return .orange
            case .achievement:
                return .green
            case .community:
                return .purple
            }
        case .type(let type):
            return type.category.badgeColor
        }
    }
    
    var textColor: Color {
        return .white
    }
}

// MARK: - Extensions

extension NotificationCategory {
    var badgeColor: Color {
        switch self {
        case .interaction:
            return .blue
        case .milestone:
            return .orange
        case .achievement:
            return .green
        case .community:
            return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .interaction:
            return "person.2"
        case .milestone:
            return "flag"
        case .achievement:
            return "trophy"
        case .community:
            return "globe"
        }
    }
}

extension NotificationType {
    var badgeColor: Color {
        return category.badgeColor
    }
}