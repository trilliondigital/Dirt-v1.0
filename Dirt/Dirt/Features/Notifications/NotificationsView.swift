import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        NavigationView {
            VStack {
                if notificationManager.totalUnreadCount > 0 {
                    List {
                        NotificationRowView(
                            title: "Welcome to Dirt!",
                            message: "Thanks for joining our community",
                            time: "2h ago",
                            isRead: false
                        )
                        
                        NotificationRowView(
                            title: "Post Upvoted",
                            message: "Your post received an upvote",
                            time: "1d ago",
                            isRead: false
                        )
                        
                        NotificationRowView(
                            title: "New Reply",
                            message: "Someone replied to your comment",
                            time: "2d ago",
                            isRead: true
                        )
                    }
                } else {
                    VStack {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No notifications")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("You're all caught up!")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                if notificationManager.totalUnreadCount > 0 {
                    Button("Mark All Read") {
                        notificationManager.markAllAsRead()
                    }
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let title: String
    let message: String
    let time: String
    let isRead: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(isRead ? .medium : .semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}