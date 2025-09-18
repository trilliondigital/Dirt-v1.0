# Design Document

## Overview

This design outlines a systematic approach to refactor the Dirt iOS app from its current organically-grown state into a clean, maintainable architecture with modern iOS 18+ Material Glass design patterns. The refactor will preserve all existing functionality while establishing clear architectural boundaries, implementing modern visual design, creating comprehensive documentation, and building a sustainable development foundation that supports future feature development aligned with the existing milestone structure (M1-M5).

## Architecture

### Current State Analysis

The existing codebase has these strengths:
- Well-organized feature-based directory structure (`Features/`)
- Established design token system (`UI/Design/DesignTokens.swift`)
- Comprehensive service layer with proper separation of concerns
- Good test coverage for core utilities
- Clear documentation and requirements

Areas requiring systematic improvement:
- **File Organization**: Mix of active, inactive, and experimental code without clear status indicators
- **Architecture Clarity**: No Material Glass implementation despite being mentioned in PLAN.md
- **Service Duplication**: Multiple services with overlapping functionality (e.g., `MediaService` vs `EnhancedMediaService`)
- **Build Performance**: Potential circular dependencies and unused code affecting compilation times
- **Documentation Gaps**: Missing architectural decision records and development guidelines
- **Development Roadmap**: No clear structure for implementing remaining PLAN.md milestone items

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

## Codebase Audit and Cleanup Strategy

### File Classification System

**Design Decision**: Implement a systematic approach to identify and categorize all files in the codebase to eliminate confusion about active vs deprecated components.

**Rationale**: Requirement 1 emphasizes the need for clear organization where developers can efficiently maintain and extend the app without confusion about file status.

**Classification Categories:**
1. **Active**: Currently used in production code
2. **Inactive**: Legacy code that may be referenced but not actively maintained
3. **Experimental**: Proof-of-concept or feature-flag protected code
4. **Duplicate**: Multiple implementations of the same functionality
5. **Unused**: Dead code with no references

**Implementation Strategy:**
```swift
// File header documentation standard
/*
 * Status: [Active|Inactive|Experimental|Deprecated]
 * Purpose: Brief description of file's role
 * Dependencies: Key dependencies this file relies on
 * Dependents: Key files that depend on this file
 * Migration Notes: If deprecated, what replaces it
 */
```

### Dependency Analysis and Cleanup

**Design Decision**: Create comprehensive dependency mapping to identify circular dependencies and optimize build performance.

**Rationale**: Requirement 6 specifically calls for improved build performance and reduced technical debt through proper module organization.

**Cleanup Process:**
1. Generate dependency graphs for all modules
2. Identify and break circular dependencies
3. Consolidate duplicate services and utilities
4. Remove unused imports and dead code
5. Optimize module boundaries for faster compilation

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

**Design Decision**: Establish clear feature boundaries with minimal inter-feature dependencies to enable independent development and testing.

**Rationale**: Requirement 3 emphasizes the need for modular architecture where features can be developed and tested independently, with clear boundaries and minimal dependencies.

Each feature module follows this standardized pattern:
```
Features/[FeatureName]/
├── Views/              # SwiftUI views
├── ViewModels/         # ObservableObject view models
├── Models/             # Feature-specific models
├── Services/           # Feature-specific services (if needed)
├── Components/         # Feature-specific reusable components
└── README.md           # Feature documentation and guidelines
```

**Feature Boundary Rules:**
- Features communicate through shared services, not direct dependencies
- Shared models live in `Shared/Models/`
- Cross-feature components live in `Shared/Components/`
- Each feature must have clear documentation of its responsibilities
- Feature-to-feature communication goes through Core services only

**Module Dependency Guidelines:**
```swift
// Allowed dependencies (top-down only)
Features → Core/Services
Features → Shared/Models
Features → Shared/Components
Core → Foundation frameworks only
Shared → Foundation frameworks only

// Prohibited dependencies
Features ↔ Features (direct communication)
Core → Features
Shared → Features
```

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

### Functionality Preservation Testing

**Design Decision**: Implement comprehensive testing strategy that ensures all existing functionality is preserved during refactoring.

**Rationale**: Requirement 5 mandates that all existing UX flows and features must be maintained during architectural improvements, with all tests continuing to pass.

### Test Organization

**Unit Tests:**
- Preserve existing test structure in `DirtTests/`
- Add tests for new Material components
- Test service consolidation doesn't break functionality
- Test error handling improvements
- **Requirement Coverage**: Verify all documented features in PLAN.md still work correctly

**Integration Tests:**
- Test feature module boundaries and communication patterns
- Test service dependency injection functionality
- Test Material Glass component rendering and performance
- **Build Performance Tests**: Measure and validate improved build times

