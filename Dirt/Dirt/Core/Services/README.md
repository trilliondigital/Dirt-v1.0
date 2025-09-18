# Core Services

This directory contains the core infrastructure services and service container that provide centralized dependency injection and service management throughout the Dirt iOS app.

## Overview

The services architecture provides a clean separation of concerns with centralized dependency injection, proper error handling, and comprehensive service management.

## Components

### Service Container
- **`ServiceContainer.swift`** - Central dependency injection container managing all app services

### Core Infrastructure Services
- **`SupabaseManager.swift`** - Supabase client management and configuration
- **`NetworkMonitor.swift`** - Network connectivity monitoring and status
- **`AnalyticsService.swift`** - Event tracking and analytics
- **`PerformanceService.swift`** - Performance monitoring and optimization
- **`PerformanceOptimizationService.swift`** - Advanced performance optimization utilities
- **`ThemeService.swift`** - Theme and appearance management

### Error Handling
- **`ErrorHandlingManager.swift`** - Centralized error handling coordination
- **`ErrorHandlingService.swift`** - Error processing and categorization
- **`ErrorPresenter.swift`** - User-facing error message presentation

## Service Container Architecture

### Dependency Injection

The `ServiceContainer` provides centralized service management with lazy loading:

```swift
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Core services
    lazy var supabaseManager = SupabaseManager()
    lazy var networkMonitor = NetworkMonitor()
    lazy var analyticsService = AnalyticsService()
    lazy var performanceService = PerformanceService()
    lazy var themeService = ThemeService()
    
    // Feature services (consolidated)
    lazy var mediaService = MediaService()
    lazy var searchService = SearchService()
    lazy var postService = PostService()
    lazy var moderationService = ModerationService()
    
    // Error handling
    lazy var errorHandlingManager = ErrorHandlingManager()
}
```

### Environment Integration

Services are accessible through SwiftUI environment:

```swift
// Environment key
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// Usage in views
struct MyView: View {
    @Environment(\.services) var services
    
    var body: some View {
        Text("Content")
            .onAppear {
                services.analyticsService.track(.viewAppeared)
            }
    }
}
```

## Core Services

### Supabase Manager

Manages Supabase client configuration and authentication:

```swift
class SupabaseManager: ObservableObject {
    let client: SupabaseClient
    @Published var isAuthenticated = false
    
    func signIn(email: String, password: String) async throws {
        // Authentication logic
    }
    
    func signOut() async throws {
        // Sign out logic
    }
}
```

### Network Monitor

Monitors network connectivity and provides status updates:

```swift
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    
    func startMonitoring() {
        // Start network monitoring
    }
}
```

### Analytics Service

Tracks user events and app performance:

```swift
class AnalyticsService {
    func track(_ event: AnalyticsEvent) {
        // Event tracking logic
    }
    
    func setUserProperty(_ property: String, value: Any) {
        // User property setting
    }
}
```

### Performance Service

Monitors app performance and provides optimization insights:

```swift
class PerformanceService {
    func startPerformanceMonitoring() {
        // Performance monitoring setup
    }
    
    func measureOperation<T>(_ operation: () throws -> T) rethrows -> T {
        // Performance measurement
    }
}
```

### Theme Service

Manages app theme and appearance settings:

```swift
class ThemeService: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var materialIntensity: MaterialIntensity = .standard
    
    func setTheme(_ theme: AppTheme) {
        // Theme switching logic
    }
}
```

## Error Handling System

### Centralized Error Management

The error handling system provides consistent error processing:

```swift
class ErrorHandlingManager {
    func handle(_ error: Error, context: ErrorContext) {
        // Centralized error processing
        let userMessage = ErrorPresenter.message(for: error)
        // Present to user through appropriate channel
    }
}

class ErrorPresenter {
    static func message(for error: Error) -> String {
        // Convert technical errors to user-friendly messages
    }
}
```

### Error Categories

Errors are categorized for appropriate handling:

```swift
enum AppError: Error {
    case network(NetworkError)
    case authentication(AuthError)
    case validation(ValidationError)
    case storage(StorageError)
    case unknown(Error)
}
```

## Service Lifecycle

### Initialization

Services are initialized lazily when first accessed:

```swift
// In App.swift
@main
struct DirtApp: App {
    let services = ServiceContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.services, services)
                .onAppear {
                    services.initializeCriticalServices()
                }
        }
    }
}
```

### Cleanup

Proper cleanup when app terminates:

```swift
extension ServiceContainer {
    func cleanup() {
        networkMonitor.stopMonitoring()
        analyticsService.flush()
        performanceService.stopMonitoring()
    }
}
```

## Testing

### Mock Services

Test containers with mock services for unit testing:

```swift
extension ServiceContainer {
    static func mock() -> ServiceContainer {
        let container = ServiceContainer()
        container.supabaseManager = MockSupabaseManager()
        container.networkMonitor = MockNetworkMonitor()
        return container
    }
}
```

### Service Testing

Each service includes comprehensive unit tests:
- Initialization and configuration
- Core functionality
- Error handling
- Performance characteristics
- Memory management

## Performance Considerations

### Lazy Loading

Services are only instantiated when needed:
- Reduces app startup time
- Minimizes memory footprint
- Allows for conditional service loading

### Singleton Pattern

Each service maintains a single instance:
- Consistent state across the app
- Efficient resource usage
- Proper lifecycle management

### Memory Management

Proper memory management for services:
- Weak references where appropriate
- Cleanup of resources on deallocation
- Monitoring for memory leaks

## Security

### Secure Configuration

Services handle sensitive data securely:
- API keys stored in secure keychain
- Network requests use certificate pinning
- User data encrypted at rest

### Privacy

Services respect user privacy:
- Minimal data collection
- User consent for analytics
- Data anonymization where possible

## Contributing

When adding new services:
1. Follow the established service pattern
2. Include proper error handling
3. Add comprehensive unit tests
4. Update service container registration
5. Document service interface and usage
6. Consider performance implications

## Future Enhancements

- Service health monitoring and alerting
- Dynamic service configuration
- A/B testing for service implementations
- Service metrics and performance analytics
- Automatic service dependency resolution