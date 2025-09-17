# Design Document

## Overview

This design outlines a systematic approach to refactor the Dirt iOS app from its current "vibe-coded" state into a clean, maintainable architecture with modern iOS 18+ Material Glass design patterns. The refactor will preserve all existing functionality while establishing clear architectural boundaries, implementing modern visual design, and creating a sustainable development foundation.

## Architecture

### Current State Analysis

The existing codebase has these strengths:
- Well-organized feature-based directory structure (`Features/`)
- Established design token system (`UI/Design/DesignTokens.swift`)
- Comprehensive service layer with proper separation of concerns
- Good test coverage for core utilities
- Clear documentation and requirements

Areas needing improvement:
- No Material Glass implementation despite being mentioned in PLAN.md
- Potential service duplication (e.g., `MediaService` vs `EnhancedMediaService`)
- Mixed abstraction levels in some components
- Inconsistent error handling patterns

### Target Architecture

```
Dirt/Dirt/
├── App/                    # App lifecycle and configuration
├── Core/                   # Foundational systems (new)
│   ├── Design/            # Material Glass design system
│   ├── Navigation/        # Navigation coordination
│   └── Services/          # Core infrastructure services
├── Features/              # Feature modules (existing, refined)
│   ├── Feed/
│   ├── Search/
│   ├── CreatePost/
│   └── [other features]/
├── Shared/                # Cross-feature shared components
│   ├── Models/
│   ├── Components/
│   └── Utilities/
└── Resources/             # Assets and localizations
```

## Components and Interfaces

### Core Design System

**Material Glass Design System** (`Core/Design/`)
- `MaterialDesignSystem.swift` - Central design system with Material effects
- `GlassComponents.swift` - Reusable glass-effect components
- `ColorTokens.swift` - Enhanced color system with Material support
- `TypographySystem.swift` - Typography scale and styles
- `MotionSystem.swift` - Animation and transition definitions

**Key Material Components:**
```swift
// Glass card with proper Material background
struct GlassCard: View {
    let content: () -> Content
    
    var body: some View {
        content()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// Glass navigation bar
struct GlassNavigationBar: View {
    // Implementation with .regularMaterial background
}

// Glass tab bar
struct GlassTabBar: View {
    // Implementation with .thinMaterial background
}
```

### Service Layer Consolidation

**Service Audit and Cleanup:**
1. **Merge Enhanced Services**: Consolidate `MediaService` + `EnhancedMediaService` into single `MediaService`
2. **Merge Search Services**: Consolidate `SearchService` + `EnhancedSearchService` 
3. **Service Dependencies**: Create clear dependency injection pattern
4. **Error Handling**: Standardize on `ErrorPresenter` pattern across all services

**Core Services Architecture:**
```swift
// Service container for dependency injection
class ServiceContainer: ObservableObject {
    lazy var mediaService = MediaService()
    lazy var searchService = SearchService()
    lazy var postService = PostService()
    // ... other services
}

// Environment key for service injection
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer()
}
```

### Feature Module Structure

Each feature module follows this pattern:
```
Features/[FeatureName]/
├── Views/              # SwiftUI views
├── ViewModels/         # ObservableObject view models
├── Models/             # Feature-specific models
├── Services/           # Feature-specific services (if needed)
└── Components/         # Feature-specific reusable components
```

**Feature Boundaries:**
- Features communicate through shared services, not direct dependencies
- Shared models live in `Shared/Models/`
- Cross-feature components live in `Shared/Components/`

## Data Models

### Enhanced Design Tokens

```swift
// Enhanced color system with Material Glass support
struct MaterialColors {
    // Glass backgrounds
    static let glassPrimary = Material.ultraThin
    static let glassSecondary = Material.thin
    static let glassThick = Material.thick
    
    // Semantic colors with glass variants
    static let cardBackground = Material.regularMaterial
    static let navigationBackground = Material.regularMaterial
    static let tabBarBackground = Material.thinMaterial
    
    // Existing semantic colors (preserved)
    static let background = Color(.systemBackground)
    // ... rest of existing colors
}

// Motion system for consistent animations
struct MaterialMotion {
    static let quickTransition: Animation = .easeInOut(duration: 0.2)
    static let standardTransition: Animation = .easeInOut(duration: 0.3)
    static let slowTransition: Animation = .easeInOut(duration: 0.5)
    
    // Glass-specific animations
    static let glassAppear: Animation = .spring(response: 0.6, dampingFraction: 0.8)
}
```

