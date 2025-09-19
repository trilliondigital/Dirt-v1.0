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
            
            // Search Tab
            SearchView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .search ? TabItem.search.selectedIconName : TabItem.search.iconName)
                    Text(TabItem.search.rawValue)
                }
                .tag(TabItem.search)
            
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
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationService())
        .environmentObject(SupabaseManager())
}