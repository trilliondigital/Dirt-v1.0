# ADR-003: Feature Module Boundaries

## Status
Accepted

## Context

The Dirt iOS app had grown organically with features that were becoming increasingly interdependent, leading to:
- Tight coupling between feature modules
- Difficulty testing features in isolation
- Unclear ownership of shared functionality
- Challenges in parallel development
- Complex dependency graphs

The app needed clear feature boundaries that would:
- Enable independent feature development and testing
- Reduce coupling between features
- Clarify ownership of code and functionality
- Support modular architecture principles
- Allow for future feature extraction or replacement

## Decision

We decided to establish strict feature module boundaries with the following principles:

### Feature Structure
Each feature follows a consistent structure:
```
Features/[FeatureName]/
├── Views/              # SwiftUI views for the feature
├── ViewModels/         # ObservableObject view models (if needed)
├── Models/             # Feature-specific models (if needed)
├── Services/           # Feature-specific services (if needed)
├── Components/         # Feature-specific reusable components (if needed)
└── README.md           # Feature-specific documentation
```

### Communication Rules
Features communicate through:
- **Core Services**: Shared services from `Core/Services/`
- **Shared Models**: Common data models from `Shared/Models/`
- **Navigation**: Centralized navigation through `Core/Navigation/`
- **Events**: Decoupled communication through event system

### Prohibited Dependencies
Features must NOT:
- Directly import other feature modules
- Share feature-specific view models
- Have tight coupling with other features
- Access other features' internal components

### Dependency Flow
```
Features → Core Services → Shared Utilities
Features → Shared Models
Features ← Core Navigation (for routing)
```

## Alternatives Considered

### 1. Monolithic Feature Structure
- **Pros**: Simple, no boundaries to maintain
- **Cons**: Tight coupling, difficult testing, poor scalability
- **Rejected**: Current problematic pattern

### 2. Micro-Frontend Architecture
- **Pros**: Maximum isolation, independent deployment
- **Cons**: Over-engineering for mobile app, communication complexity
- **Rejected**: Too complex for current needs

### 3. Layered Architecture
- **Pros**: Clear separation of concerns
- **Cons**: Doesn't address feature-level boundaries, can become rigid
- **Rejected**: Doesn't solve feature coupling issues

### 4. Plugin Architecture
- **Pros**: Maximum flexibility, runtime feature loading
- **Cons**: Complex implementation, potential performance issues
- **Rejected**: Unnecessary complexity for current requirements

## Consequences

### Positive
- **Independent Development**: Teams can work on features without conflicts
- **Testability**: Features can be tested in isolation with mock dependencies
- **Maintainability**: Clear ownership and boundaries reduce maintenance burden
- **Scalability**: Easy to add new features without affecting existing ones
- **Reusability**: Shared components are properly abstracted and reusable
- **Parallel Development**: Multiple developers can work on different features simultaneously

### Negative
- **Initial Overhead**: Setting up proper boundaries requires upfront work
- **Communication Complexity**: Need well-defined interfaces for feature communication
- **Potential Duplication**: Some code might be duplicated across features
- **Learning Curve**: Developers need to understand and follow boundary rules

### Risks and Mitigations

**Risk**: Features become too isolated and duplicate functionality
**Mitigation**: Regular architecture reviews, promote shared utilities for common functionality

**Risk**: Communication between features becomes too complex
**Mitigation**: Use centralized navigation and event system, avoid direct feature-to-feature communication

**Risk**: Boundaries become too rigid and hinder development
**Mitigation**: Regular review of boundaries, allow for evolution as app grows

## Implementation Guidelines

### Feature Communication Patterns

#### Service Access
```swift
struct FeatureView: View {
    @Environment(\.services) var services
    
    var body: some View {
        // Access shared services
        let searchService = services.searchService
        let mediaService = services.mediaService
    }
}
```

#### Navigation
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

#### Event Communication
```swift
// Publish events for other features to observe
NotificationCenter.default.post(
    name: .postCreated,
    object: nil,
    userInfo: ["postId": postId]
)

// Observe events from other features
NotificationCenter.default.addObserver(
    forName: .postCreated,
    object: nil,
    queue: .main
) { notification in
    // Handle event
}
```

### Shared Component Guidelines

#### When to Create Shared Components
- Component is used by 3+ features
- Component represents core app functionality
- Component has no feature-specific logic

#### Where to Place Shared Components
- **UI Components**: `Shared/Components/`
- **Business Logic**: `Core/Services/`
- **Data Models**: `Shared/Models/`
- **Utilities**: `Shared/Utilities/`

### Feature-Specific Services

Features may have their own services for complex logic:
```swift
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

## Migration Strategy

### Phase 1: Identify Boundaries
- Audit existing feature dependencies
- Identify shared functionality to extract
- Plan migration order based on dependencies

### Phase 2: Extract Shared Components
- Move truly shared components to appropriate shared locations
- Update imports and references
- Ensure all features continue to work

### Phase 3: Enforce Boundaries
- Remove direct feature-to-feature imports
- Implement proper communication patterns
- Add linting rules to prevent boundary violations

### Phase 4: Optimize
- Review and optimize shared components
- Consolidate duplicate functionality
- Improve communication patterns

## Testing Strategy

### Feature Isolation Tests
- Test each feature with mock dependencies
- Verify features work independently
- Test feature communication through defined interfaces

### Integration Tests
- Test feature interactions through shared services
- Test navigation between features
- Test event communication between features

### Boundary Violation Detection
- Automated tests to detect direct feature imports
- Linting rules to prevent boundary violations
- Architecture tests to validate dependency flow

## Enforcement Mechanisms

### Code Review Guidelines
- Check for direct feature imports
- Verify proper use of shared services
- Ensure new shared components are truly reusable

### Automated Checks
- Linting rules for import restrictions
- Architecture tests for dependency validation
- CI checks for boundary violations

### Documentation
- Clear guidelines in feature READMEs
- Architecture decision records
- Code examples and patterns

## Related Decisions
- [ADR-002: Service Container Pattern](ADR-002-service-container-pattern.md) - Service access pattern
- [ADR-004: Centralized Navigation](ADR-004-centralized-navigation.md) - Navigation between features
- [ADR-007: Dependency Injection Pattern](ADR-007-dependency-injection-pattern.md) - Dependency management

## Review Date
This decision should be reviewed in 6 months to assess:
- Effectiveness of feature boundaries in practice
- Developer satisfaction with boundary rules
- Need for adjustments to communication patterns
- Impact on development velocity and code quality