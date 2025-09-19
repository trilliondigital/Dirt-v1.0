# Features

This directory contains all feature modules for the Dirt iOS app, organized by functionality with clear boundaries and minimal inter-feature dependencies.

## Overview

Each feature is self-contained with its own views, view models, and feature-specific services, following a consistent modular architecture pattern.

## Feature Structure

Each feature follows this standard structure:

```
Features/[FeatureName]/
├── Views/              # SwiftUI views for the feature
├── ViewModels/         # ObservableObject view models (if needed)
├── Models/             # Feature-specific models (if needed)
├── Services/           # Feature-specific services (if needed)
├── Components/         # Feature-specific reusable components (if needed)
└── README.md           # Feature-specific documentation
```

## Available Features

### Core Features
- **`Feed/`** - Main content feed with post display and interactions
- **`Search/`** - Global search with filtering and saved searches
- **`CreatePost/`** - Post creation with media upload and validation
- **`Profile/`** - User profile management and settings

### Secondary Features
- **`Notifications/`** - Activity and keyword alert notifications
- **`Settings/`** - App configuration and user preferences
- **`Onboarding/`** - User onboarding and tutorial flows
- **`Moderation/`** - Content moderation and reporting

### Specialized Features
- **`Home/`** - Home screen and navigation hub
- **`Invite/`** - User invitation and referral system
- **`Lookup/`** - Content lookup and discovery wizard
- **`Topics/`** - Topic-based content organization

## Architecture Principles

### Feature Boundaries

Features communicate through:
- **Shared Services**: Core services from `Core/Services/`
- **Shared Models**: Common data models from `Shared/Models/`
- **Navigation**: Centralized navigation through `Core/Navigation/`
- **Events**: Decoupled communication through event system

Features should NOT:
- Directly import other feature modules
- Share feature-specific view models
- Have tight coupling with other features

### Dependency Flow

```
Features → Core Services → Shared Utilities
Features → Shared Models
Features ← Core Navigation (for routing)
```

### Material Glass Integration

All features implement Material Glass design system:
- Use components from `Core/Design/GlassComponents.swift`
- Follow Material Design patterns from `Core/Design/MaterialDesignSystem.swift`
- Implement consistent animations from `Core/Design/MotionSystem.swift`
- Maintain accessibility standards from `Core/Design/AccessibilitySystem.swift`

## Service Integration

### Accessing Core Services

Features access services through the service container:

```swift
struct FeatureView: View {
    @Environment(\.services) var services
    
    var body: some View {
        // Use services
        let searchService = services.searchService
        let mediaService = services.mediaService
        // ...
    }
}
```

### Feature-Specific Services

Some features may have their own services for complex logic:

```swift
// Feature-specific service
class CreatePostService: ObservableObject {
    private let mediaService: MediaService
    private let postService: PostService
    
    init(services: ServiceContainer) {
        self.mediaService = services.mediaService
        self.postService = services.postService
    }
    
    func createPost(_ content: PostContent) async throws {
        // Feature-specific post creation logic
    }
}
```

## Navigation Integration

Features integrate with centralized navigation:

```swift
struct FeatureView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        Button("Navigate") {
            coordinator.navigate(to: .postDetail(id: "123"))
        }
    }
}
```

## Testing Strategy

### Feature Testing

Each feature includes:
- **Unit Tests**: Test view models and feature-specific logic
- **Integration Tests**: Test feature integration with core services
- **UI Tests**: Test Material Glass implementation and accessibility
- **Navigation Tests**: Test navigation flows within and between features

### Test Organization

```
DirtTests/
├── [FeatureName]Tests.swift           # Core feature logic tests
├── [FeatureName]MaterialGlassTests.swift  # Material Glass implementation tests
├── [FeatureName]AccessibilityTests.swift  # Accessibility compliance tests
└── [FeatureName]IntegrationTests.swift    # Service integration tests
```

## Performance Considerations

### Lazy Loading

Features are loaded on-demand:
- Views are only created when navigated to
- Heavy resources loaded asynchronously
- Proper memory management for feature resources

### State Management

Efficient state management within features:
- Use `@StateObject` for feature-owned state
- Use `@ObservedObject` for shared state
- Minimize state duplication across features

## Accessibility

### Feature Accessibility

All features implement comprehensive accessibility:
- VoiceOver support with descriptive labels
- Dynamic Type support for text scaling
- High contrast mode compatibility
- Reduced motion respect for animations
- Keyboard navigation support

### Testing Accessibility

Each feature includes accessibility tests:
- VoiceOver navigation tests
- Dynamic Type scaling tests
- High contrast rendering tests
- Keyboard navigation tests

## Contributing

### Adding New Features

1. **Create Feature Directory**: Follow the standard structure
2. **Implement Core Views**: Start with main feature views
3. **Add Material Glass**: Implement Material Glass design system
4. **Integrate Services**: Use core services through service container
5. **Add Navigation**: Integrate with navigation coordinator
6. **Include Tests**: Add comprehensive test coverage
7. **Document Feature**: Create feature-specific README

### Modifying Existing Features

1. **Maintain Boundaries**: Don't introduce cross-feature dependencies
2. **Update Tests**: Ensure all tests continue to pass
3. **Preserve Accessibility**: Maintain accessibility compliance
4. **Follow Patterns**: Use established patterns from other features
5. **Update Documentation**: Keep README files current

## Migration Guide

### From Legacy Architecture

When migrating features from legacy architecture:

1. **Extract Feature Logic**: Separate feature-specific from shared logic
2. **Update Service Usage**: Use service container instead of direct instantiation
3. **Implement Material Glass**: Update UI to use Material Glass components
4. **Add Navigation Integration**: Use centralized navigation coordinator
5. **Update Tests**: Migrate and enhance test coverage
6. **Document Changes**: Update feature documentation

## Future Enhancements

### Planned Features

- **Analytics Dashboard**: User analytics and insights
- **Advanced Moderation**: Enhanced content moderation tools
- **Social Features**: Enhanced social interaction features
- **Personalization**: AI-driven content personalization

### Architecture Improvements

- Feature-level dependency injection
- Plugin architecture for feature extensions
- Feature flag system for gradual rollouts
- Performance monitoring per feature
- Automated feature testing pipeline

## Performance Monitoring

### Feature Metrics

Each feature tracks:
- Load time and performance
- User engagement metrics
- Error rates and crash reports
- Memory usage and optimization opportunities

### Optimization

Continuous optimization of features:
- Performance profiling and improvement
- Memory usage optimization
- Battery usage minimization
- Network usage optimization