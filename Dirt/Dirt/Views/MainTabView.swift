import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .feed ? "house.fill" : "house")
                    Text("Feed")
                }
                .tag(TabItem.feed)
            
            ReviewsView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .reviews ? "star.fill" : "star")
                    Text("Reviews")
                }
                .tag(TabItem.reviews)
            
            CreatePostView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .create ? "plus.circle.fill" : "plus.circle")
                    Text("Create")
                }
                .tag(TabItem.create)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .notifications ? "bell.fill" : "bell")
                    Text("Notifications")
                }
                .badge(appState.getBadgeCount(for: .notifications))
                .tag(TabItem.notifications)
            
            ProfileView()
                .tabItem {
                    Image(systemName: appState.selectedTab == .profile ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .tag(TabItem.profile)
        }
        .onChange(of: appState.selectedTab) { _, newTab in
            appState.saveNavigationState(for: newTab)
        }
    }
}