import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
            
            CreatePostView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 30))
                    Text("Post")
                }
                .tag(2)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Alerts")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.black)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
