import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var badgeManager = NotificationBadgeManager.shared
    @State private var previousTab: TabItem = .feed
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Feed Tab
            NavigationStack(path: $appState.navigationPath) {
                FeedView()
            }
            .tabItem {
                TabItemView(
                    tab: .feed,
                    isSelected: appState.selectedTab == .feed,
                    badgeCount: appState.getBadgeCount(for: .feed)
                )
            }
            .tag(TabItem.feed)
            
            // Reviews Tab
            NavigationStack(path: $appState.navigationPath) {
                ReviewsView()
            }
            .tabItem {
                TabItemView(
                    tab: .reviews,
                    isSelected: appState.selectedTab == .reviews,
                    badgeCount: appState.getBadgeCount(for: .reviews)
                )
            }
            .tag(TabItem.reviews)
            
            // Create Tab
            NavigationStack(path: $appState.navigationPath) {
                CreatePostView()
            }
            .tabItem {
                TabItemView(
                    tab: .create,
                    isSelected: appState.selectedTab == .create,
                    badgeCount: 0 // Create tab typically doesn't have badges
                )
            }
            .tag(TabItem.create)
            
            // Notifications Tab
            NavigationStack(path: $appState.navigationPath) {
                NotificationCenterView()
            }
            .tabItem {
                TabItemView(
                    tab: .notifications,
                    isSelected: appState.selectedTab == .notifications,
                    badgeCount: badgeManager.totalBadgeCount
                )
            }
            .tag(TabItem.notifications)
            
            // Profile Tab
            NavigationStack(path: $appState.navigationPath) {
                ProfileView()
            }
            .tabItem {
                TabItemView(
                    tab: .profile,
                    isSelected: appState.selectedTab == .profile,
                    badgeCount: appState.getBadgeCount(for: .profile)
                )
            }
            .tag(TabItem.profile)
        }
        .accentColor(.blue)
        .animation(.easeInOut(duration: 0.3), value: appState.selectedTab)
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            handleTabChange(from: oldValue, to: newValue)
        }
        .onDisappear {
            // Save navigation state when view disappears
            appState.saveNavigationState(for: appState.selectedTab)
        }
        .onReceive(appState.$deepLinkPath) { path in
            handleDeepLink(path)
        }
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    // MARK: - Tab Management
    
    private func handleTabChange(from oldTab: TabItem, to newTab: TabItem) {
        print("📱 MainTabView: Tab changed from \(oldTab.rawValue) to \(newTab.rawValue)")
        
        // Save navigation state for the previous tab
        if oldTab != newTab {
            appState.saveNavigationState(for: oldTab)
            print("💾 MainTabView: Saved navigation state for \(oldTab.rawValue)")
        }
        
        previousTab = oldTab
        
        // Provide haptic feedback for tab changes
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Use AppState's enhanced tab selection
        if oldTab != newTab {
            appState.selectTab(newTab)
        }
        
        // Handle tab-specific logic
        switch newTab {
        case .notifications:
            // Mark notifications as seen when user visits notifications tab
            badgeManager.clearBadge(for: .interaction)
            print("🔔 MainTabView: Cleared interaction badges for notifications tab")
        case .reviews:
            // Could trigger analytics or refresh data
            print("⭐ MainTabView: Entered reviews tab")
        case .feed:
            // Could refresh feed data
            print("📰 MainTabView: Entered feed tab")
        case .create:
            // Reset create form if needed
            print("➕ MainTabView: Entered create tab")
        case .profile:
            // Could refresh profile data
            print("👤 MainTabView: Entered profile tab")
        }
    }
    
    private func setupTabBarAppearance() {
        // Configure tab bar appearance for better visual consistency
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Deep Linking
    
    private func handleDeepLink(_ path: String?) {
        guard let path = path else { return }
        
        print("🔗 MainTabView: Handling deep link: \(path)")
        
        // Enhanced deep linking with support for nested navigation
        let components = path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard let firstComponent = components.first else { 
            print("❌ MainTabView: No valid component found in path")
            return 
        }
        
        // Navigate to the appropriate tab
        let targetTab: TabItem?
        switch firstComponent {
        case "feed":
            targetTab = .feed
        case "reviews":
            targetTab = .reviews
        case "create":
            targetTab = .create
        case "notifications":
            targetTab = .notifications
        case "profile":
            targetTab = .profile
        default:
            targetTab = nil
        }
        
        guard let tab = targetTab else { 
            print("❌ MainTabView: Unknown tab component: \(firstComponent)")
            return 
        }
        
        print("✅ MainTabView: Navigating to tab: \(tab.rawValue)")
        
        // Animate to the target tab
        withAnimation(.easeInOut(duration: 0.3)) {
            appState.selectedTab = tab
        }
        
        // Handle nested navigation within the tab
        if components.count > 1 {
            let remainingPath = Array(components.dropFirst()).joined(separator: "/")
            print("🔗 MainTabView: Handling nested navigation: \(remainingPath)")
            handleNestedNavigation(for: tab, path: remainingPath)
        }
        
        // Clear the deep link path after handling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            appState.deepLinkPath = nil
        }
    }
    
    private func handleNestedNavigation(for tab: TabItem, path: String) {
        // Handle navigation within specific tabs
        switch tab {
        case .feed:
            // Handle feed-specific deep links (e.g., specific posts)
            if path.hasPrefix("post/") {
                let postId = String(path.dropFirst(5))
                // Navigate to specific post
                appState.navigationPath.append("post/\(postId)")
            }
        case .reviews:
            // Handle review-specific deep links
            if path.hasPrefix("review/") {
                let reviewId = String(path.dropFirst(7))
                appState.navigationPath.append("review/\(reviewId)")
            } else if path == "filter" {
                appState.navigationPath.append("filter")
            }
        case .notifications:
            // Handle notification-specific deep links
            if path.hasPrefix("notification/") {
                let notificationId = String(path.dropFirst(13))
                appState.navigationPath.append("notification/\(notificationId)")
            }
        case .profile:
            // Handle profile-specific deep links
            if path == "settings" {
                appState.navigationPath.append("settings")
            } else if path == "edit" {
                appState.navigationPath.append("edit")
            }
        case .create:
            // Create tab typically doesn't have nested navigation
            break
        }
    }
}

}

