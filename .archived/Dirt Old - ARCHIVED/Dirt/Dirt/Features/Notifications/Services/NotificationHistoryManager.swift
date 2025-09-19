import Foundation
import SwiftUI

// MARK: - Notification History Manager

@MainActor
class NotificationHistoryManager: ObservableObject {
    static let shared = NotificationHistoryManager()
    
    @Published var notificationHistory: [NotificationHistoryEntry] = []
    @Published var analytics: NotificationAnalytics = NotificationAnalytics()
    
    private let userDefaults = UserDefaults.standard
    private let maxHistoryEntries = 1000
    
    init() {
        loadNotificationHistory()
        calculateAnalytics()
    }
    
    // MARK: - History Management
    
    func recordNotification(_ notification: DirtNotification, action: NotificationAction) {
        let entry = NotificationHistoryEntry(
            notificationId: notification.id,
            userId: notification.userId,
            type: notification.type,
            action: action,
            timestamp: Date(),
            title: notification.title,
            message: notification.message
        )
        
        notificationHistory.insert(entry, at: 0)
        
        // Keep only recent entries
        if notificationHistory.count > maxHistoryEntries {
            notificationHistory = Array(notificationHistory.prefix(maxHistoryEntries))
        }
        
        saveNotificationHistory()
        calculateAnalytics()
    }
    
    func recordNotificationDelivered(_ notification: DirtNotification) {
        recordNotification(notification, action: .delivered)
    }
    
    func recordNotificationOpened(_ notification: DirtNotification) {
        recordNotification(notification, action: .opened)
    }
    
    func recordNotificationDismissed(_ notification: DirtNotification) {
        recordNotification(notification, action: .dismissed)
    }
    
    func recordNotificationInteracted(_ notification: DirtNotification) {
        recordNotification(notification, action: .interacted)
    }
    
    // MARK: - Analytics
    
    private func calculateAnalytics() {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate time-based metrics
        let last24Hours = calendar.date(byAdding: .hour, value: -24, to: now) ?? now
        let last7Days = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let last30Days = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        let recent24h = notificationHistory.filter { $0.timestamp >= last24Hours }
        let recent7d = notificationHistory.filter { $0.timestamp >= last7Days }
        let recent30d = notificationHistory.filter { $0.timestamp >= last30Days }
        
        // Calculate delivery metrics
        analytics.totalNotifications = notificationHistory.count
        analytics.notificationsLast24h = recent24h.count
        analytics.notificationsLast7d = recent7d.count
        analytics.notificationsLast30d = recent30d.count
        
        // Calculate engagement metrics
        let deliveredCount = notificationHistory.filter { $0.action == .delivered }.count
        let openedCount = notificationHistory.filter { $0.action == .opened }.count
        let interactedCount = notificationHistory.filter { $0.action == .interacted }.count
        
        analytics.openRate = deliveredCount > 0 ? Double(openedCount) / Double(deliveredCount) : 0.0
        analytics.interactionRate = deliveredCount > 0 ? Double(interactedCount) / Double(deliveredCount) : 0.0
        
        // Calculate type distribution
        analytics.typeDistribution = Dictionary(grouping: notificationHistory, by: { $0.type })
            .mapValues { $0.count }
        
        // Calculate peak hours
        analytics.peakHours = calculatePeakHours()
        
        // Calculate engagement by type
        analytics.engagementByType = calculateEngagementByType()
    }
    
    private func calculatePeakHours() -> [Int: Int] {
        let calendar = Calendar.current
        let hourCounts = Dictionary(grouping: notificationHistory) { entry in
            calendar.component(.hour, from: entry.timestamp)
        }.mapValues { $0.count }
        
        return hourCounts
    }
    
    private func calculateEngagementByType() -> [NotificationType: Double] {
        var engagementByType: [NotificationType: Double] = [:]
        
        for type in NotificationType.allCases {
            let typeNotifications = notificationHistory.filter { $0.type == type }
            let deliveredCount = typeNotifications.filter { $0.action == .delivered }.count
            let openedCount = typeNotifications.filter { $0.action == .opened }.count
            
            if deliveredCount > 0 {
                engagementByType[type] = Double(openedCount) / Double(deliveredCount)
            } else {
                engagementByType[type] = 0.0
            }
        }
        
        return engagementByType
    }
    
    // MARK: - Filtering and Querying
    
    func getNotificationHistory(
        for type: NotificationType? = nil,
        action: NotificationAction? = nil,
        since: Date? = nil,
        limit: Int? = nil
    ) -> [NotificationHistoryEntry] {
        var filtered = notificationHistory
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let action = action {
            filtered = filtered.filter { $0.action == action }
        }
        
        if let since = since {
            filtered = filtered.filter { $0.timestamp >= since }
        }
        
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }
        