**UI Tests:**
- Test Material Glass visual consistency across all features
- Test accessibility compliance with Material backgrounds
- Test dark mode compatibility and contrast ratios
- **Regression Tests**: Ensure no UX flows are broken during refactoring

### Testing Approach

1. **Preserve Existing Tests**: All current tests must continue passing (Requirement 5.3)
2. **Add Component Tests**: Test new Material Glass components for functionality and accessibility
3. **Service Integration Tests**: Test consolidated services work correctly without performance degradation
4. **Visual Regression Tests**: Ensure Material Glass looks correct across devices and orientations
5. **Performance Validation**: Measure build times and runtime performance improvements (Requirement 6.4)

## Implementation Phases

**Design Decision**: Implement refactoring in carefully planned phases to maintain stability and enable rollback if needed.

**Rationale**: Requirement 5 emphasizes preserving functionality during refactoring, while Requirement 6 calls for improved build performance through systematic organization.

### Phase 1: Foundation Cleanup and Analysis
- **Codebase Audit**: Comprehensive analysis of all files to identify active, inactive, and duplicate code (Requirement 1.1)
- **Dependency Mapping**: Document current dependencies and identify circular references
- **Service Consolidation**: Merge duplicate services while maintaining functionality (Requirement 6.3)
- **File Organization**: Establish clear service boundaries and remove unused code (Requirement 1.4)

### Phase 2: Core Architecture Implementation
- **Core Structure**: Create `Core/` directory with Design, Navigation, and Services subdirectories (Requirement 3.1)
- **Material Glass System**: Implement iOS 18+ Material Glass design system (Requirement 2.1)
- **Service Container**: Create dependency injection pattern for better modularity (Requirement 3.2)
- **Documentation Foundation**: Begin architectural decision records and coding standards (Requirement 4.2)

### Phase 3: Feature Modernization and Boundaries
- **Feature Updates**: Update each feature to use Material Glass components while preserving UX flows (Requirement 2.2, 5.1)
- **Module Boundaries**: Implement clear feature boundaries with minimal dependencies (Requirement 3.1, 3.2)
- **Error Handling**: Standardize error handling patterns across all features (Requirement 4.3)
- **Accessibility**: Ensure Material Glass components meet accessibility standards (Requirement 2.4)

### Phase 4: Documentation, Optimization, and Roadmap
- **Performance Optimization**: Optimize build times and runtime performance (Requirement 6.2, 6.4)
- **Comprehensive Documentation**: Complete README files, coding standards, and architectural guidelines (Requirement 4.1, 4.3)
- **Development Roadmap**: Create clear roadmap for implementing remaining PLAN.md items aligned with M1-M5 milestones (Requirement 7.1, 7.2)
- **Final Validation**: Ensure all existing functionality is preserved and performance is improved (Requirement 5.4, 6.4)

## Migration Strategy

### Backward Compatibility and Risk Mitigation

**Design Decision**: Implement gradual migration with comprehensive rollback capabilities to ensure zero downtime and functionality preservation.

**Rationale**: Requirement 5 mandates that all existing functionality must be preserved during refactoring, with the ability to maintain backward compatibility during transition.

During refactoring:
1. **Gradual Migration**: Update components incrementally to minimize risk (Requirement 1.5)
2. **Feature Flags**: Use feature flags to toggle between old/new implementations
3. **Parallel Implementation**: Keep old components until new ones are validated through testing
4. **Rollback Plan**: Maintain ability to revert changes if issues arise
5. **Import Statement Management**: Systematically update all import statements and references (Requirement 5.2)

### File Organization Migration

**Design Decision**: Establish clear migration mapping to ensure no files are lost and all references are properly updated.

**Rationale**: Requirement 3.3 calls for appropriate placement of shared components, while Requirement 5.2 requires updating all import statements and references.

```swift
// Migration mapping with validation
Old Location                    → New Location                     → Validation Required
Dirt/Dirt/UI/Design/           → Core/Design/                    → Update all UI imports
Dirt/Dirt/Services/            → Core/Services/ (core services)  → Update service injection
                               → Features/*/Services/ (feature)   → Update feature imports  
Dirt/Dirt/Utilities/           → Shared/Utilities/               → Update utility imports
Dirt/Dirt/Models/              → Shared/Models/                  → Update model imports
Dirt/Dirt/Components/          → Shared/Components/              → Update component imports
```

### Import Statement Update Strategy

```swift
// Automated import update process
1. Generate comprehensive reference map of all imports
2. Update imports in dependency order (leaf nodes first)
3. Validate compilation after each batch of updates
4. Run full test suite after each major migration step
5. Document any breaking changes and required manual updates
```

## Performance Considerations

### Build Performance Optimization

**Design Decision**: Implement systematic build performance improvements through dependency optimization and dead code elimination.

