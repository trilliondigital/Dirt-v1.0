import SwiftUI

// MARK: - Notification Badge View

struct NotificationBadgeView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    let showCount: Bool
    let maxCount: Int
    
    init(showCount: Bool = true, maxCount: Int = 99) {
        self.showCount = showCount
        self.maxCount = maxCount
    }
    
    var body: some View {
        ZStack {
            if notificationManager.totalUnreadCount > 0 {
                if showCount {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .scaleEffect(notificationManager.totalUnreadCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: notificationManager.totalUnreadCount)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(notificationManager.totalUnreadCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: notificationManager.totalUnreadCount)
                }
            }
        }
    }
    
    private var badgeText: String {
        let count = notificationManager.totalUnreadCount
        return count > maxCount ? "\(maxCount)+" : "\(count)"
    }
    
    private var horizontalPadding: CGFloat {
        let count = notificationManager.totalUnreadCount
        return count > 9 ? 6 : 4
    }
}

// MARK: - Specific Notification Badge Views

struct ActivityBadgeView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    
    let showCount: Bool
    let maxCount: Int
    
    init(showCount: Bool = true, maxCount: Int = 99) {
        self.showCount = showCount
        self.maxCount = maxCount
    }
    
    var body: some View {
        ZStack {
            if pushNotificationService.unreadCount > 0 {
                if showCount {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .scaleEffect(pushNotificationService.unreadCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pushNotificationService.unreadCount)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pushNotificationService.unreadCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pushNotificationService.unreadCount)
                }
            }
        }
    }
    
    private var badgeText: String {
        let count = pushNotificationService.unreadCount
        return count > maxCount ? "\(maxCount)+" : "\(count)"
    }
    
    private var horizontalPadding: CGFloat {
        let count = pushNotificationService.unreadCount
        return count > 9 ? 6 : 4
    }
}

struct AnnouncementBadgeView: View {
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    
    let showCount: Bool
    let maxCount: Int
    
    init(showCount: Bool = true, maxCount: Int = 99) {
        self.showCount = showCount
        self.maxCount = maxCount
    }
    
    var body: some View {
        ZStack {
            if communityAnnouncementService.unreadAnnouncementCount > 0 {
                if showCount {
                    Text(badgeText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .scaleEffect(communityAnnouncementService.unreadAnnouncementCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: communityAnnouncementService.unreadAnnouncementCount)
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .scaleEffect(communityAnnouncementService.unreadAnnouncementCount > 0 ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: communityAnnouncementService.unreadAnnouncementCount)
                }
            }
        }
    }
    
    private var badgeText: String {
        let count = communityAnnouncementService.unreadAnnouncementCount
        return count > maxCount ? "\(maxCount)+" : "\(count)"
    }
    
    private var horizontalPadding: CGFloat {
        let count = communityAnnouncementService.unreadAnnouncementCount
        return count > 9 ? 6 : 4
    }
}

// MARK: - Tab Bar Badge View

struct TabBarNotificationBadge: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            if notificationManager.totalUnreadCount > 0 {
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Text("\(min(notificationManager.totalUnreadCount, 99))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 8, y: -8)
                    .scaleEffect(notificationManager.totalUnreadCount > 0 ? 1.0 : 0.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: notificationManager.totalUnreadCount)
            }
        }
    }
}

// MARK: - Notification Type Badge

struct NotificationTypeBadge: View {
    let type: NotificationType
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption)
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(badgeColor)
                    .clipShape(Capsule())
            }
        }
        .foregroundColor(badgeColor)
    }
    
    private var badgeColor: Color {
        switch type.priority {
        case .low:
            return .gray
        case .normal:
            return .blue
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

// MARK: - Floating Notification Badge

struct FloatingNotificationBadge: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isVisible = false
    
    let onTap: () -> Void
    
    var body: some View {
        if notificationManager.totalUnreadCount > 0 && isVisible {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("\(notificationManager.totalUnreadCount) new")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.red)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
            .onAppear {
                // Auto-hide after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
    
    func show() {
        withAnimation {
            isVisible = true
        }
    }
    
    func hide() {
        withAnimation {
            isVisible = false
        }
    }
}

// MARK: - Notification Summary View

struct NotificationSummaryView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                NotificationSummaryItem(
                    title: "Activity",
                    count: pushNotificationService.unreadCount,
                    icon: "bell",
                    color: .blue
                )
                
                NotificationSummaryItem(
                    title: "Announcements",
                    count: communityAnnouncementService.unreadAnnouncementCount,
                    icon: "megaphone",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(MaterialDesignSystem.Glass.thin)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                )
        )
    }
}

struct NotificationSummaryItem: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(count > 0 ? color : .secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct NotificationBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "bell")
                    .overlay(
                        NotificationBadgeView()
                            .offset(x: 8, y: -8)
                    )
                
                Image(systemName: "bell")
                    .overlay(
                        NotificationBadgeView(showCount: false)
                            .offset(x: 8, y: -8)
                    )
            }
            
            NotificationSummaryView()
            
            FloatingNotificationBadge {
                print("Tapped floating badge")
            }
        }
        .padding()
    }
}