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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented control
                Picker("", selection: $selectedTab) {
                    Text("Activity").tag(0)
                    Text("Keyword Alerts").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
                                    Image(systemName: "plus.circle.fill").foregroundColor(.blue)
                                    Text("Add keyword alert")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Alerts", displayMode: .inline)
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark all as read") { notifications = notifications.map { n in var n = n; n.isRead = true; return n } }
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .padding()
        }
        .cardBackground()
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
