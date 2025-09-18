import SwiftUI

struct Notification: Identifiable {
    let id = UUID()
    let username: String
    let action: String
    let timeAgo: String
    var isRead: Bool
    let imageName: String?
}

struct NotificationsView: View {
    @State private var notifications: [Notification] = [
        Notification(
            username: "User456",
            action: "liked your post",
            timeAgo: "5m ago",
            isRead: false,
            imageName: "heart.fill"
        ),
        Notification(
            username: "User222",
            action: "mentioned you in a comment",
            timeAgo: "20m ago",
            isRead: false,
            imageName: "at"
        ),
        Notification(
            username: "User789",
            action: "commented: 'I had a similar experience!'",
            timeAgo: "1h ago",
            isRead: false,
            imageName: "bubble.left"
        ),
        Notification(
            username: "Dirt Team",
            action: "Your post has been viewed 150 times",
            timeAgo: "3h ago",
            isRead: true,
            imageName: "eye"
        ),
        Notification(
            username: "Moderation",
            action: "A report was filed on your post (review pending)",
            timeAgo: "6h ago",
            isRead: true,
            imageName: "flag"
        ),
        Notification(
            username: "User123",
            action: "started following you",
            timeAgo: "1d ago",
            isRead: true,
            imageName: "person.badge.plus"
        )
    ]
    
    @State private var selectedTab: Int = 0 // 0 Activity, 1 Keywords
    @State private var keywordAlerts: [String: Bool] = [
        "ghosting": true,
        "red flag": true,
        "Austin": false
    ]
    @State private var alertsStatus: AlertsService.AuthorizationStatus = .notDetermined
    @Environment(\.services) private var services
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enable alerts banner
                if alertsStatus != .authorized {
                    GlassCard(material: MaterialDesignSystem.Context.card, padding: UISpacing.md) {
                        HStack(alignment: .top, spacing: UISpacing.sm) {
                            Image(systemName: "bell.badge")
                                .font(.title3)
                                .foregroundColor(UIColors.accentPrimary)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: UISpacing.xxs) {
                                Text(NSLocalizedString("Turn on alerts", comment: ""))
                                    .font(.headline)
                                    .foregroundColor(UIColors.label)
                                
                                Text(NSLocalizedString("Get notified about mentions and keyword matches.", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                            
                            Spacer()
                            
                            GlassButton(
                                NSLocalizedString("Enable", comment: ""),
                                style: .primary
                            ) {
                                Task { alertsStatus = await services.alertsService.requestAuthorization() }
                            }
                            .accessibilityLabel(Text(NSLocalizedString("Enable", comment: "")))
                        }
                    }
                    .padding([.horizontal, .top])
                    .glassAppear()
                }
                // Segmented control with glass styling
                GlassCard(material: MaterialDesignSystem.Glass.ultraThin, padding: UISpacing.xs) {
                    Picker("", selection: $selectedTab) {
                        Text("Activity").tag(0)
                        Text("Keyword Alerts").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    // Activity list
                    List {
                        ForEach(notifications.indices, id: \.self) { idx in
                            NotificationRow(notification: notifications[idx])
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if notifications[idx].isRead {
                                        Button("Unread") { notifications[idx].isRead = false }
                                            .tint(.blue)
                                    } else {
                                        Button("Read") { notifications[idx].isRead = true }
                                            .tint(.green)
                                    }
                                    Button(role: .destructive) {
                                        notifications.remove(at: idx)
                                    } label: { Text("Delete") }
                                }
                        }
                        .onDelete { indexSet in
                            notifications.remove(atOffsets: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    // Keyword alerts management
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
                                for index in indexSet { keywordAlerts.removeValue(forKey: keys[index]) }
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
            }
            .navigationBarTitle("Alerts", displayMode: .inline)
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        GlassButton(
                            "Mark all as read",
                            style: .subtle
                        ) {
                            withAnimation(MaterialMotion.Spring.standard) {
                                notifications = notifications.map { n in var n = n; n.isRead = true; return n }
                            }
                        }
                    }
                }
            }
            .task {
                alertsStatus = await services.alertsService.currentStatus()
            }
        }
    }
}

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
