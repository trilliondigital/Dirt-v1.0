import SwiftUI

struct Notification: Identifiable {
    let id = UUID()
    let username: String
    let action: String
    let timeAgo: String
    let isRead: Bool
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
            username: "User123",
            action: "started following you",
            timeAgo: "1d ago",
            isRead: true,
            imageName: "person.badge.plus"
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .background(notification.isRead ? Color(.systemBackground) : Color.blue.opacity(0.05))
                }
                .onDelete { indexSet in
                    notifications.remove(atOffsets: indexSet)
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Notifications", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark all as read") {
                        // Mark all as read action
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Notification Icon
            ZStack {
                Circle()
                    .fill(notification.isRead ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if let imageName = notification.imageName {
                    Image(systemName: imageName)
                        .foregroundColor(notification.isRead ? .blue : .white)
                        .imageScale(.small)
                }
            }
            
            // Notification Content
            VStack(alignment: .leading, spacing: 4) {
                Text("\(notification.username) \(notification.action)")
                    .font(.subheadline)
                    .foregroundColor(notification.isRead ? .gray : .primary)
                
                Text(notification.timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
