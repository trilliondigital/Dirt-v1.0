import SwiftUI
import Combine

// MARK: - Navigation Coordinator
/// Centralized navigation management for Material Glass transitions
/// Handles navigation flow, deep linking, and Material Glass transition animations
class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current selected tab in the main tab bar
    @Published var selectedTab: MainTab = .home
    
    /// Navigation path for programmatic navigation
    @Published var navigationPath = NavigationPath()
    
    /// Current modal presentation state
    @Published var presentedModal: ModalDestination?
    
    /// Sheet presentation state
    @Published var presentedSheet: SheetDestination?
    
    /// Full screen cover presentation state
    @Published var presentedFullScreenCover: FullScreenDestination?
    
    /// Alert presentation state
    @Published var presentedAlert: AlertDestination?
    
    /// Toast notification state
    @Published var presentedToast: ToastDestination?
    
    // MARK: - Navigation State
    
    /// Navigation history for back button functionality
    private var navigationHistory: [NavigationDestination] = []
    
    /// Maximum navigation history to maintain
    private let maxHistoryCount = 50
    
    // MARK: - Singleton
    
    static let shared = NavigationCoordinator()
    
    private init() {
        setupNavigationAppearance()
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific tab
    func navigateToTab(_ tab: MainTab) {
        withAnimation(MaterialMotion.Interactive.tabSelection()) {
            selectedTab = tab
        }
        
        // Haptic feedback
        MaterialHaptics.selection()
        
        // Clear navigation path when switching tabs
        navigationPath = NavigationPath()
    }
    
    /// Push a new destination onto the navigation stack
    func push(_ destination: NavigationDestination) {
        withAnimation(MaterialMotion.Glass.navigationTransition) {
            navigationPath.append(destination)
        }
        
        // Add to history
        addToHistory(destination)
        
        // Haptic feedback
        MaterialHaptics.light()
    }
    
    /// Pop the current view from navigation stack
    func pop() {
        guard !navigationPath.isEmpty else { return }
        
        withAnimation(MaterialMotion.Glass.navigationTransition) {
            navigationPath.removeLast()
        }
        
        // Haptic feedback
        MaterialHaptics.light()
    }
    
    /// Pop to root view
    func popToRoot() {
        guard !navigationPath.isEmpty else { return }
        
        withAnimation(MaterialMotion.Glass.navigationTransition) {
            navigationPath = NavigationPath()
        }
        
        // Clear history for current tab
        navigationHistory.removeAll()
        
        // Haptic feedback
        MaterialHaptics.medium()
    }
    
    /// Present a modal
    func presentModal(_ modal: ModalDestination) {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedModal = modal
        }
        
        // Haptic feedback
        MaterialHaptics.medium()
    }
    
    /// Dismiss current modal
    func dismissModal() {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedModal = nil
        }
        
        // Haptic feedback
        MaterialHaptics.light()
    }
    
    /// Present a sheet
    func presentSheet(_ sheet: SheetDestination) {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedSheet = sheet
        }
        
        // Haptic feedback
        MaterialHaptics.medium()
    }
    
    /// Dismiss current sheet
    func dismissSheet() {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedSheet = nil
        }
        
        // Haptic feedback
        MaterialHaptics.light()
    }
    
    /// Present a full screen cover
    func presentFullScreenCover(_ cover: FullScreenDestination) {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedFullScreenCover = cover
        }
        
        // Haptic feedback
        MaterialHaptics.heavy()
    }
    
    /// Dismiss current full screen cover
    func dismissFullScreenCover() {
        withAnimation(MaterialMotion.Glass.modalPresent) {
            presentedFullScreenCover = nil
        }
        
        // Haptic feedback
        MaterialHaptics.light()
    }
    
    /// Present an alert
    func presentAlert(_ alert: AlertDestination) {
        presentedAlert = alert
        
        // Haptic feedback
        MaterialHaptics.warning()
    }
    
    /// Dismiss current alert
    func dismissAlert() {
        presentedAlert = nil
    }
    
    /// Show a toast notification
    func showToast(_ toast: ToastDestination) {
        presentedToast = toast
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            if self.presentedToast?.id == toast.id {
                self.dismissToast()
            }
        }
    }
    
    /// Dismiss current toast
    func dismissToast() {
        withAnimation(MaterialMotion.Glass.toastAppear) {
            presentedToast = nil
        }
    }
    
    // MARK: - Deep Linking
    
    /// Handle deep link navigation
    func handleDeepLink(_ url: URL) {
        // Parse URL and navigate accordingly
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        // Handle different deep link patterns
        switch components.path {
        case "/profile":
            navigateToTab(.profile)
            if let userId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                push(.profile(userId: userId))
            }
            
        case "/post":
            navigateToTab(.home)
            if let postId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                push(.postDetail(postId: postId))
            }
            
        case "/search":
            navigateToTab(.search)
            if let query = components.queryItems?.first(where: { $0.name == "q" })?.value {
                push(.searchResults(query: query))
            }
            
        case "/create":
            navigateToTab(.create)
            
        case "/notifications":
            navigateToTab(.notifications)
            
        default:
            // Default to home tab
            navigateToTab(.home)
        }
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ destination: NavigationDestination) {
        navigationHistory.append(destination)
        
        // Maintain history limit
        if navigationHistory.count > maxHistoryCount {
            navigationHistory.removeFirst()
        }
    }
    
    private func setupNavigationAppearance() {
        // Configure Material Glass navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        // Set title attributes
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Navigation Destinations

/// Main tab destinations
enum MainTab: String, CaseIterable {
    case home = "home"
    case search = "search"
    case create = "create"
    case notifications = "notifications"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .create: return "Create"
        case .notifications: return "Notifications"
        case .profile: return "Profile"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .create: return "plus.circle"
        case .notifications: return "bell"
        case .profile: return "person.circle"
        }
    }
    
    var selectedSystemImage: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .create: return "plus.circle.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.circle.fill"
        }
    }
}

