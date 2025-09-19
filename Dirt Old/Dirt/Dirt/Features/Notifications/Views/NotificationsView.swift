import SwiftUI

// MARK: - Legacy Notification Model (for backward compatibility)
struct Notification: Identifiable {
    let id = UUID()
    let username: String
    let action: String
    let timeAgo: String
    var isRead: Bool
    let imageName: String?
}

// MARK: - Enhanced Notifications View
struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    
    @State private var selectedTab: Int = 0 // 0 Activity, 1 Keywords, 2 Settings
    @State private var keywordAlerts: [String: Bool] = [
        "ghosting": true,
        "red flag": true,
        "Austin": false
    ]
    @State private var alertsStatus: AlertsService.AuthorizationStatus = .notDetermined
    @State private var showingNotificationCenter = false
    @Environment(\.services) private var services
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enable alerts banner
                if alertsStatus != .authorized {
                    enableAlertsBanner
                }
                
                // Enhanced tab selector with badges
                enhancedTabSelector
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        activityTabContent
                    case 1:
                        keywordAlertsContent
                    case 2:
                        NotificationCenterView()
                    default:
                        activityTabContent
                    }
                }
            }
            .navigationBarTitle("Notifications", displayMode: .inline)
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Notification badge
                        if notificationManager.totalUnreadCount > 0 {
                            NotificationBadgeView(showCount: true, maxCount: 99)
                        }
                        
                        // Menu button
                        Menu {
                            Button("Notification Center") {
                                selectedTab = 2
                            }
                            
                            Button("Mark All as Read") {
                                Task {
                                    await notificationManager.markAllAsRead()
                                }
                            }
                            
                            Button("Settings") {
                                selectedTab = 2
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task {
                alertsStatus = await services.alertsService.currentStatus()
                await notificationManager.initialize()
            }
        }
    }
    
    // MARK: - Enable Alerts Banner
    
    private var enableAlertsBanner: some View {
        GlassCard(material: MaterialDesignSystem.Context.card, padding: UISpacing.md) {
            HStack(alignment: .top, spacing: UISpacing.sm) {
                Image(systemName: "bell.badge")
                    .font(.title3)
                    .foregroundColor(UIColors.accentPrimary)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: UISpacing.xxs) {
                    Text(NSLocalizedString("Turn on notifications", comment: ""))
                        .font(.headline)
                        .foregroundColor(UIColors.label)
                    
                    Text(NSLocalizedString("Get notified about replies, upvotes, and important updates.", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(UIColors.secondaryLabel)
                }
                
                Spacer()
                
                GlassButton(
                    NSLocalizedString("Enable", comment: ""),
                    style: .primary
                ) {
                    Task { 
                        let granted = await notificationManager.requestNotificationPermission()
                        if granted {
                            alertsStatus = .authorized
                        }
                    }
                }
                .accessibilityLabel(Text(NSLocalizedString("Enable notifications", comment: "")))
            }
        }
        .padding([.horizontal, .top])
        .glassAppear()
    }
    
    // MARK: - Enhanced Tab Selector
    
    private var enhancedTabSelector: some View {
        GlassCard(material: MaterialDesignSystem.Glass.ultraThin, padding: UISpacing.xs) {
            Picker("", selection: $selectedTab) {
                HStack {
                    Text("Activity")
                    if pushNotificationService.unreadCount > 0 {
                        Badge(count: pushNotificationService.unreadCount)
                    }
                }
                .tag(0)
                
                Text("Keywords").tag(1)
                
                HStack {
                    Text("Center")
                    if notificationManager.totalUnreadCount > 0 {
                        Badge(count: notificationManager.totalUnreadCount)
                    }
                }
                .tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Activity Tab Content
    
    private var activityTabContent: some View {
        Group {
            if pushNotificationService.notifications.isEmpty {
                emptyActivityState
            } else {
                List {
                    ForEach(pushNotificationService.notifications.prefix(20)) { notification in
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
                .listStyle(PlainListStyle())
                .refreshable {
                    // Refresh notifications
                    await refreshNotifications()
                }
            }
        }
    }
    
    // MARK: - Empty Activity State
    
    private var emptyActivityState: some View {
        VStack(spacing: UISpacing.lg) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(UIColors.secondaryLabel)
            
            VStack(spacing: UISpacing.sm) {
                Text("No Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(UIColors.label)
                
                Text("When you receive notifications, they'll appear here.")
                    .font(.body)
                    .foregroundColor(UIColors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, UISpacing.xl)
            }
            
            // Quick action buttons
            VStack(spacing: UISpacing.md) {
                GlassButton("View All Notifications", style: .primary) {
                    selectedTab = 2
                }
                
                GlassButton("Notification Settings", style: .secondary) {
                    selectedTab = 2
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MaterialDesignSystem.Context.background)
    }
    
    // MARK: - Keyword Alerts Content
    
    private var keywordAlertsContent: some View {
        List {
            Section(footer: Text("Get notified when new posts mention your saved keywords.")) {
                ForEach(keywordAlerts.keys.sorted(), id: \.self) { key in
                    Toggle(isOn: Binding(
                        get: { keywordAlerts[key, default: false] },
                        set: { keywordAlerts[key] = $0 }
                    )) {
                        Text(key)
                    }
                }
                .onDelete { indexSet in
                    let keys = keywordAlerts.keys.sorted()
                    for index in indexSet { 
                        keywordAlerts.removeValue(forKey: keys[index]) 
                    }
                }
                
                Button(action: {
                    // Add a sample new keyword (stub)
                    keywordAlerts["new keyword \(Int.random(in: 1...99))"] = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(UIColors.accentPrimary)
                        Text("Add keyword alert")
                            .foregroundColor(UIColors.label)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Actions
    
    private func handleNotificationTap(_ notification: DirtNotification) {
        pushNotificationService.markAsRead(notification.id)
        
        // Handle deep linking if available
        if let deepLinkPath = notification.data?.deepLinkPath {
            handleDeepLink(deepLinkPath)
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
    }
    
    private func refreshNotifications() async {
        // In a real app, this would fetch new notifications from the server
        await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
    }
}

// MARK: - Legacy Notification Row (for backward compatibility)
struct NotificationRow: View {
    let notification: Notification
    @State private var isPressed = false
    
    var body: some View {
        GlassCard(
            material: notification.isRead ? MaterialDesignSystem.Glass.ultraThin : MaterialDesignSystem.Glass.thin,
            padding: UISpacing.md
        ) {
            HStack(alignment: .top, spacing: UISpacing.sm) {
                // Notification Icon with glass effect
                ZStack {
                    Circle()
                        .fill(notification.isRead ? 
                              MaterialDesignSystem.GlassColors.neutral : 
                              MaterialDesignSystem.GlassColors.primary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    notification.isRead ? 
                                    MaterialDesignSystem.GlassBorders.subtle : 
                                    MaterialDesignSystem.GlassBorders.accent,
                                    lineWidth: 1
                                )
                        )
                    
                    if let imageName = notification.imageName {
                        Image(systemName: imageName)
                            .foregroundColor(notification.isRead ? UIColors.secondaryLabel : UIColors.accentPrimary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                
                // Notification Content
                VStack(alignment: .leading, spacing: UISpacing.xxs) {
                    Text("\(notification.username) \(notification.action)")
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .medium)
                        .foregroundColor(notification.isRead ? UIColors.secondaryLabel : UIColors.label)
                        .lineLimit(2)
                    
                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundColor(UIColors.secondaryLabel)
                }
                
                Spacer()
                
                // Unread indicator with glass effect
                if !notification.isRead {
                    Circle()
                        .fill(UIColors.accentPrimary)
                        .frame(width: 8, height: 8)
                        .shadow(color: MaterialDesignSystem.GlassShadows.soft, radius: 2)
                }
            }
        }
        .padding(.horizontal)
        .glassPress(isPressed: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MaterialMotion.Interactive.buttonPress(isPressed: pressing)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
