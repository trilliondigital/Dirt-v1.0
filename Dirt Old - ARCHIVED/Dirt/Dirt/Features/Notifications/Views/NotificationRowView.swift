import SwiftUI

struct NotificationRowView: View {
    let notification: DirtNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        GlassCard(
            material: notification.isRead ? 
                MaterialDesignSystem.Glass.ultraThin : 
                MaterialDesignSystem.Glass.thin,
            padding: UISpacing.md
        ) {
            HStack(alignment: .top, spacing: UISpacing.md) {
                // Notification Icon
                notificationIcon
                
                // Notification Content
                VStack(alignment: .leading, spacing: UISpacing.xs) {
                    // Title and timestamp
                    HStack(alignment: .top) {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(notification.isRead ? UIColors.secondaryLabel : UIColors.label)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Text(notification.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(UIColors.tertiaryLabel)
                    }
                    
                    // Message
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(UIColors.secondaryLabel)
                        .lineLimit(3)
                    
                    // Additional context if available
                    if let data = notification.data {
                        notificationContext(data)
                    }
                }
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(UIColors.accentPrimary)
                        .frame(width: 8, height: 8)
                        .shadow(color: MaterialDesignSystem.GlassShadows.soft, radius: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, UISpacing.xs)
        .contentShape(Rectangle())
        .glassPress(isPressed: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MaterialMotion.Interactive.buttonPress(isPressed: pressing)) {
                isPressed = pressing
            }
        }, perform: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Delete action
            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDelete()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            // Mark as read/unread action
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onMarkAsRead()
                }
            } label: {
                Label(
                    notification.isRead ? "Mark Unread" : "Mark Read",
                    systemImage: notification.isRead ? "envelope.badge" : "envelope.open"
                )
            }
            .tint(notification.isRead ? .orange : .green)
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Notification Icon
    