### Component Architecture

```swift
// Base component protocol for consistent behavior
protocol MaterialComponent: View {
    var glassStyle: Material { get }
    var cornerRadius: CGFloat { get }
}

// Reusable glass components
struct GlassButton: MaterialComponent {
    let title: String
    let action: () -> Void
    let glassStyle: Material = .thin
    let cornerRadius: CGFloat = 12
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.primary)
                .padding()
        }
        .background(glassStyle, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
```

## Error Handling

### Standardized Error Management

**Error Handling Strategy:**
1. All services use `ErrorPresenter.message(for:)` for user-facing messages
2. Consistent error types across the app
3. Graceful degradation for non-critical failures
4. Proper error logging for debugging

```swift
// Enhanced error presenter with Material Glass toast support
extension ErrorPresenter {
    static func presentGlassToast(for error: Error, in view: some View) -> some View {
        view.overlay(
            GlassToast(message: message(for: error))
                .animation(.glassAppear, value: error)
        )
    }
}
```

## Testing Strategy

### Test Organization

**Unit Tests:**
- Preserve existing test structure in `DirtTests/`
- Add tests for new Material components
- Test service consolidation doesn't break functionality
- Test error handling improvements

**Integration Tests:**
- Test feature module boundaries
- Test service dependency injection
- Test Material Glass component rendering

**UI Tests:**
- Test Material Glass visual consistency
- Test accessibility with Material backgrounds
- Test dark mode compatibility

### Testing Approach

1. **Preserve Existing Tests**: All current tests must continue passing
2. **Add Component Tests**: Test new Material Glass components
3. **Service Integration Tests**: Test consolidated services work correctly
4. **Visual Regression Tests**: Ensure Material Glass looks correct across devices

## Implementation Phases

### Phase 1: Foundation Cleanup
- Audit and document all existing files
- Identify and remove unused/duplicate code
- Consolidate duplicate services
- Establish clear service boundaries

### Phase 2: Core Architecture
- Create `Core/` directory structure
- Implement Material Glass design system
- Create service container and dependency injection
- Update existing components to use new design system

### Phase 3: Feature Modernization
- Update each feature to use Material Glass components
- Implement consistent error handling
- Add proper navigation coordination
- Ensure accessibility compliance

### Phase 4: Polish and Optimization
- Performance optimization
- Visual consistency audit
- Documentation updates
- Final testing and validation

## Migration Strategy

### Backward Compatibility

During refactoring:
1. **Gradual Migration**: Update components incrementally
2. **Feature Flags**: Use feature flags to toggle between old/new implementations
3. **Parallel Implementation**: Keep old components until new ones are validated
4. **Rollback Plan**: Maintain ability to revert changes if issues arise

### File Organization Migration

```swift
// Migration mapping
Old Location                    → New Location
Dirt/Dirt/UI/Design/           → Core/Design/
Dirt/Dirt/Services/            → Core/Services/ (core) + Features/*/Services/ (feature-specific)
Dirt/Dirt/Utilities/           → Shared/Utilities/
Dirt/Dirt/Models/              → Shared/Models/
```

## Performance Considerations

### Material Glass Optimization

1. **Efficient Material Usage**: Use appropriate Material thickness for context
2. **Animation Performance**: Optimize glass transitions for smooth 60fps
3. **Memory Management**: Proper cleanup of Material effects
4. **Battery Impact**: Monitor battery usage with Material effects

### Build Performance

1. **Module Organization**: Reduce compilation dependencies
2. **Service Injection**: Lazy loading of services
3. **Asset Optimization**: Optimize Material Glass visual assets

## Accessibility

### Material Glass Accessibility

1. **Contrast Ratios**: Ensure text remains readable on Material backgrounds
2. **Reduce Motion**: Respect accessibility settings for animations
3. **VoiceOver**: Proper accessibility labels for Material components
4. **Dynamic Type**: Support for larger text sizes with Material backgrounds

## Security Considerations

### Maintained Security Posture

1. **Privacy Preservation**: All existing privacy protections remain intact
2. **Data Handling**: No changes to data handling during refactor
3. **Authentication**: Preserve existing auth flows
4. **Content Moderation**: Maintain all moderation capabilities