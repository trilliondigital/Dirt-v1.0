import SwiftUI

struct NotificationCenterView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    @State private var selectedFilter: NotificationCenterFilter = .all
    @State private var showingSettings = false
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            TabView {
                // Notifications Tab
                VStack(spacing: 0) {
                    // Filter tabs
                    filterTabs
                    
                    // Content
                    if filteredNotifications.isEmpty {
                        emptyState
                    } else {
                        notificationsList
                    }
                }
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .badge(badgeManager.totalBadgeCount > 0 ? badgeManager.totalBadgeCount : 0)
                
                // Activity Feed Tab
                ActivityFeedView()
                    .tabItem {
                        Label("Activity", systemImage: "clock.arrow.circlepath")
                    }
            }
            .navigationTitle("Notifications")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if badgeManager.totalBadgeCount > 0 {
                        Button("Mark All Read") {
                            badgeManager.clearAllBadges()
                        }
                        .font(.caption)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingHistory = true
                        } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        
                        NavigationLink {
                            NotificationManagementView()
                        } label: {
                            Label("Manage", systemImage: "slider.horizontal.3")
                        }
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        ZStack {
                            Image(systemName: "ellipsis.circle")
                            
                            // Badge for settings if there are disabled notifications
                            if !pushNotificationService.preferences.isEnabled {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingHistory) {
                NotificationHistoryView()
            }
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationCenterFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        List {
            // Community announcements (if any)
            if selectedFilter == .all || selectedFilter == .announcements {
                let activeAnnouncements = communityAnnouncementService.getActiveAnnouncements()
                if !activeAnnouncements.isEmpty {
                    Section("Community Announcements") {
                        ForEach(activeAnnouncements.prefix(3)) { announcement in
                            AnnouncementRowView(
                                announcement: announcement,
                                onTap: {
                                    handleAnnouncementTap(announcement)
                                },
                                onMarkAsRead: {
                                    communityAnnouncementService.markAnnouncementAsRead(announcement.id)
                                },
                                onDismiss: {
                                    communityAnnouncementService.dismissAnnouncement(announcement.id)
                                }
                            )
                        }
                        
                        if activeAnnouncements.count > 3 {
                            NavigationLink("View All Announcements") {
                                AnnouncementsListView()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Regular notifications
            Section("Activity") {
                ForEach(filteredNotifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        onTap: {
                            handleNotificationTap(notification)
                        },
                        onMarkAsRead: {
                            pushNotificationService.markAsRead(notification.id)
                        },
                        onDelete: {
                            pushNotificationService.deleteNotification(notification.id)
                        }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // In a real app, this would fetch new notifications
            await refreshNotifications()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if selectedFilter != .all {
                Button("View All Notifications") {
                    selectedFilter = .all
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredNotifications: [DirtNotification] {
        switch selectedFilter {
        case .all:
            return pushNotificationService.notifications
        case .unread:
            return pushNotificationService.notifications.filter { !$0.isRead }
        case .interactions:
            return pushNotificationService.notifications.filter { $0.type.category == .interaction }
        case .milestones:
            return pushNotificationService.notifications.filter { $0.type.category == .milestone }
        case .achievements:
            return pushNotificationService.notifications.filter { $0.type.category == .achievement }
        case .announcements:
            return pushNotificationService.notifications.filter { $0.type.category == .community }
        }
    }
    
    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all:
            return "bell.slash"
        case .unread:
            return "bell.badge"
        case .interactions:
            return "person.2"
        case .milestones:
            return "star"
        case .achievements:
            return "trophy"
        case .announcements:
            return "megaphone"
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return "No Notifications"
        case .unread:
            return "All Caught Up!"
        case .interactions:
            return "No Interactions"
        case .milestones:
            return "No Milestones Yet"
        case .achievements:
            return "No Achievements Yet"
        case .announcements:
            return "No Announcements"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return "When you receive notifications, they'll appear here."
        case .unread:
            return "You've read all your notifications."
        case .interactions:
            return "Replies, upvotes, and mentions will appear here."
        case .milestones:
            return "Reputation and engagement milestones will appear here."
        case .achievements:
            return "Badges and accomplishments will appear here."
        case .announcements:
            return "Community updates and announcements will appear here."
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCountForFilter(_ filter: NotificationCenterFilter) -> Int {
        switch filter {
        case .all:
            return badgeManager.totalBadgeCount
        case .unread:
            return badgeManager.totalBadgeCount
        case .interactions:
            return badgeManager.getBadgeCount(for: .interaction)
        case .milestones:
            return badgeManager.getBadgeCount(for: .milestone)
        case .achievements:
            return badgeManager.getBadgeCount(for: .achievement)
        case .announcements:
            return badgeManager.getBadgeCount(for: .community)
        }
    }
    
    private func handleNotificationTap(_ notification: DirtNotification) {
        pushNotificationService.markAsRead(notification.id)
        
        // Handle deep linking if available
        if let deepLinkPath = notification.data?.deepLinkPath {
            handleDeepLink(deepLinkPath)
        }
    }
    
    private func handleAnnouncementTap(_ announcement: CommunityAnnouncement) {
        communityAnnouncementService.markAnnouncementAsRead(announcement.id)
        
        // Handle action URL if available
        if let actionURL = announcement.actionURL {
            handleDeepLink(actionURL)
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
    }
    
    private func refreshNotifications() async {
        // In a real app, this would fetch new notifications from the server
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
    }
}

// MARK: - Filter Chip
// FilterChip is defined in FeedView.swift to avoid redeclaration

// MARK: - Notification Filter

enum NotificationCenterFilter: CaseIterable {
    case all
    case unread
    case interactions
    case milestones
    case achievements
    case announcements
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .interactions:
            return "Interactions"
        case .milestones:
            return "Milestones"
        case .achievements:
            return "Achievements"
        case .announcements:
            return "Announcements"
        }
    }
}

// MARK: - Preview

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}