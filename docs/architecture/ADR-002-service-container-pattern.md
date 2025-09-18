# ADR-002: Service Container Pattern

## Status
Accepted

## Context

The Dirt iOS app had grown organically with services being instantiated directly in views and view models, leading to:
- Tight coupling between UI and service implementations
- Difficulty testing components in isolation
- Inconsistent service lifecycle management
- Duplicate service instances across the app
- No centralized configuration for services

The app needed a clean dependency injection pattern that would:
- Decouple UI components from service implementations
- Enable easy testing with mock services
- Provide centralized service lifecycle management
- Support lazy loading for performance
- Allow for service configuration and swapping

## Decision

We decided to implement a Service Container pattern with the following characteristics:

### Core Architecture
```swift
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Lazy-loaded services
    lazy var supabaseManager = SupabaseManager()
    lazy var mediaService = MediaService()
    lazy var searchService = SearchService()
    // ... other services
}
```

### Environment Integration
Services are accessible through SwiftUI environment:
```swift
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
```

### Usage Pattern
```swift
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

## Alternatives Considered

### 1. Direct Service Instantiation
- **Pros**: Simple, no additional abstraction
- **Cons**: Tight coupling, difficult testing, no lifecycle management
- **Rejected**: Current problematic pattern

### 2. Protocol-Based Dependency Injection
- **Pros**: Maximum flexibility, protocol-oriented design
- **Cons**: More complex setup, potential over-engineering
- **Rejected**: Too complex for current needs

### 3. Third-Party DI Framework
- **Pros**: Proven implementation, advanced features
- **Cons**: External dependency, learning curve, potential overkill
- **Rejected**: Wanted lightweight, native solution

### 4. Singleton Services
- **Pros**: Simple global access
- **Cons**: Global state issues, difficult testing, tight coupling
- **Rejected**: Poor testability and flexibility

## Consequences

### Positive
- **Loose Coupling**: UI components are decoupled from service implementations
- **Testability**: Easy to inject mock services for testing
- **Performance**: Lazy loading reduces startup time and memory usage
- **Consistency**: Single source of truth for service instances
- **Flexibility**: Easy to swap service implementations
- **Lifecycle Management**: Centralized service initialization and cleanup
- **SwiftUI Integration**: Natural integration with SwiftUI environment system

### Negative
- **Indirection**: Additional layer between UI and services
- **Learning Curve**: Developers need to understand container pattern
- **Potential Overuse**: Risk of putting too much logic in container
- **Memory Management**: Need to be careful with service lifecycles

### Risks and Mitigations

**Risk**: Service container becomes a "god object"
**Mitigation**: Keep container focused on service management only, avoid business logic

**Risk**: Circular dependencies between services
**Mitigation**: Clear service dependency hierarchy, lazy loading breaks cycles

**Risk**: Performance impact from environment lookups
**Mitigation**: Environment access is optimized in SwiftUI, minimal performance impact

## Implementation Details

### Service Registration
```swift
extension ServiceContainer {
    func register<T>(_ service: T, for keyPath: WritableKeyPath<ServiceContainer, T>) {
        self[keyPath: keyPath] = service
    }
}
```

### Testing Support
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

### Lifecycle Management
```swift
extension ServiceContainer {
    func initializeCriticalServices() {
        // Initialize services that need early setup
        _ = supabaseManager
        _ = networkMonitor
    }
    
    func cleanup() {
        // Cleanup services on app termination
        networkMonitor.stopMonitoring()
        analyticsService.flush()
    }
}
```

## Migration Strategy

### Phase 1: Container Setup
- Create ServiceContainer class
- Register existing services
- Add environment integration

### Phase 2: Gradual Migration
- Update views one feature at a time
- Maintain backward compatibility during transition
- Add tests for container functionality

### Phase 3: Cleanup
- Remove direct service instantiation
- Clean up unused service creation code
- Optimize service initialization

## Performance Considerations

### Lazy Loading
- Services are only created when first accessed
- Reduces app startup time
- Minimizes memory footprint for unused services

### Memory Management
- Services maintain single instances throughout app lifecycle
- Proper cleanup prevents memory leaks
- Weak references used where appropriate

### Environment Access
- SwiftUI environment access is optimized
- Minimal performance overhead
- Cached lookups within view updates

## Testing Strategy

### Unit Tests
- Test service container initialization
- Test lazy loading behavior
- Test service registration and retrieval
- Test concurrent access safety

### Integration Tests
- Test service container with real services
- Test environment integration
- Test service lifecycle management

### Mock Testing
- Easy mock service injection for feature tests
- Isolated testing of UI components
- Predictable test behavior

## Related Decisions
- [ADR-005: Service Consolidation Strategy](ADR-005-service-consolidation-strategy.md) - Which services to consolidate
- [ADR-007: Dependency Injection Pattern](ADR-007-dependency-injection-pattern.md) - Detailed DI implementation

## Review Date
This decision should be reviewed in 3 months to assess:
- Developer adoption and satisfaction
- Performance impact on app startup and runtime
- Testing effectiveness with mock services
- Need for additional DI features