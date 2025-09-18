# Navigation System

This directory contains the navigation coordination and routing components that manage app-wide navigation flows with Material Glass transitions.

## Overview

The navigation system provides centralized navigation management, Material Glass tab bar implementation, and coordinated navigation flows throughout the app.

## Components

### Core Navigation
- **`NavigationCoordinator.swift`** - Central navigation coordinator managing app-wide navigation state
- **`NavigationRouter.swift`** - Type-safe routing system for navigation between features
- **`MaterialGlassTabBar.swift`** - Material Glass implementation of the main tab bar

## Architecture

### Navigation Coordinator

The `NavigationCoordinator` manages navigation state and provides centralized navigation logic:

```swift
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .feed
    @Published var navigationPath = NavigationPath()
    
    func navigate(to destination: AppDestination) {
        // Centralized navigation logic
    }
    
    func presentModal(_ modal: AppModal) {
        // Modal presentation logic
    }
}
```

### Navigation Router

Type-safe routing system that defines all possible navigation destinations:

```swift
enum AppDestination: Hashable {
    case postDetail(id: String)
    case userProfile(id: String)
    case search(query: String?)
    case createPost
    // ... other destinations
}

enum AppModal: Identifiable {
    case settings
    case reportPost(id: String)
    case imageViewer(url: URL)
    // ... other modals
}
```

## Usage

### Basic Navigation

```swift
struct ContentView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            TabView(selection: $coordinator.selectedTab) {
                FeedView()
                    .tabItem { Label("Feed", systemImage: "house") }
                    .tag(AppTab.feed)
                
                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(AppTab.search)
                
                // ... other tabs
            }
            .navigationDestination(for: AppDestination.self) { destination in
                coordinator.view(for: destination)
            }
        }
        .environmentObject(coordinator)
    }
}
```

### Programmatic Navigation

```swift
struct SomeView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        Button("View Post") {
            coordinator.navigate(to: .postDetail(id: "123"))
        }
        
        Button("Open Settings") {
            coordinator.presentModal(.settings)
        }
    }
}
```

### Material Glass Tab Bar

The custom tab bar provides Material Glass effects with proper accessibility:

```swift
MaterialGlassTabBar(
    selectedTab: $coordinator.selectedTab,
    tabs: [
        .init(tab: .feed, icon: "house", label: "Feed"),
        .init(tab: .search, icon: "magnifyingglass", label: "Search"),
        .init(tab: .notifications, icon: "bell", label: "Notifications"),
        .init(tab: .profile, icon: "person", label: "Profile")
    ]
)
```

## Navigation Patterns

### Deep Linking

The navigation system supports deep linking through URL-based navigation:

```swift
// Handle deep link
coordinator.handleDeepLink(url: "dirt://post/123")

// Navigate to specific content
coordinator.navigate(to: .postDetail(id: "123"))
```

### Modal Presentation

Consistent modal presentation with Material Glass backgrounds:

```swift
// Present modal
coordinator.presentModal(.reportPost(id: "123"))

// Dismiss modal
coordinator.dismissModal()
```

### Tab Switching

Programmatic tab switching with state preservation:

```swift
// Switch to search tab with query
coordinator.switchToSearch(query: "example")

// Switch to profile tab
coordinator.selectedTab = .profile
```

## Material Glass Integration

### Tab Bar Styling

The Material Glass tab bar uses:
- `.thinMaterial` background for subtle transparency
- Proper contrast ratios for accessibility
- Smooth transitions between tabs
- Haptic feedback for tab selection

### Navigation Transitions

Custom transitions that work with Material Glass:
- Slide transitions for hierarchical navigation
- Modal presentations with glass backgrounds
- Smooth animations that respect reduced motion settings

## Accessibility

### VoiceOver Support

All navigation components include proper accessibility:
- Descriptive labels for tab items
- Navigation announcements for screen changes
- Proper focus management during navigation

### Keyboard Navigation

Full keyboard navigation support:
- Tab key navigation through tab bar
- Return key activation for navigation items
- Escape key for modal dismissal

## Testing

Navigation components include comprehensive tests:
- Navigation flow tests
- Deep linking tests
- Accessibility navigation tests
- Material Glass rendering tests

## Performance

### Lazy Loading

Navigation destinations are lazily loaded to improve performance:
- Views are only created when navigated to
- Heavy content is loaded on-demand
- Proper memory management for navigation stack

### State Management

Efficient state management for navigation:
- Minimal state storage in coordinator
- Proper cleanup of navigation state
- Memory-efficient navigation path management

## Contributing

When adding new navigation features:
1. Define new destinations in `AppDestination` enum
2. Add routing logic to `NavigationRouter`
3. Update coordinator with new navigation methods
4. Include accessibility support
5. Add comprehensive tests
6. Update this documentation

## Future Enhancements

- Navigation analytics and tracking
- A/B testing for navigation flows
- Advanced deep linking with parameters
- Navigation state persistence across app launches