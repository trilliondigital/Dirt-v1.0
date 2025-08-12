import Foundation
import SwiftUI

// MARK: - Deep Link Types

enum DeepLinkDestination: Hashable {
    case home
    case profile(userId: String)
    case post(postId: String)
    case search(query: String?)
    case settings
    case notifications
    case createPost
    case topic(topicId: String)
    case invite(code: String)
    case resetPassword(token: String)
    
    var path: String {
        switch self {
        case .home:
            return "/home"
        case .profile(let userId):
            return "/profile/\(userId)"
        case .post(let postId):
            return "/post/\(postId)"
        case .search(let query):
            return "/search" + (query != nil ? "?q=\(query!)" : "")
        case .settings:
            return "/settings"
        case .notifications:
            return "/notifications"
        case .createPost:
            return "/create"
        case .topic(let topicId):
            return "/topic/\(topicId)"
        case .invite(let code):
            return "/invite/\(code)"
        case .resetPassword(let token):
            return "/reset-password?token=\(token)"
        }
    }
}

// MARK: - Deep Link Service

@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()
    
    @Published var pendingDestination: DeepLinkDestination?
    @Published var currentDestination: DeepLinkDestination = .home
    
    private init() {}
    
    func handleURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return false
        }
        
        // Handle different URL schemes
        switch host {
        case "dirt.app", "www.dirt.app":
            return handleWebURL(components)
        default:
            return handleCustomScheme(components)
        }
    }
    
    private func handleWebURL(_ components: URLComponents) -> Bool {
        let path = components.path
        let queryItems = components.queryItems
        
        switch path {
        case "/home":
            navigate(to: .home)
        case let path where path.hasPrefix("/profile/"):
            let userId = String(path.dropFirst("/profile/".count))
            navigate(to: .profile(userId: userId))
        case let path where path.hasPrefix("/post/"):
            let postId = String(path.dropFirst("/post/".count))
            navigate(to: .post(postId: postId))
        case "/search":
            let query = queryItems?.first(where: { $0.name == "q" })?.value
            navigate(to: .search(query: query))
        case "/settings":
            navigate(to: .settings)
        case "/notifications":
            navigate(to: .notifications)
        case "/create":
            navigate(to: .createPost)
        case let path where path.hasPrefix("/topic/"):
            let topicId = String(path.dropFirst("/topic/".count))
            navigate(to: .topic(topicId: topicId))
        case let path where path.hasPrefix("/invite/"):
            let code = String(path.dropFirst("/invite/".count))
            navigate(to: .invite(code: code))
        case "/reset-password":
            if let token = queryItems?.first(where: { $0.name == "token" })?.value {
                navigate(to: .resetPassword(token: token))
            }
        default:
            return false
        }
        
        return true
    }
    
    private func handleCustomScheme(_ components: URLComponents) -> Bool {
        // Handle dirt:// scheme
        let path = components.path
        
        switch path {
        case "/open":
            navigate(to: .home)
        default:
            return false
        }
        
        return true
    }
    
    func navigate(to destination: DeepLinkDestination) {
        if SupabaseManager.shared.isAuthenticated {
            currentDestination = destination
            pendingDestination = nil
        } else {
            // Store for after authentication
            pendingDestination = destination
        }
    }
    
    func handlePendingNavigation() {
        if let pending = pendingDestination {
            currentDestination = pending
            pendingDestination = nil
        }
    }
    
    func generateShareURL(for destination: DeepLinkDestination) -> URL? {
        let baseURL = "https://dirt.app"
        return URL(string: baseURL + destination.path)
    }
}

// MARK: - Navigation Coordinator

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var homePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var notificationsPath = NavigationPath()
    
    private let deepLinkService = DeepLinkService.shared
    
    init() {
        // Listen for deep link changes
        deepLinkService.$currentDestination
            .sink { [weak self] destination in
                self?.handleDeepLink(destination)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .home:
            selectedTab = .home
            homePath = NavigationPath()
            
        case .profile(let userId):
            selectedTab = .profile
            profilePath = NavigationPath()
            profilePath.append(ProfileDestination.user(userId))
            
        case .post(let postId):
            selectedTab = .home
            homePath = NavigationPath()
            homePath.append(HomeDestination.post(postId))
            
        case .search(let query):
            selectedTab = .search
            searchPath = NavigationPath()
            if let query = query {
                searchPath.append(SearchDestination.results(query))
            }
            
        case .settings:
            selectedTab = .profile
            profilePath = NavigationPath()
            profilePath.append(ProfileDestination.settings)
            
        case .notifications:
            selectedTab = .notifications
            notificationsPath = NavigationPath()
            
        case .createPost:
            selectedTab = .home
            homePath = NavigationPath()
            homePath.append(HomeDestination.createPost)
            
        case .topic(let topicId):
            selectedTab = .home
            homePath = NavigationPath()
            homePath.append(HomeDestination.topic(topicId))
            
        case .invite(let code):
            selectedTab = .home
            homePath = NavigationPath()
            homePath.append(HomeDestination.invite(code))
            
        case .resetPassword(let token):
            // Handle password reset
            break
        }
    }
}

// MARK: - App Tabs

enum AppTab: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case notifications = "Notifications"
    case profile = "Profile"
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
    
    var selectedSystemImage: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Navigation Destinations

enum HomeDestination: Hashable {
    case post(String)
    case createPost
    case topic(String)
    case invite(String)
}

enum SearchDestination: Hashable {
    case results(String)
    case filters
}

enum ProfileDestination: Hashable {
    case user(String)
    case settings
    case editProfile
}

// MARK: - SwiftUI Integration

struct DeepLinkHandler: ViewModifier {
    @StateObject private var deepLinkService = DeepLinkService.shared
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                _ = deepLinkService.handleURL(url)
            }
    }
}

extension View {
    func handleDeepLinks() -> some View {
        modifier(DeepLinkHandler())
    }
}

import Combine
