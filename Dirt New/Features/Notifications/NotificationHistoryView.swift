import SwiftUI

struct NotificationHistoryView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedCategory: NotificationCategory? = nil
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter controls
                filterControls
                
                // History content
                if filteredNotifications.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("Notification History")
            
            .toolbar {
                ToolbarItem(placement: .trailing) {
                    Menu {
                        Button("Export History") {
                            exportHistory()
                        }
                        
                        Button("Clear History", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Clear History", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("This will permanently delete all notification history. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search notifications...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        VStack(spacing: 12) {
            // Time range filter
            timeRangeFilter
            
            // Category filter
            categoryFilter
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var timeRangeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    FilterChip(
                        title: range.displayName,
                        count: getNotificationCount(for: range),
                        isSelected: selectedTimeRange == range
                    ) {
                        selectedTimeRange = range
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All Categories",
                    count: getNotificationCount(for: selectedTimeRange),
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(NotificationCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        count: getNotificationCount(for: selectedTimeRange, category: category),
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        List {
            // Statistics section
            Section {
                statisticsView
            }
            
            // Notifications grouped by date
            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(groupedNotifications[date] ?? []) { notification in
                        NotificationHistoryRow(
                            notification: notification,
                            onTap: {
                                handleNotificationTap(notification)
                            },
                            onDelete: {
                                deleteNotification(notification)
                            }
                        )
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Statistics View
    
    private var statisticsView: some View {
        VStack(spacing: 12) {
            HStack {
                StatisticCard(
                    title: "Total",
                    value: "\(filteredNotifications.count)",
                    icon: "bell",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Read",
                    value: "\(filteredNotifications.filter { $0.isRead }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatisticCard(
                    title: "Unread",
                    value: "\(filteredNotifications.filter { !$0.isRead }.count)",
                    icon: "circle",
                    color: .orange
                )
            }
            
            HStack {
                StatisticCard(
                    title: "Interactions",
                    value: "\(filteredNotifications.filter { $0.type.category == .interaction }.count)",
                    icon: "person.2",
                    color: .purple
                )
                
                StatisticCard(
                    title: "Milestones",
                    value: "\(filteredNotifications.filter { $0.type.category == .milestone }.count)",
                    icon: "star",
                    color: .yellow
                )
                
                StatisticCard(
                    title: "Achievements",
                    value: "\(filteredNotifications.filter { $0.type.category == .achievement }.count)",
                    icon: "trophy",
                    color: .green
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No History Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Clear Filters") {
                clearFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredNotifications: [DirtNotification] {
        var notifications = pushNotificationService.notifications
        
        // Filter by time range
        let timeRangeDate = selectedTimeRange.startDate
        notifications = notifications.filter { $0.createdAt >= timeRangeDate }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            notifications = notifications.filter { $0.type.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            notifications = notifications.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.message.localizedCaseInsensitiveContains(searchText) ||
                notification.type.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return notifications.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var groupedNotifications: [String: [DirtNotification]] {
        Dictionary(grouping: filteredNotifications) { notification in
            DateFormatter.dayFormatter.string(from: notification.createdAt)
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No notifications match your search criteria."
        } else if selectedCategory != nil {
            return "No notifications found in the selected category and time range."
        } else {
            return "No notifications found in the selected time range."
        }
    }
    
    // MARK: - Helper Methods
    
    private func getNotificationCount(for timeRange: TimeRange, category: NotificationCategory? = nil) -> Int {
        var notifications = pushNotificationService.notifications.filter { $0.createdAt >= timeRange.startDate }
        
        if let category = category {
            notifications = notifications.filter { $0.type.category == category }
        }
        
        return notifications.count
    }
    
    private func sectionHeader(for dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(groupedNotifications[dateString]?.count ?? 0)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    private func handleNotificationTap(_ notification: DirtNotification) {
        // Mark as read if not already
        if !notification.isRead {
            pushNotificationService.markAsRead(notification.id)
        }
        
        // Handle deep link if available
        if let deepLinkPath = notification.data?.deepLinkPath {
            handleDeepLink(deepLinkPath)
        }
    }
    
    private func deleteNotification(_ notification: DirtNotification) {
        pushNotificationService.deleteNotification(notification.id)
    }
    
    private func clearHistory() {
        pushNotificationService.clearAllNotifications()
    }
    
    private func clearFilters() {
        selectedTimeRange = .week
        selectedCategory = nil
        searchText = ""
    }
    
    private func exportHistory() {
        // In a real app, this would export the notification history
        print("Exporting notification history...")
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
    }
}

// MARK: - Notification History Row

struct NotificationHistoryRow: View {
    let notification: DirtNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                notificationIcon
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title and time
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(notification.isRead ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(notification.createdAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Message
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Status indicators
                    HStack {
                        Label(notification.type.displayName, systemImage: notification.type.iconName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if notification.isDelivered {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        if notification.isRead {
                            Image(systemName: "eye.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 32, height: 32)
            
            Image(systemName: notification.type.iconName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(iconForegroundColor)
        }
    }
    
    private var iconBackgroundColor: Color {
        switch notification.type.category {
        case .interaction:
            return .blue.opacity(0.2)
        case .milestone:
            return .orange.opacity(0.2)
        case .achievement:
            return .green.opacity(0.2)
        case .community:
            return .purple.opacity(0.2)
        }
    }
    
    private var iconForegroundColor: Color {
        switch notification.type.category {
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
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Time Range

enum TimeRange: CaseIterable {
    case day
    case week
    case month
    case quarter
    case year
    case all
    
    var displayName: String {
        switch self {
        case .day:
            return "Today"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .quarter:
            return "3 Months"
        case .year:
            return "This Year"
        case .all:
            return "All Time"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .all:
            return Date.distantPast
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

struct NotificationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationHistoryView()
    }
}