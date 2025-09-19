import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: TabItem = .feed
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var currentUser: User?
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    @Published var deepLinkPath: String?
    @Published var notificationBadges: [TabItem: Int] = [:]
    
    // Theme and appearance
    @Published var isDarkMode = false
    @Published var useSystemAppearance = true
    
    init() {
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Configure app-wide appearance
        if useSystemAppearance {
            // Use system appearance
        } else {
            // Use custom theme
        }
    }
    
    func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "feed":
            selectedTab = .feed
        case "reviews":
            selectedTab = .reviews
        case "create":
            selectedTab = .create
        case "notifications":
            selectedTab = .notifications
        case "profile":
            selectedTab = .profile
        default:
            break
        }
        
        // Store the path for further navigation within the tab
        deepLinkPath = components.path
    }
    
    func handleDeepLink(to tab: TabItem, path: String? = nil) {
        selectedTab = tab
        deepLinkPath = path
    }
    
    // MARK: - Badge Management
    
    func updateBadge(for tab: TabItem, count: Int) {
        notificationBadges[tab] = count
    }
    
    func getBadgeCount(for tab: TabItem) -> Int {
        return notificationBadges[tab] ?? 0
    }
}

enum TabItem: String, CaseIterable {
    case feed = "Feed"
    case reviews = "Reviews"
    case create = "Create"
    case notifications = "Notifications"
    case profile = "Profile"
    
    var iconName: String {
        switch self {
        case .feed:
            return "house"
        case .reviews:
            return "star"
        case .create:
            return "plus.circle"
        case .notifications:
            return "bell"
        case .profile:
            return "person.circle"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .feed:
            return "house.fill"
        case .reviews:
            return "star.fill"
        case .create:
            return "plus.circle.fill"
        case .notifications:
            return "bell.fill"
        case .profile:
            return "person.circle.fill"
        }
    }
}