// MARK: - Tab Item View Component

struct TabItemView: View {
    let tab: TabItem
    let isSelected: Bool
    let badgeCount: Int
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Image(systemName: isSelected ? tab.selectedIconName : tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Badge overlay
                if badgeCount > 0 {
                    NotificationBadge(
                        count: badgeCount,
                        size: .small,
                        style: .red
                    )
                    .offset(x: 12, y: -8)
                }
            }
            
            Text(tab.rawValue)
                .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .blue : .gray)
        }
    }
}

// MARK: - Navigation Extensions

extension AppState {
    func navigateToTab(_ tab: TabItem, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        } else {
            selectedTab = tab
        }
    }
    
    func navigateToTabWithPath(_ tab: TabItem, path: String) {
        selectedTab = tab
        navigationPath = NavigationPath()
        navigationPath.append(path)
    }
}

// MARK: - Tab Item Extensions

extension TabItem {
    var accessibilityLabel: String {
        switch self {
        case .feed:
            return "Feed Tab"
        case .reviews:
            return "Reviews Tab"
        case .create:
            return "Create Post Tab"
        case .notifications:
            return "Notifications Tab"
        case .profile:
            return "Profile Tab"
        }
    }
    
    var accessibilityHint: String {
        switch self {
        case .feed:
            return "View your personalized feed"
        case .reviews:
            return "Browse dating reviews"
        case .create:
            return "Create a new post or review"
        case .notifications:
            return "View your notifications"
        case .profile:
            return "View and edit your profile"
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationService())
        .environmentObject(SupabaseManager())
}