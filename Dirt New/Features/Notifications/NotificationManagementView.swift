import SwiftUI

struct NotificationManagementView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    @State private var selectedTab: ManagementTab = .overview
    @State private var showingBulkActions = false
    @State private var selectedNotifications: Set<UUID> = []
    @State private var isSelectionMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(ManagementTab.overview)
                    
                    categoriesTab
                        .tag(ManagementTab.categories)
                    
                    bulkActionsTab
                        .tag(ManagementTab.bulkActions)
                    
                    analyticsTab
                        .tag(ManagementTab.analytics)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Manage Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelectionMode ? "Done" : "Select") {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedNotifications.removeAll()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ManagementTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 16))
                        
                        Text(tab.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .background(
                    Rectangle()
                        .fill(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                )
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick stats
                quickStatsSection
                
                // Recent notifications
                recentNotificationsSection
                
                // Quick actions
                quickActionsSection
            }
            .padding(16)
        }
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Total Notifications",
                    value: "\(pushNotificationService.notifications.count)",
                    icon: "bell",
                    color: .blue
                )
                
                StatCard(
                    title: "Unread",
                    value: "\(badgeManager.totalBadgeCount)",
                    icon: "bell.badge",
                    color: .red
                )
                
                StatCard(
                    title: "Today",
                    value: "\(getTodayNotificationCount())",
                    icon: "calendar",
                    color: .green
                )
                
                StatCard(
                    title: "This Week",
                    value: "\(getWeekNotificationCount())",
                    icon: "calendar.badge.clock",
                    color: .orange
                )
            }
        }
    }
    
    private var recentNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Notifications")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink("View All") {
                    NotificationHistoryView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(pushNotificationService.notifications.prefix(5)) { notification in
                    NotificationManagementRow(
                        notification: notification,
                        isSelected: selectedNotifications.contains(notification.id),
                        isSelectionMode: isSelectionMode,
                        onToggleSelection: {
                            toggleSelection(for: notification.id)
                        },
                        onTap: {
                            handleNotificationTap(notification)
                        }
                    )
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Mark All Read",
                    icon: "checkmark.circle",
                    color: .green
                ) {
                    badgeManager.clearAllBadges()
                }
                
                QuickActionCard(
                    title: "Clear All",
                    icon: "trash",
                    color: .red
                ) {
                    pushNotificationService.clearAllNotifications()
                }
                
                QuickActionCard(
                    title: "Settings",
                    icon: "gear",
                    color: .blue
                ) {
                    // Navigate to settings
                }
                
                QuickActionCard(
                    title: "Export",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    exportNotifications()
                }
            }
        }
    }
    
    // MARK: - Categories Tab
    
    private var categoriesTab: some View {
        List {
            ForEach(NotificationCategory.allCases, id: \.self) { category in
                CategoryManagementRow(
                    category: category,
                    unreadCount: badgeManager.getBadgeCount(for: category),
                    totalCount: getCategoryTotalCount(category),
                    isEnabled: pushNotificationService.preferences.isCategoryEnabled(category),
                    onToggle: { enabled in
                        pushNotificationService.toggleNotificationCategory(category, enabled: enabled)
                    },
                    onClearBadge: {
                        badgeManager.clearBadge(for: category)
                    }
                )
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Bulk Actions Tab
    
    private var bulkActionsTab: some View {
        VStack(spacing: 20) {
            if selectedNotifications.isEmpty {
                bulkActionsEmptyState
            } else {
                selectedNotificationsView
                bulkActionButtons
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    private var bulkActionsEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Select Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap 'Select' in the top right to choose notifications for bulk actions.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var selectedNotificationsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Notifications (\(selectedNotifications.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(getSelectedNotifications()) { notification in
                        NotificationManagementRow(
                            notification: notification,
                            isSelected: true,
                            isSelectionMode: true,
                            onToggleSelection: {
                                toggleSelection(for: notification.id)
                            },
                            onTap: {}
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    private var bulkActionButtons: some View {
        VStack(spacing: 12) {
            Button {
                markSelectedAsRead()
            } label: {
                Label("Mark as Read", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedNotifications.isEmpty)
            
            Button {
                deleteSelected()
            } label: {
                Label("Delete Selected", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .disabled(selectedNotifications.isEmpty)
        }
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                notificationTrendsChart
                categoryBreakdownChart
                engagementMetrics
            }
            .padding(16)
        }
    }
    
    private var notificationTrendsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { day in
                    let count = getNotificationCount(for: day)
                    let height = CGFloat(count) * 3 + 20
                    
                    VStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 30, height: height)
                            .cornerRadius(4)
                        
                        Text(getDayLabel(for: day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var categoryBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(NotificationCategory.allCases, id: \.self) { category in
                let count = getCategoryTotalCount(category)
                let percentage = Double(count) / Double(pushNotificationService.notifications.count) * 100
                
                HStack {
                    Image(systemName: category.iconName)
                        .foregroundColor(category.badgeColor)
                        .frame(width: 20)
                    
                    Text(category.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("(\(Int(percentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: percentage, total: 100)
                    .tint(category.badgeColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var engagementMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Engagement Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Read Rate",
                    value: "\(getReadRate())%",
                    icon: "eye",
                    color: .green
                )
                
                MetricCard(
                    title: "Avg. Response Time",
                    value: getAverageResponseTime(),
                    icon: "clock",
                    color: .orange
                )
                
                MetricCard(
                    title: "Most Active Hour",
                    value: getMostActiveHour(),
                    icon: "chart.bar",
                    color: .purple
                )
                
                MetricCard(
                    title: "Weekly Growth",
                    value: "+\(getWeeklyGrowth())%",
                    icon: "arrow.up.right",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelection(for id: UUID) {
        if selectedNotifications.contains(id) {
            selectedNotifications.remove(id)
        } else {
            selectedNotifications.insert(id)
        }
    }
    
    private func getSelectedNotifications() -> [DirtNotification] {
        return pushNotificationService.notifications.filter { selectedNotifications.contains($0.id) }
    }
    
    private func markSelectedAsRead() {
        for id in selectedNotifications {
            pushNotificationService.markAsRead(id)
        }
        selectedNotifications.removeAll()
    }
    
    private func deleteSelected() {
        for id in selectedNotifications {
            pushNotificationService.deleteNotification(id)
        }
        selectedNotifications.removeAll()
    }
    
    private func handleNotificationTap(_ notification: DirtNotification) {
        if !notification.isRead {
            pushNotificationService.markAsRead(notification.id)
        }
    }
    
    private func getTodayNotificationCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return pushNotificationService.notifications.filter { $0.createdAt >= today }.count
    }
    
    private func getWeekNotificationCount() -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return pushNotificationService.notifications.filter { $0.createdAt >= weekAgo }.count
    }
    
    private func getCategoryTotalCount(_ category: NotificationCategory) -> Int {
        return pushNotificationService.notifications.filter { $0.type.category == category }.count
    }
    
    private func getNotificationCount(for daysAgo: Int) -> Int {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        return pushNotificationService.notifications.filter { notification in
            notification.createdAt >= startOfDay && notification.createdAt < endOfDay
        }.count
    }
    
    private func getDayLabel(for daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func getReadRate() -> Int {
        let total = pushNotificationService.notifications.count
        guard total > 0 else { return 0 }
        let read = pushNotificationService.notifications.filter { $0.isRead }.count
        return Int(Double(read) / Double(total) * 100)
    }
    
    private func getAverageResponseTime() -> String {
        // Mock implementation
        return "2.5h"
    }
    
    private func getMostActiveHour() -> String {
        // Mock implementation
        return "2 PM"
    }
    
    private func getWeeklyGrowth() -> Int {
        // Mock implementation
        return 15
    }
    
    private func exportNotifications() {
        // In a real app, this would export notification data
        print("Exporting notifications...")
    }
}

// MARK: - Supporting Views

struct NotificationManagementRow: View {
    let notification: DirtNotification
    let isSelected: Bool
    let isSelectionMode: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Button {
                    onToggleSelection()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
            }
            
            // Notification icon
            Circle()
                .fill(notification.type.category.badgeColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: notification.type.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(notification.type.category.badgeColor)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(notification.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            } else {
                onTap()
            }
        }
    }
}

struct CategoryManagementRow: View {
    let category: NotificationCategory
    let unreadCount: Int
    let totalCount: Int
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    let onClearBadge: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(category.badgeColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: category.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(category.badgeColor)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(totalCount) total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if unreadCount > 0 {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(unreadCount) unread")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: onToggle
                ))
                .labelsHidden()
                
                if unreadCount > 0 {
                    Button("Clear") {
                        onClearBadge()
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Management Tab Enum

enum ManagementTab: CaseIterable {
    case overview
    case categories
    case bulkActions
    case analytics
    
    var displayName: String {
        switch self {
        case .overview:
            return "Overview"
        case .categories:
            return "Categories"
        case .bulkActions:
            return "Bulk Actions"
        case .analytics:
            return "Analytics"
        }
    }
    
    var iconName: String {
        switch self {
        case .overview:
            return "house"
        case .categories:
            return "folder"
        case .bulkActions:
            return "checkmark.circle"
        case .analytics:
            return "chart.bar"
        }
    }
}

// MARK: - Preview

struct NotificationManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationManagementView()
    }
}