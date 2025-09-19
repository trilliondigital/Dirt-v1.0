import SwiftUI

struct NotificationCenterView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    
    @State private var selectedTab: NotificationTab = .activity
    @State private var showingSettings = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                notificationTabSelector
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .activity:
                        activityFeedView
                    case .announcements:
                        announcementsView
                    case .settings:
                        notificationSettingsView
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Mark All as Read") {
                            Task {
                                await notificationManager.markAllAsRead()
                            }
                        }
                        
                        Button("Clear All") {
                            Task {
                                await notificationManager.clearAllNotifications()
                            }
                        }
                        
                        Divider()
                        
                        Button("Settings") {
                            selectedTab = .settings
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationManager.totalUnreadCount > 0 {
                        Badge(count: notificationManager.totalUnreadCount)
                    }
                }
            }
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
        }
    }
    
    // MARK: - Tab Selector
    
    private var notificationTabSelector: some View {
        GlassCard(material: MaterialDesignSystem.Glass.ultraThin, padding: UISpacing.xs) {
            Picker("Notification Type", selection: $selectedTab) {
                ForEach(NotificationTab.allCases, id: \.self) { tab in
                    HStack {
                        Image(systemName: tab.iconName)
                        Text(tab.displayName)
                        
                        if tab == .activity && pushNotificationService.unreadCount > 0 {
                            Badge(count: pushNotificationService.unreadCount)
                        } else if tab == .announcements && communityAnnouncementService.unreadAnnouncementCount > 0 {
                            Badge(count: communityAnnouncementService.unreadAnnouncementCount)
                        }
                    }
                    .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
        .padding(.top, UISpacing.sm)
    }
    
    // MARK: - Activity Feed View
    
    private var activityFeedView: some View {
        VStack(spacing: 0) {
            // Search bar
            if !pushNotificationService.notifications.isEmpty {
                SearchBar(text: $searchText, placeholder: "Search notifications...")
                    .padding(.horizontal)
                    .padding(.top, UISpacing.sm)
            }
            
            if filteredNotifications.isEmpty {
                emptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    message: "You're all caught up! New notifications will appear here."
                )
            } else {
                List {
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
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    // Refresh notifications
                    await refreshNotifications()
                }
            }
        }
    }
    
    // MARK: - Announcements View
    
    private var announcementsView: some View {
        VStack(spacing: 0) {
            if communityAnnouncementService.getActiveAnnouncements().isEmpty {
                emptyStateView(
                    icon: "megaphone.slash",
                    title: "No Announcements",
                    message: "Community announcements will appear here."
                )
            } else {
                List {
                    ForEach(communityAnnouncementService.getActiveAnnouncements()) { announcement in
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
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    // Refresh announcements
                    await refreshAnnouncements()
                }
            }
        }
    }
    
    // MARK: - Settings View
    
    private var notificationSettingsView: some View {
        NotificationSettingsView()
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: UISpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(UIColors.secondaryLabel)
            
            VStack(spacing: UISpacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(UIColors.label)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(UIColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UISpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaterialDesignSystem.Context.background)
    }
    
    // MARK: - Computed Properties
    
    private var filteredNotifications: [DirtNotification] {
        let notifications = pushNotificationService.notifications
        
        if searchText.isEmpty {
            return notifications
        } else {
            return notifications.filter { notification in
                notification.title.localizedCaseInsensitiveContains(searchText) ||
                notification.message.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleNotificationTap(_ notification: DirtNotification) {
        // Mark as read
        pushNotificationService.markAsRead(notification.id)
        
        // Handle deep linking
        if let deepLinkPath = notification.data?.deepLinkPath {
            handleDeepLink(deepLinkPath)
        }
    }
    
    private func handleAnnouncementTap(_ announcement: CommunityAnnouncement) {
        // Mark as read
        communityAnnouncementService.markAnnouncementAsRead(announcement.id)
        
        // Handle action button
        if let action = announcement.actionButton {
            handleDeepLink(action.deepLink)
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
        
        // Example implementation:
        // NotificationCenter.default.post(
        //     name: .deepLinkReceived,
        //     object: nil,
        //     userInfo: ["path": path]
        // )
    }
    
    private func refreshNotifications() async {
        // In a real app, this would fetch new notifications from the server
        await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
    }
    
    private func refreshAnnouncements() async {
        // In a real app, this would fetch new announcements from the server
        await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
    }
}

// MARK: - Notification Tab

enum NotificationTab: String, CaseIterable {
    case activity = "activity"
    case announcements = "announcements"
    case settings = "settings"
    
    var displayName: String {
        switch self {
        case .activity:
            return "Activity"
        case .announcements:
            return "Announcements"
        case .settings:
            return "Settings"
        }
    }
    
    var iconName: String {
        switch self {
        case .activity:
            return "bell"
        case .announcements:
            return "megaphone"
        case .settings:
            return "gear"
        }
    }
}

// MARK: - Badge View

struct Badge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(count > 99 ? "99+" : "\(count)")")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? 6 : 4)
                .padding(.vertical, 2)
                .background(Color.red)
                .clipShape(Capsule())
                .scaleEffect(count > 0 ? 1.0 : 0.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(UIColors.secondaryLabel)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(UIColors.accentPrimary)
            }
        }
        .padding(.horizontal, UISpacing.md)
        .padding(.vertical, UISpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MaterialDesignSystem.Glass.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}