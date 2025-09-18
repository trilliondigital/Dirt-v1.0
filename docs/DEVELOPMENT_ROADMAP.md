# Development Roadmap

This document provides a comprehensive roadmap for implementing the remaining PLAN.md milestones (M1-M5) within the refactored Dirt iOS architecture. It establishes guidelines for maintaining architectural consistency and outlines the development process for future features.

## Table of Contents

- [Overview](#overview)
- [Milestone Implementation Plan](#milestone-implementation-plan)
- [Component Analysis: Build vs Refactor](#component-analysis-build-vs-refactor)
- [Architecture Guidelines](#architecture-guidelines)
- [Development Process](#development-process)
- [Quality Assurance](#quality-assurance)
- [Future Considerations](#future-considerations)

## Overview

### Current State
The architectural refactor has established:
- ✅ Clean Core architecture with Material Glass design system
- ✅ Service container pattern with dependency injection
- ✅ Feature module boundaries and navigation coordination
- ✅ Comprehensive testing infrastructure
- ✅ Performance optimization and accessibility compliance

### Remaining Work
The PLAN.md defines 5 milestones (M1-M5) that need implementation within this new architecture:
- **M1**: Parity analysis and checklist updates
- **M2**: Create Post v2 + Feed actions parity
- **M3**: Search/saved searches + Alerts (keyword)
- **M4**: Report flow + soft-hide functionality
- **M5**: Visual polish (glass effects, dark mode), QA, TestFlight

## Milestone Implementation Plan

### M1: Parity Analysis Complete (FigJam) + Checklist Updated

**Status**: Ready to Start  
**Estimated Duration**: 1-2 weeks  
**Dependencies**: None

#### Objectives
- Complete detailed parity analysis against Tea reference app
- Update PLAN.md checklist with specific gaps and deltas
- Document UX decisions and feature alignment

#### Implementation Tasks
1. **Parity Analysis Documentation**
   - Create `docs/parity-analysis.md` with detailed Tea vs Dirt comparison
   - Document missing features, broken functionality, and intentional divergences
   - Update PLAN.md checklist with specific action items

2. **UX Flow Documentation**
   - Document current user flows with screenshots/wireframes
   - Identify UX gaps that need addressing before visual polish
   - Create user journey maps for core flows

3. **Technical Gap Analysis**
   - Audit existing implementations against PLAN.md requirements
   - Identify technical debt that impacts UX
   - Prioritize fixes based on user impact

#### Components: Analysis Only
- No new components needed
- Documentation and planning phase

---

### M2: Create Post v2 + Feed Actions Parity

**Status**: Ready to Start  
**Estimated Duration**: 2-3 weeks  
**Dependencies**: M1 completion

#### Objectives
- Enhance Create Post flow with full schema validation
- Implement complete Feed actions (Helpful, Report, Save, Share)
- Ensure parity with Tea reference for core posting functionality

#### Implementation Tasks

##### Create Post Enhancements
1. **Enhanced Post Validation** (Build New)
   ```swift
   // Location: Dirt/Dirt/Features/CreatePost/Services/PostValidationService.swift
   class PostValidationService {
       func validatePost(_ content: PostContent) throws -> ValidatedPost
       func validateTags(_ tags: [String]) throws -> [ControlledTag]
       func validateCharacterCount(_ text: String) -> ValidationResult
   }
   ```

2. **Media Processing Integration** (Refactor Existing)
   - Enhance existing `MediaService` with EXIF stripping
   - Add auto-blur functionality for uploaded images
   - Integrate with existing `CreatePostView.swift`

3. **Category Selection UI** (Build New)
   ```swift
   // Location: Dirt/Dirt/Features/CreatePost/Views/CategorySelectionView.swift
   struct CategorySelectionView: View {
       // Red/Green flag selection with relationship type categories
   }
   ```

##### Feed Actions Implementation
1. **Enhanced Post Actions** (Refactor Existing)
   - Update existing `PostDetailView.swift` with complete action set
   - Integrate with consolidated services (PostService, ModerationService)
   - Add Material Glass action buttons

2. **Save/Share Functionality** (Build New)
   ```swift
   // Location: Dirt/Dirt/Features/Feed/Services/PostInteractionService.swift
   class PostInteractionService {
       func savePost(_ postId: String) async throws
       func sharePost(_ post: Post) -> ShareSheet
       func markHelpful(_ postId: String) async throws
   }
   ```

#### Components Analysis
- **Build New**: PostValidationService, CategorySelectionView, PostInteractionService
- **Refactor Existing**: CreatePostView, PostDetailView, MediaService integration
- **Leverage Existing**: Material Glass components, Service container, Navigation coordination

---

### M3: Search/Saved Searches + Alerts (Keyword)

**Status**: Depends on M2  
**Estimated Duration**: 2-3 weeks  
**Dependencies**: M2 completion

#### Objectives
- Implement comprehensive search with saved searches
- Add keyword alert system for content monitoring
- Enhance discovery with advanced filtering

#### Implementation Tasks

##### Search Enhancement
1. **Advanced Search Service** (Refactor Existing)
   - Enhance consolidated `SearchService` with saved searches
   - Add typeahead suggestions and search history
   - Implement tag-based and sentiment-based search

2. **Saved Searches Management** (Build New)
   ```swift
   // Location: Dirt/Dirt/Features/Search/Services/SavedSearchService.swift
   class SavedSearchService {
       func saveSearch(_ query: SearchQuery) async throws
       func getSavedSearches() async throws -> [SavedSearch]
       func deleteSearch(_ id: String) async throws
   }
   ```

3. **Search Results UI** (Refactor Existing)
   - Update `SearchView.swift` with saved searches section
   - Add Material Glass search result cards
   - Implement infinite scroll for search results

##### Keyword Alerts System
1. **Alert Management Service** (Build New)
   ```swift
   // Location: Dirt/Dirt/Features/Notifications/Services/KeywordAlertService.swift
   class KeywordAlertService {
       func createAlert(for keywords: [String]) async throws
       func getActiveAlerts() async throws -> [KeywordAlert]
       func processIncomingContent(_ content: String) async
   }
   ```

2. **Notifications Enhancement** (Refactor Existing)
   - Update `NotificationsView.swift` with Activity/Keyword tabs
   - Integrate with existing notification system
   - Add Material Glass notification cards

#### Components Analysis
- **Build New**: SavedSearchService, KeywordAlertService, alert processing logic
- **Refactor Existing**: SearchView, NotificationsView, SearchService enhancement
- **Leverage Existing**: Material Glass components, Navigation, Service container

---

### M4: Report Flow + Soft-Hide Functionality

**Status**: Depends on M3  
**Estimated Duration**: 2-3 weeks  
**Dependencies**: M3 completion

#### Objectives
- Implement comprehensive content reporting system
- Add soft-hide functionality with moderation queue
- Ensure content safety and community guidelines enforcement

#### Implementation Tasks

##### Enhanced Reporting System
1. **Report Flow UI** (Refactor Existing)
   - Enhance existing report functionality in feed/detail views
   - Add Material Glass report modal with reason selection
   - Implement progressive disclosure for report details

2. **Moderation Queue Enhancement** (Refactor Existing)
   - Enhance existing `ModerationService` and `ModerationQueue`
   - Add auto-hide threshold logic
   - Implement moderator review interface

3. **Content Filtering** (Build New)
   ```swift
   // Location: Dirt/Dirt/Core/Services/ContentFilterService.swift
   class ContentFilterService {
       func shouldHideContent(_ content: Post, reportCount: Int) -> Bool
       func applyContentFilter(_ posts: [Post]) -> [Post]
       func getHiddenContentReason(_ postId: String) -> HideReason?
   }
   ```

##### Soft-Hide Implementation
1. **Content State Management** (Build New)
   - Add content visibility states (visible, soft-hidden, hard-hidden)
   - Implement user preference for viewing hidden content
   - Add "Show hidden content" toggle functionality

2. **Feed Integration** (Refactor Existing)
   - Update `FeedView.swift` to respect content visibility
   - Add placeholder cards for hidden content
   - Implement "Content hidden" messaging with Material Glass

#### Components Analysis
- **Build New**: ContentFilterService, content state management, soft-hide UI
- **Refactor Existing**: Report flows, ModerationService, FeedView filtering
- **Leverage Existing**: Material Glass modals, Service container, Error handling

---

### M5: Visual Polish (Glass Effects, Dark Mode), QA, TestFlight

**Status**: Depends on M4  
**Estimated Duration**: 3-4 weeks  
**Dependencies**: M4 completion

#### Objectives
- Apply comprehensive Material Glass visual polish
- Ensure perfect Dark Mode support across all features
- Complete QA testing and prepare TestFlight build

#### Implementation Tasks

##### Visual Polish Application
1. **Material Glass Refinement** (Refactor Existing)
   - Apply Material Glass effects to all remaining components
   - Ensure consistent visual hierarchy with proper Material thickness
   - Optimize glass effects for performance

2. **Dark Mode Perfection** (Refactor Existing)
   - Audit all components for Dark Mode compatibility
   - Ensure proper contrast ratios with Material backgrounds
   - Test Dynamic Type support with glass effects

3. **Animation Polish** (Refactor Existing)
   - Apply consistent Material motion system
   - Add delightful micro-interactions
   - Optimize animation performance

##### Quality Assurance
1. **Comprehensive Testing** (Build New)
   - Create comprehensive test plans for all M1-M5 features
   - Implement automated UI tests for critical user flows
   - Performance testing with Material Glass effects

2. **Accessibility Audit** (Refactor Existing)
   - Complete accessibility compliance verification
   - Test VoiceOver with all new features
   - Ensure keyboard navigation support

3. **TestFlight Preparation** (Build New)
   - Create TestFlight build configuration
   - Implement crash reporting and analytics
   - Create beta testing documentation

#### Components Analysis
- **Build New**: Test plans, TestFlight configuration, beta documentation
- **Refactor Existing**: All UI components for visual polish, Dark Mode, animations
- **Leverage Existing**: Material Glass system, Accessibility framework, Testing infrastructure

## Component Analysis: Build vs Refactor

### Build New Components

#### Services Layer
```swift
// New services needed for PLAN.md features
PostValidationService      // M2: Enhanced post validation
SavedSearchService        // M3: Saved search management
KeywordAlertService       // M3: Keyword monitoring
ContentFilterService      // M4: Content filtering and soft-hide
```

#### UI Components
```swift
// New UI components for enhanced functionality
CategorySelectionView     // M2: Post category selection
SavedSearchesView        // M3: Saved searches management
KeywordAlertsView        // M3: Alert configuration
ReportModalView          // M4: Enhanced reporting interface
HiddenContentCard        // M4: Placeholder for hidden content
```

#### Data Models
```swift
// New models for extended functionality
ValidatedPost            // M2: Post with validation state
SavedSearch             // M3: Saved search queries
KeywordAlert            // M3: Keyword monitoring rules
ContentVisibilityState  // M4: Content hide/show state
```

### Refactor Existing Components

#### Enhanced Functionality
- `CreatePostView.swift` → Add validation, categories, media processing
- `SearchView.swift` → Add saved searches, enhanced filtering
- `NotificationsView.swift` → Add keyword alerts, improved organization
- `FeedView.swift` → Add content filtering, soft-hide support
- `PostDetailView.swift` → Enhanced actions, reporting integration

#### Service Integration
- `MediaService` → Add EXIF stripping, auto-blur
- `SearchService` → Add saved searches, typeahead
- `ModerationService` → Add soft-hide, auto-threshold
- `PostService` → Add validation, enhanced actions

#### Visual Polish
- All existing Material Glass components → Performance optimization
- All views → Dark Mode perfection, animation polish
- Navigation components → Consistent Material effects

### Leverage Existing Architecture

#### Core Systems (No Changes Needed)
- ✅ Service Container pattern
- ✅ Material Glass design system foundation
- ✅ Navigation coordination
- ✅ Error handling framework
- ✅ Testing infrastructure
- ✅ Accessibility system
- ✅ Performance optimization framework

## Architecture Guidelines

### Adding New Features

#### 1. Service Layer First
```swift
// Always start with service layer design
protocol NewFeatureServiceProtocol {
    func performFeatureAction() async throws -> Result
}

class NewFeatureService: NewFeatureServiceProtocol {
    // Implementation with proper error handling
}

// Register in ServiceContainer
extension ServiceContainer {
    var newFeatureService: NewFeatureService {
        service(\.newFeatureService) {
            NewFeatureService(dependencies: ...)
        }
    }
}
```

#### 2. Model Definition
```swift
// Define clear data models
struct FeatureModel: Codable, Identifiable {
    let id: String
    // Properties with proper types
}

// Add validation if needed
extension FeatureModel {
    func validate() throws {
        // Validation logic
    }
}
```

#### 3. View Implementation
```swift
// Use Material Glass components
struct FeatureView: View {
    @Environment(\.services) var services
    @StateObject private var viewModel = FeatureViewModel()
    
    var body: some View {
        GlassCard {
            // Feature UI using design system
        }
        .navigationTitle("Feature")
        .materialGlassBackground()
    }
}
```

#### 4. Testing Strategy
```swift
// Comprehensive test coverage
class FeatureServiceTests: XCTestCase {
    // Unit tests for service logic
}

class FeatureViewTests: XCTestCase {
    // UI tests for view behavior
}

class FeatureIntegrationTests: XCTestCase {
    // Integration tests for complete flows
}
```

### Maintaining Consistency

#### Code Organization
```
Features/NewFeature/
├── Views/
│   ├── NewFeatureView.swift
│   └── Components/
├── ViewModels/
│   └── NewFeatureViewModel.swift
├── Services/
│   └── NewFeatureService.swift
├── Models/
│   └── NewFeatureModels.swift
└── Tests/
    ├── NewFeatureServiceTests.swift
    └── NewFeatureViewTests.swift
```

#### Service Integration Pattern
```swift
// Always use dependency injection
class NewFeatureViewModel: ObservableObject {
    private let service: NewFeatureService
    
    init(service: NewFeatureService) {
        self.service = service
    }
}

// Environment integration
struct NewFeatureView: View {
    @Environment(\.services) var services
    
    var body: some View {
        // Use services.newFeatureService
    }
}
```

#### Material Glass Usage
```swift
// Follow established hierarchy
VStack {
    // Ultra thin for overlays
    OverlayView()
        .background(.ultraThinMaterial)
    
    // Regular for primary surfaces
    GlassCard { // Uses .regularMaterial
        ContentView()
    }
    
    // Thick for modals
    ModalView()
        .background(.thickMaterial)
}
```

## Development Process

### Feature Development Workflow

#### 1. Planning Phase
- [ ] Review PLAN.md requirements
- [ ] Create feature specification document
- [ ] Design service interfaces
- [ ] Plan UI/UX with Material Glass components
- [ ] Estimate development timeline

#### 2. Implementation Phase
- [ ] Implement service layer with tests
- [ ] Create data models with validation
- [ ] Build UI components using design system
- [ ] Integrate with existing navigation/services
- [ ] Add comprehensive error handling

#### 3. Testing Phase
- [ ] Unit tests for all service logic
- [ ] UI tests for user interactions
- [ ] Integration tests for complete flows
- [ ] Accessibility testing
- [ ] Performance testing

#### 4. Review Phase
- [ ] Code review for architecture compliance
- [ ] UX review against PLAN.md requirements
- [ ] Security review for sensitive features
- [ ] Performance review for Material Glass usage

#### 5. Integration Phase
- [ ] Merge with main branch
- [ ] Update documentation
- [ ] Deploy to TestFlight (if applicable)
- [ ] Monitor performance metrics

### Code Review Checklist

#### Architecture Compliance
- [ ] Uses service container for dependencies
- [ ] Follows feature module boundaries
- [ ] Implements proper error handling
- [ ] Uses Material Glass design system
- [ ] Maintains navigation patterns

#### Code Quality
- [ ] Follows coding standards
- [ ] Has comprehensive tests
- [ ] Includes proper documentation
- [ ] Handles edge cases
- [ ] Optimizes performance

#### UX Alignment
- [ ] Matches PLAN.md requirements
- [ ] Maintains existing user flows
- [ ] Follows Apple HIG guidelines
- [ ] Supports accessibility
- [ ] Works in Dark Mode

### Milestone Delivery Process

#### Pre-Milestone Checklist
- [ ] All planned features implemented
- [ ] Comprehensive testing completed
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Accessibility compliance verified

#### Milestone Review
- [ ] Stakeholder demo of new features
- [ ] UX validation against requirements
- [ ] Technical architecture review
- [ ] Performance and stability assessment
- [ ] User feedback collection (if applicable)

#### Post-Milestone Activities
- [ ] Update PLAN.md with completion status
- [ ] Document lessons learned
- [ ] Plan next milestone priorities
- [ ] Address any technical debt
- [ ] Prepare for next development cycle

## Quality Assurance

### Testing Strategy

#### Automated Testing
```swift
// Service layer testing
class PostValidationServiceTests: XCTestCase {
    func testValidatePost_WhenValidContent_ReturnsValidatedPost() {
        // Test implementation
    }
}

// UI testing with Material Glass
class MaterialGlassUITests: XCTestCase {
    func testGlassCard_WhenRendered_HasCorrectAccessibility() {
        // Test Material Glass accessibility
    }
}

// Integration testing
class FeatureIntegrationTests: XCTestCase {
    func testCompleteUserFlow_WhenExecuted_CompletesSuccessfully() {
        // Test end-to-end flows
    }
}
```

#### Manual Testing
- [ ] User flow validation
- [ ] Cross-device compatibility
- [ ] Performance under load
- [ ] Edge case handling
- [ ] Accessibility with assistive technologies

### Performance Monitoring

#### Key Metrics
- App launch time
- Material Glass rendering performance
- Memory usage with glass effects
- Network request efficiency
- Battery impact assessment

#### Monitoring Tools
- Xcode Instruments for performance profiling
- Crash reporting for stability monitoring
- Analytics for user behavior tracking
- A/B testing for UX optimization

### Accessibility Compliance

#### Requirements
- [ ] VoiceOver support for all interactive elements
- [ ] Dynamic Type support throughout the app
- [ ] Proper contrast ratios with Material backgrounds
- [ ] Keyboard navigation support
- [ ] Reduced motion respect

#### Testing Process
- [ ] Automated accessibility testing in CI
- [ ] Manual testing with VoiceOver
- [ ] Testing with various Dynamic Type sizes
- [ ] Color contrast validation
- [ ] User testing with accessibility needs

## Future Considerations

### Scalability Planning

#### Architecture Evolution
- Modular architecture for feature teams
- Micro-frontend patterns for large features
- Service mesh for complex integrations
- Event-driven architecture for real-time features

#### Performance Optimization
- Lazy loading for large feature sets
- Code splitting for reduced bundle size
- Caching strategies for improved responsiveness
- Background processing for heavy operations

### Technology Roadmap

#### iOS Platform Evolution
- SwiftUI advances and new APIs
- iOS version adoption and deprecation
- New Apple frameworks integration
- Performance improvements and optimizations

#### Third-Party Dependencies
- Regular dependency updates
- Security vulnerability monitoring
- Performance impact assessment
- Alternative solution evaluation

### Maintenance Strategy

#### Technical Debt Management
- Regular architecture reviews
- Code quality metrics monitoring
- Refactoring prioritization
- Legacy code migration planning

#### Documentation Maintenance
- Regular documentation updates
- Architecture decision record maintenance
- Code example freshness
- Onboarding material updates

---

## Implementation Timeline

### Milestone Schedule
- **M1**: Weeks 1-2 (Analysis and Planning)
- **M2**: Weeks 3-5 (Create Post v2 + Feed Actions)
- **M3**: Weeks 6-8 (Search + Alerts)
- **M4**: Weeks 9-11 (Report Flow + Soft-Hide)
- **M5**: Weeks 12-15 (Visual Polish + TestFlight)

### Resource Allocation
- **Development**: 70% of effort
- **Testing**: 20% of effort
- **Documentation**: 10% of effort

### Risk Mitigation
- Buffer time for complex integrations
- Parallel development where possible
- Regular milestone reviews
- Rollback plans for major changes

---

*This roadmap should be reviewed and updated regularly as development progresses and requirements evolve.*