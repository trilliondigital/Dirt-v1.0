import SwiftUI

struct ActivityFeedView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    @State private var selectedTimeframe: ActivityTimeframe = .today
    @State private var selectedActivityType: ActivityType? = nil
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Activity summary header
                activitySummaryHeader
                
                // Filter controls
                filterControls
                
                // Activity timeline
                if groupedActivities.isEmpty {
                    emptyActivityState
                } else {
                    activityTimeline
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ActivityFiltersView(
                    selectedTimeframe: $selectedTimeframe,
                    selectedActivityType: $selectedActivityType
                )
            }
        }
    }
    
    // MARK: - Activity Summary Header
    
    private var activitySummaryHeader: some View {
        VStack(spacing: 12) {
            // Total activity count
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(filteredActivities.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(selectedTimeframe.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(Date(), style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Activity type breakdown
            activityTypeBreakdown
        }
        .padding(16)
        .background(Color(.systemGray6))
    }
    
    private var activityTypeBreakdown: some View {
        HStack(spacing: 12) {
            ForEach(ActivityType.allCases, id: \.self) { type in
                let count = getActivityCount(for: type)
                
                VStack(spacing: 4) {
                    Image(systemName: type.iconName)
                        .font(.caption)
                        .foregroundColor(type.color)
                    
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(type.shortName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedActivityType == type ? type.color.opacity(0.2) : Color.clear)
                )
                .onTapGesture {
                    selectedActivityType = selectedActivityType == type ? nil : type
                }
            }
        }
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityTimeframe.allCases, id: \.self) { timeframe in
                    FilterChip(
                        title: timeframe.displayName,
                        count: getActivityCount(for: timeframe),
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        selectedTimeframe = timeframe
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Activity Timeline
    
    private var activityTimeline: some View {
        List {
            ForEach(groupedActivities.keys.sorted(by: >), id: \.self) { dateString in
                Section(header: timelineSectionHeader(for: dateString)) {
                    ForEach(groupedActivities[dateString] ?? []) { activity in
                        ActivityTimelineRow(
                            activity: activity,
                            onTap: {
                                handleActivityTap(activity)
                            }
                        )
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await refreshActivities()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyActivityState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Activity")
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
    
    private var filteredActivities: [ActivityItem] {
        var activities = allActivities
        
        // Filter by timeframe
        let startDate = selectedTimeframe.startDate
        activities = activities.filter { $0.timestamp >= startDate }
        
        // Filter by activity type
        if let selectedType = selectedActivityType {
            activities = activities.filter { $0.type == selectedType }
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var allActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add notifications as activities
        for notification in pushNotificationService.notifications {
            activities.append(ActivityItem(
                id: notification.id,
                type: .notification,
                title: notification.title,
                description: notification.message,
                timestamp: notification.createdAt,
                isRead: notification.isRead,
                metadata: ActivityMetadata(
                    notificationType: notification.type,
                    deepLinkPath: notification.data?.deepLinkPath
                )
            ))
        }
        
        // Add announcements as activities
        for announcement in communityAnnouncementService.announcements {
            activities.append(ActivityItem(
                id: announcement.id,
                type: .announcement,
                title: announcement.title,
                description: announcement.message,
                timestamp: announcement.createdAt,
                isRead: announcement.isRead,
                metadata: ActivityMetadata(
                    announcementType: announcement.type,
                    priority: announcement.priority,
                    deepLinkPath: announcement.actionURL
                )
            ))
        }
        
        return activities
    }
    
    private var groupedActivities: [String: [ActivityItem]] {
        Dictionary(grouping: filteredActivities) { activity in
            DateFormatter.activityDateFormatter.string(from: activity.timestamp)
        }
    }
    
    private var emptyStateMessage: String {
        if selectedActivityType != nil {
            return "No \(selectedActivityType?.displayName.lowercased() ?? "activity") found for the selected timeframe."
        } else {
            return "No activity found for the selected timeframe."
        }
    }
    
    // MARK: - Helper Methods
    
    private func getActivityCount(for type: ActivityType) -> Int {
        return filteredActivities.filter { $0.type == type }.count
    }
    
    private func getActivityCount(for timeframe: ActivityTimeframe) -> Int {
        let startDate = timeframe.startDate
        return allActivities.filter { $0.timestamp >= startDate }.count
    }
    
    private func timelineSectionHeader(for dateString: String) -> some View {
        HStack {
            Text(dateString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(groupedActivities[dateString]?.count ?? 0) items")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }
    
    private func handleActivityTap(_ activity: ActivityItem) {
        // Mark as read if not already
        if !activity.isRead {
            if activity.type == .notification {
                pushNotificationService.markAsRead(activity.id)
            } else if activity.type == .announcement {
                communityAnnouncementService.markAnnouncementAsRead(activity.id)
            }
        }
        
        // Handle deep link if available
        if let deepLinkPath = activity.metadata.deepLinkPath {
            handleDeepLink(deepLinkPath)
        }
    }
    
    private func clearFilters() {
        selectedTimeframe = .today
        selectedActivityType = nil
    }
    
    private func refreshActivities() async {
        // In a real app, this would refresh data from the server
        await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
    }
}

// MARK: - Activity Timeline Row

struct ActivityTimelineRow: View {
    let activity: ActivityItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Timeline indicator
                VStack {
                    Circle()
                        .fill(activity.type.color)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 12)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Header
                    HStack {
                        Image(systemName: activity.type.iconName)
                            .font(.caption)
                            .foregroundColor(activity.type.color)
                        
                        Text(activity.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(activity.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if !activity.isRead {
                            Circle()
                                .fill(activity.type.color)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    // Title
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(activity.isRead ? .regular : .semibold)
                        .foregroundColor(activity.isRead ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata
                    if let metadata = activity.metadata {
                        activityMetadataView(metadata)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func activityMetadataView(_ metadata: ActivityMetadata) -> some View {
        HStack {
            if let notificationType = metadata.notificationType {
                Label(notificationType.displayName, systemImage: notificationType.iconName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let announcementType = metadata.announcementType {
                Label(announcementType.displayName, systemImage: announcementType.iconName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let priority = metadata.priority, priority == .high || priority == .urgent {
                Text(priority.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color(priority.color))
                    )
            }
            
            Spacer()
        }
    }
}

// MARK: - Activity Filters View

struct ActivityFiltersView: View {
    @Binding var selectedTimeframe: ActivityTimeframe
    @Binding var selectedActivityType: ActivityType?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Timeframe") {
                    ForEach(ActivityTimeframe.allCases, id: \.self) { timeframe in
                        HStack {
                            Text(timeframe.displayName)
                            
                            Spacer()
                            
                            if selectedTimeframe == timeframe {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTimeframe = timeframe
                        }
                    }
                }
                
                Section("Activity Type") {
                    HStack {
                        Text("All Types")
                        
                        Spacer()
                        
                        if selectedActivityType == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedActivityType = nil
                    }
                    
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.iconName)
                                .foregroundColor(type.color)
                                .frame(width: 20)
                            
                            Text(type.displayName)
                            
                            Spacer()
                            
                            if selectedActivityType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedActivityType = type
                        }
                    }
                }
            }
            .navigationTitle("Activity Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Activity Models

struct ActivityItem: Identifiable, Equatable {
    let id: UUID
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let isRead: Bool
    let metadata: ActivityMetadata
    
    init(
        id: UUID,
        type: ActivityType,
        title: String,
        description: String,
        timestamp: Date,
        isRead: Bool,
        metadata: ActivityMetadata
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.isRead = isRead
        self.metadata = metadata
    }
}

struct ActivityMetadata: Equatable {
    let notificationType: NotificationType?
    let announcementType: AnnouncementType?
    let priority: AnnouncementPriority?
    let deepLinkPath: String?
    
    init(
        notificationType: NotificationType? = nil,
        announcementType: AnnouncementType? = nil,
        priority: AnnouncementPriority? = nil,
        deepLinkPath: String? = nil
    ) {
        self.notificationType = notificationType
        self.announcementType = announcementType
        self.priority = priority
        self.deepLinkPath = deepLinkPath
    }
}

enum ActivityType: CaseIterable {
    case notification
    case announcement
    case interaction
    case milestone
    case achievement
    
    var displayName: String {
        switch self {
        case .notification:
            return "Notification"
        case .announcement:
            return "Announcement"
        case .interaction:
            return "Interaction"
        case .milestone:
            return "Milestone"
        case .achievement:
            return "Achievement"
        }
    }
    
    var shortName: String {
        switch self {
        case .notification:
            return "Notif"
        case .announcement:
            return "News"
        case .interaction:
            return "Social"
        case .milestone:
            return "Goals"
        case .achievement:
            return "Badges"
        }
    }
    
    var iconName: String {
        switch self {
        case .notification:
            return "bell"
        case .announcement:
            return "megaphone"
        case .interaction:
            return "person.2"
        case .milestone:
            return "star"
        case .achievement:
            return "trophy"
        }
    }
    
    var color: Color {
        switch self {
        case .notification:
            return .blue
        case .announcement:
            return .purple
        case .interaction:
            return .green
        case .milestone:
            return .orange
        case .achievement:
            return .yellow
        }
    }
}

enum ActivityTimeframe: CaseIterable {
    case today
    case yesterday
    case week
    case month
    case quarter
    case all
    
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .yesterday:
            return "Yesterday"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .quarter:
            return "3 Months"
        case .all:
            return "All Time"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .yesterday:
            return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) ?? now
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let activityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview

struct ActivityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityFeedView()
    }
}