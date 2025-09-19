import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedFilter: NotificationFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                NotificationFilterBar(selectedFilter: $selectedFilter)
                
                // Notifications List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredNotifications) { notification in
                            NotificationRow(
                                notification: notification,
                                onTap: {
                                    viewModel.markAsRead(notification)
                                    // Handle navigation based on notification type
                                },
                                onDismiss: {
                                    viewModel.dismissNotification(notification)
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete") {
                                    viewModel.deleteNotification(notification)
                                }
                                .tint(.red)
                            }
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .refreshable {
                    await viewModel.refreshNotifications()
                }
            }
            .navigationTitle("Notifications")
            
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Mark All as Read") {
                            viewModel.markAllAsRead()
                        }
                        
                        Button("Clear All") {
                            viewModel.clearAllNotifications()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.loadNotifications()
            }
            .onChange(of: selectedFilter) { newFilter in
                viewModel.applyFilter(newFilter)
            }
            .overlay {
                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    EmptyNotificationsView()
                }
            }
        }
    }
}

// MARK: - Notification Filter Bar
struct NotificationFilterBar: View {
    @Binding var selectedFilter: NotificationFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: DirtNotification
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                NotificationIcon(type: notification.type)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .multilineTextAlignment(.leading)
                    
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(notification.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Mark as Read") {
                // Handle mark as read
            }
            
            Button("Dismiss") {
                onDismiss()
            }
            
            Button("Delete", role: .destructive) {
                // Handle delete
            }
        }
    }
}

// MARK: - Notification Icon
struct NotificationIcon: View {
    let type: NotificationType
    
    var body: some View {
        Circle()
            .fill(iconBackgroundColor)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: type.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            )
    }
    
    private var iconBackgroundColor: Color {
        switch type {
        case .reply, .mention:
            return Color.blue.opacity(0.2)
        case .upvote:
            return Color.green.opacity(0.2)
        case .reputationMilestone, .postMilestone, .engagementMilestone, .anniversaryMilestone:
            return Color.yellow.opacity(0.2)
        case .firstPost, .firstUpvote, .popularPost, .helpfulContributor, .communityChampion:
            return Color.green.opacity(0.2)
        case .announcement, .communityEvent:
            return Color.purple.opacity(0.2)
        case .featureUpdate:
            return Color.orange.opacity(0.2)
        case .moderationUpdate:
            return Color.red.opacity(0.2)
        case .comment:
            return Color.cyan.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .reply, .mention:
            return .blue
        case .upvote:
            return .green
        case .reputationMilestone, .postMilestone, .engagementMilestone, .anniversaryMilestone:
            return .yellow
        case .firstPost, .firstUpvote, .popularPost, .helpfulContributor, .communityChampion:
            return .green
        case .announcement, .communityEvent:
            return .purple
        case .featureUpdate:
            return .orange
        case .moderationUpdate:
            return .red
        case .comment:
            return .cyan
        }
    }
}

// MARK: - Empty Notifications View
struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No notifications")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("When you get notifications, they'll appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

enum NotificationFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case mentions = "Mentions"
    case upvotes = "Upvotes"
    case replies = "Replies"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Extensions
// timeAgo is now defined in the DirtNotification model

#Preview {
    NotificationsView()
}