/// Navigation stack destinations
enum NavigationDestination: Hashable {
    case profile(userId: String)
    case postDetail(postId: String)
    case searchResults(query: String)
    case settings
    case editProfile
    case createPost
    case notifications
    case topics
    case moderation
    case invite
    case lookup
}

/// Modal presentation destinations
enum ModalDestination: Identifiable {
    case createPost
    case editProfile
    case settings
    case imageViewer(imageURL: String)
    case reportContent(contentId: String)
    
    var id: String {
        switch self {
        case .createPost: return "createPost"
        case .editProfile: return "editProfile"
        case .settings: return "settings"
        case .imageViewer(let url): return "imageViewer_\(url)"
        case .reportContent(let id): return "reportContent_\(id)"
        }
    }
}

/// Sheet presentation destinations
enum SheetDestination: Identifiable {
    case filters
    case sortOptions
    case sharePost(postId: String)
    case userList(type: UserListType)
    
    var id: String {
        switch self {
        case .filters: return "filters"
        case .sortOptions: return "sortOptions"
        case .sharePost(let id): return "sharePost_\(id)"
        case .userList(let type): return "userList_\(type.rawValue)"
        }
    }
    
    enum UserListType: String {
        case followers = "followers"
        case following = "following"
        case likes = "likes"
        case reposts = "reposts"
    }
}

/// Full screen cover destinations
enum FullScreenDestination: Identifiable {
    case onboarding
    case camera
    case videoPlayer(videoURL: String)
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .camera: return "camera"
        case .videoPlayer(let url): return "videoPlayer_\(url)"
        }
    }
}

/// Alert destinations
struct AlertDestination: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let style: Style
        let action: (() -> Void)?
        
        enum Style {
            case `default`
            case cancel
            case destructive
        }
    }
}

/// Toast notification destinations
struct ToastDestination: Identifiable {
    let id = UUID()
    let message: String
    let type: GlassToast.ToastType
    let duration: TimeInterval
    let isDismissible: Bool
    
    init(
        message: String,
        type: GlassToast.ToastType = .info,
        duration: TimeInterval? = nil,
        isDismissible: Bool = true
    ) {
        self.message = message
        self.type = type
        self.duration = duration ?? type.defaultDuration
        self.isDismissible = isDismissible
    }
}