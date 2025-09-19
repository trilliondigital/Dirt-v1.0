import SwiftUI

struct NotificationRowView: View {
    let notification: DirtNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Notification Icon
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
                        
                        Text(notification.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Message
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Type badge
                    HStack {
                        Label(notification.type.displayName, systemImage: notification.type.iconName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Unread indicator
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            
            if !notification.isRead {
                Button("Mark Read") {
                    onMarkAsRead()
                }
                .tint(.blue)
            }
        }
    }
    
    private var notificationIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: notification.type.iconName)
                .font(.system(size: 16, weight: .medium))
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

// MARK: - Notification Badge View

struct NotificationBadgeView: View {
    let count: Int
    let showCount: Bool
    let maxCount: Int
    
    init(count: Int = 0, showCount: Bool = true, maxCount: Int = 99) {
        self.count = count
        self.showCount = showCount
        self.maxCount = maxCount
    }
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: badgeSize, height: badgeSize)
                
                if showCount {
                    Text(displayText)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(.white)
                }
            }
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
            return 8
        }
        return count > 9 ? 20 : 16
    }
    
    private var fontSize: CGFloat {
        return count > 9 ? 10 : 11
    }
}

// MARK: - Badge View

struct Badge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.red)
                )
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Preview

struct NotificationRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            NotificationRowView(
                notification: DirtNotification(
                    userId: UUID(),
                    type: .reply,
                    title: "New Reply",
                    message: "Someone replied to your post about dating advice",
                    isRead: false
                ),
                onTap: {},
                onMarkAsRead: {},
                onDelete: {}
            )
            
            NotificationRowView(
                notification: DirtNotification(
                    userId: UUID(),
                    type: .reputationMilestone,
                    title: "Reputation Milestone!",
                    message: "You've reached 500 reputation points!",
                    isRead: true
                ),
                onTap: {},
                onMarkAsRead: {},
                onDelete: {}
            )
            
            NotificationRowView(
                notification: DirtNotification(
                    userId: UUID(),
                    type: .announcement,
                    title: "Community Update",
                    message: "We've added new features to improve your experience",
                    isRead: false
                ),
                onTap: {},
                onMarkAsRead: {},
                onDelete: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}