        return filtered
    }
    
    func getNotificationCount(for type: NotificationType, since: Date) -> Int {
        return notificationHistory.filter { entry in
            entry.type == type && entry.timestamp >= since
        }.count
    }
    
    func getMostEngagingNotificationTypes(limit: Int = 5) -> [(NotificationType, Double)] {
        return analytics.engagementByType
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    func getLeastEngagingNotificationTypes(limit: Int = 5) -> [(NotificationType, Double)] {
        return analytics.engagementByType
            .sorted { $0.value < $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    // MARK: - Recommendations
    
    func getNotificationRecommendations() -> [NotificationRecommendation] {
        var recommendations: [NotificationRecommendation] = []
        
        // Check for low engagement types
        let lowEngagementTypes = getLeastEngagingNotificationTypes(limit: 3)
        for (type, rate) in lowEngagementTypes {
            if rate < 0.1 && analytics.typeDistribution[type, default: 0] > 10 {
                recommendations.append(
                    NotificationRecommendation(
                        type: .disableType,
                        title: "Consider disabling \(type.displayName) notifications",
                        description: "You rarely engage with these notifications (\(Int(rate * 100))% open rate)",
                        notificationType: type
                    )
                )
            }
        }
        
        // Check for quiet hours optimization
        if let peakHour = analytics.peakHours.max(by: { $0.value < $1.value })?.key {
            let quietHoursStart = (peakHour + 12) % 24 // Opposite of peak hour
            recommendations.append(
                NotificationRecommendation(
                    type: .optimizeQuietHours,
                    title: "Optimize quiet hours",
                    description: "Most of your notifications arrive at \(peakHour):00. Consider setting quiet hours from \(quietHoursStart):00.",
                    suggestedQuietHoursStart: quietHoursStart
                )
            )
        }
        
        // Check for notification frequency
        if analytics.notificationsLast24h > 20 {
            recommendations.append(
                NotificationRecommendation(
                    type: .reduceFrequency,
                    title: "High notification frequency",
                    description: "You received \(analytics.notificationsLast24h) notifications in the last 24 hours. Consider adjusting your preferences.",
                    currentFrequency: analytics.notificationsLast24h
                )
            )
        }
        
        return recommendations
    }
    
    // MARK: - Export and Cleanup
    
    func exportNotificationHistory() -> Data? {
        let exportData = NotificationHistoryExport(
            exportDate: Date(),
            totalEntries: notificationHistory.count,
            entries: notificationHistory,
            analytics: analytics
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func clearOldHistory(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let originalCount = notificationHistory.count
        notificationHistory = notificationHistory.filter { $0.timestamp >= cutoffDate }
        
        let removedCount = originalCount - notificationHistory.count
        
        if removedCount > 0 {
            saveNotificationHistory()
            calculateAnalytics()
            print("Removed \(removedCount) old notification history entries")
        }
    }
    
    func clearAllHistory() {
        notificationHistory.removeAll()
        analytics = NotificationAnalytics()
        saveNotificationHistory()
    }
    
    // MARK: - Persistence
    
    private func saveNotificationHistory() {
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            userDefaults.set(encoded, forKey: "notificationHistory")
        }
    }
    
    private func loadNotificationHistory() {
        if let data = userDefaults.data(forKey: "notificationHistory"),
           let history = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) {
            notificationHistory = history
        }
    }
}

// MARK: - Notification History Entry

struct NotificationHistoryEntry: Identifiable, Codable {
    let id: UUID
    let notificationId: UUID
    let userId: UUID
    let type: NotificationType
    let action: NotificationAction
    let timestamp: Date
    let title: String
    let message: String
    
    init(
        id: UUID = UUID(),
        notificationId: UUID,
        userId: UUID,
        type: NotificationType,
        action: NotificationAction,
        timestamp: Date,
        title: String,
        message: String
    ) {
        self.id = id
        self.notificationId = notificationId
        self.userId = userId
        self.type = type
        self.action = action
        self.timestamp = timestamp
        self.title = title
        self.message = message
    }
}

// MARK: - Notification Action

enum NotificationAction: String, CaseIterable, Codable {
    case delivered = "delivered"
    case opened = "opened"
    case dismissed = "dismissed"
    case interacted = "interacted"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .delivered:
            return "Delivered"
        case .opened:
            return "Opened"
        case .dismissed:
            return "Dismissed"
        case .interacted:
            return "Interacted"
        case .expired:
            return "Expired"
        }
    }
}

// MARK: - Notification Analytics

struct NotificationAnalytics: Codable {
    var totalNotifications: Int = 0
    var notificationsLast24h: Int = 0
    var notificationsLast7d: Int = 0
    var notificationsLast30d: Int = 0
    var openRate: Double = 0.0
    var interactionRate: Double = 0.0
    var typeDistribution: [NotificationType: Int] = [:]
    var peakHours: [Int: Int] = [:]
    var engagementByType: [NotificationType: Double] = [:]
}

// MARK: - Notification Recommendation

struct NotificationRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let notificationType: NotificationType?
    let suggestedQuietHoursStart: Int?
    let currentFrequency: Int?
    
    init(
        type: RecommendationType,
        title: String,
        description: String,
        notificationType: NotificationType? = nil,
        suggestedQuietHoursStart: Int? = nil,
        currentFrequency: Int? = nil
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.notificationType = notificationType
        self.suggestedQuietHoursStart = suggestedQuietHoursStart
        self.currentFrequency = currentFrequency
    }
}

enum RecommendationType: String, CaseIterable {
    case disableType = "disable_type"
    case optimizeQuietHours = "optimize_quiet_hours"
    case reduceFrequency = "reduce_frequency"
    case enableType = "enable_type"
    
    var iconName: String {
        switch self {
        case .disableType:
            return "bell.slash"
        case .optimizeQuietHours:
            return "moon"
        case .reduceFrequency:
            return "minus.circle"
        case .enableType:
            return "bell"
        }
    }
}

// MARK: - Notification History Export

struct NotificationHistoryExport: Codable {
    let exportDate: Date
    let totalEntries: Int
    let entries: [NotificationHistoryEntry]
    let analytics: NotificationAnalytics
}