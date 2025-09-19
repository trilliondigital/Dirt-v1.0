# Design Document

## Overview

The tea-inspired dating reviews feature integrates into the existing Dirt app architecture, leveraging SwiftUI for the user interface and following the established patterns for navigation, state management, and data flow. The design emphasizes a clean, intuitive user experience with smooth animations and responsive layouts.

## Architecture

### Navigation Architecture
- **TabView-based Navigation**: Primary navigation using SwiftUI TabView
- **NavigationStack**: Secondary navigation within each tab using NavigationStack
- **Deep Linking**: URL-based navigation for external links and notifications
- **State Management**: Centralized navigation state using ObservableObject pattern

### Component Hierarchy
```
MainTabView (Root)
├── FeedView (Tab 1)
├── ReviewsView (Tab 2) 
├── CreatePostView (Tab 3)
├── NotificationsView (Tab 4)
└── ProfileView (Tab 5)
```

## Components and Interfaces

### MainTabView
- **Purpose**: Root navigation container managing tab selection and badge states
- **State**: Current tab selection, notification badges, deep link handling
- **Dependencies**: NotificationBadgeManager, NavigationCoordinator

### FeedView & FeedViewModel
- **Purpose**: Infinite scroll feed displaying mixed content (posts, reviews)
- **Features**: Pull-to-refresh, infinite scroll, content filtering
- **State**: Content array, loading states, filter preferences
- **Dependencies**: ContentService, FilterService

### ReviewsView & ReviewsViewModel  
- **Purpose**: Grid-based review browsing with filtering capabilities
- **Features**: Responsive grid layout, sorting options, search functionality
- **State**: Reviews array, grid configuration, sort preferences
- **Dependencies**: ReviewService, SearchService

### FilterSheet
- **Purpose**: Modal interface for content filtering and sorting
- **Features**: Multi-select filters, sort options, clear/apply actions
- **State**: Active filters, sort selection, temporary filter state

## Data Models

### NavigationState
```swift
class NavigationState: ObservableObject {
    @Published var selectedTab: Tab = .feed
    @Published var notificationBadges: [Tab: Int] = [:]
    @Published var deepLinkPath: String?
}
```

### ContentFilter
```swift
struct ContentFilter {
    var sortBy: SortOption = .recent
    var categories: Set<Category> = []
    var dateRange: DateRange?
    var ratingRange: ClosedRange<Double>?
}
```

## Error Handling

### Network Errors
- Retry mechanisms with exponential backoff
- Offline state detection and caching
- User-friendly error messages with action buttons

### Loading States
- Skeleton loading for initial content
- Progressive loading indicators for infinite scroll
- Pull-to-refresh visual feedback

## Testing Strategy

### Unit Tests
- ViewModel logic and state management
- Filter and sort functionality
- Navigation state transitions
- Error handling scenarios

### UI Tests
- Tab navigation flows
- Content loading and refresh
- Filter application and clearing
- Deep link navigation

### Integration Tests
- End-to-end content browsing flows
- Navigation between different sections
- Notification badge updates