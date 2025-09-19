import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Feed Tab
            FeedView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .feed ? TabItem.feed.selectedIconName : TabItem.feed.iconName)
                    Text(TabItem.feed.rawValue)
                }
                .tag(TabItem.feed)
            
            // Reviews Tab
            ReviewsView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .reviews ? TabItem.reviews.selectedIconName : TabItem.reviews.iconName)
                    Text(TabItem.reviews.rawValue)
                }
                .tag(TabItem.reviews)
                .badge(appState.getBadgeCount(for: .reviews) > 0 ? appState.getBadgeCount(for: .reviews) : nil)
            
            // Create Tab
            CreatePostView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .create ? TabItem.create.selectedIconName : TabItem.create.iconName)
                    Text(TabItem.create.rawValue)
                }
                .tag(TabItem.create)
            
            // Notifications Tab
            NotificationCenterView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .notifications ? TabItem.notifications.selectedIconName : TabItem.notifications.iconName)
                    Text(TabItem.notifications.rawValue)
                }
                .tag(TabItem.notifications)
                .badge(badgeManager.totalBadgeCount > 0 ? badgeManager.totalBadgeCount : nil)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .profile ? TabItem.profile.selectedIconName : TabItem.profile.iconName)
                    Text(TabItem.profile.rawValue)
                }
                .tag(TabItem.profile)
        }
        .accentColor(.blue)
        .animation(.easeInOut(duration: 0.2), value: appState.selectedTab)
        .onReceive(appState.$deepLinkPath) { path in
            handleDeepLink(path)
        }
    }
    
    private func handleDeepLink(_ path: String?) {
        guard let path = path else { return }
        
        // Handle deep linking to specific tabs and paths
        let components = path.components(separatedBy: "/")
        
        if let firstComponent = components.first {
            switch firstComponent {
            case "feed":
                appState.selectedTab = .feed
            case "reviews":
                appState.selectedTab = .reviews
            case "create":
                appState.selectedTab = .create
            case "notifications":
                appState.selectedTab = .notifications
            case "profile":
                appState.selectedTab = .profile
            default:
                break
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationService())
        .environmentObject(SupabaseManager())
}