**Rationale**: Requirement 6 specifically calls for improved build performance and reduced technical debt, with measurable improvements in build and test execution times.

**Build Optimization Strategy:**
1. **Dependency Analysis**: Eliminate circular dependencies that slow compilation (Requirement 6.1)
2. **Module Organization**: Reduce compilation dependencies through proper module boundaries (Requirement 6.2)
3. **Dead Code Removal**: Remove unused code and dependencies to reduce build overhead (Requirement 6.3)
4. **Service Injection**: Implement lazy loading of services to improve startup performance
5. **Performance Measurement**: Establish baseline metrics and validate improvements (Requirement 6.4)

### Material Glass Performance Optimization

**Design Decision**: Optimize Material Glass rendering for smooth 60fps performance while maintaining visual quality.

**Rationale**: Requirement 2 mandates modern Material Glass implementation while maintaining performance standards.

**Optimization Techniques:**
1. **Efficient Material Usage**: Use appropriate Material thickness for context to minimize rendering overhead
2. **Animation Performance**: Optimize glass transitions for smooth 60fps with proper GPU utilization
3. **Memory Management**: Proper cleanup of Material effects to prevent memory leaks
4. **Battery Impact**: Monitor and optimize battery usage with Material effects
5. **Asset Optimization**: Optimize Material Glass visual assets for different device capabilities

### Performance Validation Metrics

```swift
// Performance benchmarks to maintain
struct PerformanceBenchmarks {
    static let maxBuildTime: TimeInterval = 120 // seconds for clean build
    static let maxTestExecutionTime: TimeInterval = 60 // seconds for full test suite
    static let minFrameRate: Double = 60 // fps for Material Glass animations
    static let maxMemoryUsage: Int = 150 // MB baseline memory usage
    static let maxStartupTime: TimeInterval = 3 // seconds to first screen
}
```

## Accessibility

### Material Glass Accessibility

1. **Contrast Ratios**: Ensure text remains readable on Material backgrounds
2. **Reduce Motion**: Respect accessibility settings for animations
3. **VoiceOver**: Proper accessibility labels for Material components
4. **Dynamic Type**: Support for larger text sizes with Material backgrounds

## Documentation and Development Guidelines

### Comprehensive Documentation Strategy

**Design Decision**: Create comprehensive documentation and development guidelines to ensure consistent future development patterns.

**Rationale**: Requirement 4 emphasizes the need for comprehensive documentation, coding standards, and clear guidelines for future development.

**Documentation Components:**
1. **README Files**: Updated README files for each major component and directory (Requirement 4.1)
2. **Architectural Decision Records (ADRs)**: Document major design choices and their rationales (Requirement 4.2)
3. **Coding Standards**: Establish consistent patterns for code organization, naming, and structure
4. **Development Guidelines**: Clear guidelines for where new code should be placed (Requirement 4.3)
5. **Dependency Diagrams**: Visual representation of module relationships and dependencies (Requirement 4.4)

### Development Roadmap Integration

**Design Decision**: Align refactoring outcomes with existing milestone structure to enable systematic future development.

**Rationale**: Requirement 7 calls for a clear development roadmap that aligns with existing PLAN.md milestone structure (M1-M5).

**Roadmap Components:**
1. **Milestone Alignment**: Clear roadmap for implementing remaining PLAN.md items (Requirement 7.1)
2. **Priority Structure**: Align development priorities with existing milestone structure (Requirement 7.2)
3. **Build vs Refactor Analysis**: Identify which components need to be built vs refactored (Requirement 7.3)
4. **Architectural Consistency**: Establish process for maintaining architectural patterns (Requirement 7.4)

```swift
// Documentation structure
Docs/
├── Architecture/
│   ├── ADR-001-material-glass-adoption.md
│   ├── ADR-002-service-consolidation.md
│   ├── dependency-diagrams.md
│   └── module-boundaries.md
├── Development/
│   ├── coding-standards.md
│   ├── feature-development-guide.md
│   ├── testing-guidelines.md
│   └── performance-standards.md
└── Roadmap/
    ├── milestone-alignment.md
    ├── remaining-features.md
    └── architectural-evolution.md
```

## Security Considerations

### Maintained Security Posture

**Design Decision**: Preserve all existing security measures during refactoring to ensure no security regressions.

**Rationale**: Requirement 5 mandates preserving all existing functionality, which includes security and privacy protections.

1. **Privacy Preservation**: All existing privacy protections remain intact during refactoring
2. **Data Handling**: No changes to data handling patterns during architectural improvements
3. **Authentication**: Preserve existing auth flows and security boundaries
4. **Content Moderation**: Maintain all moderation capabilities and security controls
5. **Dependency Security**: Audit new dependencies introduced during refactoring for security implications