    private var notificationIcon: some View {
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
            
            Image(systemName: notification.type.iconName)
                .foregroundColor(notification.isRead ? UIColors.secondaryLabel : UIColors.accentPrimary)
                .font(.system(size: 18, weight: .medium))
        }
    }
    
    // MARK: - Notification Context
    
    @ViewBuilder
    private func notificationContext(_ data: NotificationData) -> some View {
        HStack(spacing: UISpacing.xs) {
            // Content type indicator
            if let contentType = data.contentType {
                Label(contentType.displayName, systemImage: contentType.iconName)
                    .font(.caption2)
                    .foregroundColor(UIColors.tertiaryLabel)
            }
            
            // Author information
            if let authorUsername = data.authorUsername {
                Text("by \(authorUsername)")
                    .font(.caption2)
                    .foregroundColor(UIColors.tertiaryLabel)
            }
            
            // Reputation change
            if let reputationChange = data.reputationChange, reputationChange != 0 {
                HStack(spacing: 2) {
                    Image(systemName: reputationChange > 0 ? "arrow.up" : "arrow.down")
                    Text("\(abs(reputationChange))")
                }
                .font(.caption2)
                .foregroundColor(reputationChange > 0 ? .green : .red)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Context Menu
    
    private var contextMenuItems: some View {
        Group {
            Button {
                onTap()
            } label: {
                Label("Open", systemImage: "arrow.up.right")
            }
            
            Button {
                onMarkAsRead()
            } label: {
                Label(
                    notification.isRead ? "Mark as Unread" : "Mark as Read",
                    systemImage: notification.isRead ? "envelope.badge" : "envelope.open"
                )
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Announcement Row View

struct AnnouncementRowView: View {
    let announcement: CommunityAnnouncement
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDismiss: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        GlassCard(
            material: announcement.isRead ? 
                MaterialDesignSystem.Glass.ultraThin : 
                MaterialDesignSystem.Glass.thin,
            padding: UISpacing.md
        ) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                // Header
                HStack(alignment: .top, spacing: UISpacing.sm) {
                    // Announcement type icon
                    announcementIcon
                    
                    // Title and metadata
                    VStack(alignment: .leading, spacing: UISpacing.xs) {
                        HStack {
                            Text(announcement.title)
                                .font(.headline)
                                .fontWeight(announcement.isRead ? .medium : .semibold)
                                .foregroundColor(announcement.isRead ? UIColors.secondaryLabel : UIColors.label)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            if !announcement.isRead {
                                Circle()
                                    .fill(UIColors.accentPrimary)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Type and priority badges
                        HStack(spacing: UISpacing.xs) {
                            AnnouncementBadge(
                                text: announcement.type.displayName,
                                color: Color(announcement.type.color)
                            )
                            
                            if announcement.priority != .normal {
                                AnnouncementBadge(
                                    text: announcement.priority.displayName,
                                    color: priorityColor(announcement.priority)
                                )
                            }
                            
                            Spacer()
                            
                            Text(announcement.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(UIColors.tertiaryLabel)
                        }
                    }
                }
                
                // Message
                Text(announcement.message)
                    .font(.body)
                    .foregroundColor(UIColors.secondaryLabel)
                    .lineLimit(nil)
                
                // Action button
                if let actionButton = announcement.actionButton {
                    HStack {
                        Spacer()
                        
                        GlassButton(
                            actionButton.title,
                            style: .secondary
                        ) {
                            onTap()
                        }
                        .font(.subheadline)
                    }
                }
                
                // Expiration warning
                if let expiresAt = announcement.expiresAt {
                    let timeRemaining = expiresAt.timeIntervalSinceNow
                    if timeRemaining > 0 && timeRemaining < 24 * 60 * 60 { // Less than 24 hours
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("Expires \(expiresAt, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, UISpacing.xs)
        .contentShape(Rectangle())
        .glassPress(isPressed: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MaterialMotion.Interactive.buttonPress(isPressed: pressing)) {
                isPressed = pressing
            }
        }, perform: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Dismiss action
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDismiss()
                }
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
            .tint(.orange)
            
            // Mark as read action
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    onMarkAsRead()
                }
            } label: {
                Label(
                    announcement.isRead ? "Mark Unread" : "Mark Read",
                    systemImage: announcement.isRead ? "envelope.badge" : "envelope.open"
                )
            }
            .tint(announcement.isRead ? .orange : .green)
        }
        .contextMenu {
            announcementContextMenu
        }
    }
    
    // MARK: - Announcement Icon
    
    private var announcementIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(announcement.type.color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(announcement.type.color), lineWidth: 1)
                )
            
            Image(systemName: announcement.type.iconName)
                .foregroundColor(Color(announcement.type.color))
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    // MARK: - Context Menu
    
    private var announcementContextMenu: some View {
        Group {
            if announcement.actionButton != nil {
                Button {
                    onTap()
                } label: {
                    Label("Open", systemImage: "arrow.up.right")
                }
            }
            
            Button {
                onMarkAsRead()
            } label: {
                Label(
                    announcement.isRead ? "Mark as Unread" : "Mark as Read",
                    systemImage: announcement.isRead ? "envelope.badge" : "envelope.open"
                )
            }
            
            Divider()
            
            Button {
                onDismiss()
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityColor(_ priority: AnnouncementPriority) -> Color {
        switch priority {
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

// MARK: - Announcement Badge

struct AnnouncementBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Content Type Extension

extension ContentType {
    var displayName: String {
        switch self {
        case .post:
            return "Post"
        case .review:
            return "Review"
        case .comment:
            return "Comment"
        }
    }
    
    var iconName: String {
        switch self {
        case .post:
            return "doc.text"
        case .review:
            return "star"
        case .comment:
            return "bubble.left"
        }
    }
}

// MARK: - Preview

struct NotificationRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NotificationRowView(
                notification: DirtNotification(
                    userId: UUID(),
                    type: .reply,
                    title: "New Reply",
                    message: "User123 replied to your post about dating advice",
                    data: NotificationData(
                        contentType: .post,
                        authorUsername: "User123"
                    )
                ),
                onTap: {},
                onMarkAsRead: {},
                onDelete: {}
            )
            
            AnnouncementRowView(
                announcement: CommunityAnnouncement(
                    title: "New Feature: Enhanced Search",
                    message: "We've added new search filters to help you find exactly what you're looking for.",
                    type: .feature,
                    priority: .high,
                    actionButton: AnnouncementAction(
                        title: "Try It Now",
                        deepLink: "/search"
                    )
                ),
                onTap: {},
                onMarkAsRead: {},
                onDismiss: {}
            )
        }
        .padding()
    }
}