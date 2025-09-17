# Core Architecture

This directory contains the foundational systems for the Dirt iOS app, providing clean separation of concerns and dependency injection.

## Directory Structure

```
Core/
├── Design/          # Material Glass design system components
├── Navigation/      # Navigation coordination and routing
├── Services/        # Core infrastructure services and service container
└── README.md        # This file
```

## Service Container

The `ServiceContainer` class provides centralized dependency injection for all app services:

### Usage

```swift
// Access services through environment
struct MyView: View {
    @Environment(\.services) var services
    
    var body: some View {
        // Use services
        let mediaService = services.mediaService
        let searchService = services.searchService
        // ...
    }
}

// Or access directly
let container = ServiceContainer.shared
let mediaService = container.mediaService
```

### Available Services

- **Media Services**: `mediaService` - Enhanced media upload and processing
- **Search Services**: `searchService` - Enhanced search with filtering and caching
- **Content Services**: `postService`, `postSubmissionService`, `moderationService`
- **User Services**: `interestsService`, `mentionsService`, `biometricAuthService`
- **UI Services**: `themeService`, `alertsService`, `tutorialService`
- **Core Services**: `supabaseManager`, `performanceService`, `analyticsService`

### Service Registration

```swift
// Register custom service instances
container.register(myCustomService, for: \.customService)

// Retrieve services by type
let service = container.service(of: MyServiceType.self)
```

### Lifecycle Management

```swift
// Initialize critical services early in app lifecycle
container.initializeCriticalServices()

// Cleanup when app terminates
container.cleanup()
```

## Design Principles

1. **Lazy Loading**: Services are only instantiated when first accessed
2. **Singleton Pattern**: Each service maintains a single instance throughout app lifecycle
3. **Environment Integration**: Services are accessible through SwiftUI environment
4. **Type Safety**: Compile-time service resolution with proper typing
5. **Testability**: Factory methods for creating test containers with mock services

## Testing

The service container includes comprehensive unit tests covering:

- Singleton behavior
- Lazy loading
- Service registration and retrieval
- Environment integration
- Concurrent access
- Performance characteristics

## Future Enhancements

- Service dependency graph validation
- Service health monitoring
- Dynamic service replacement for A/B testing
- Service metrics and analytics