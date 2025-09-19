# Design Document

## Overview

This design document outlines the comprehensive UI/UX remaster of the Dirt app, transforming it from a basic functional prototype into a polished, production-ready dating feedback platform. The design draws heavily from the 132 Tea app screenshots as reference material, adapting proven dating app UX patterns for Dirt's unique community-focused approach.

The remaster focuses on creating a cohesive visual language that balances modern iOS design principles with the specific needs of a dating feedback community. Key design pillars include visual hierarchy, intuitive navigation, engaging interactions, and accessibility compliance.

## Architecture

### Design System Foundation

The new UI will be built on a comprehensive design system that ensures consistency across all screens and interactions:

**Material Design Integration**
- Utilizes iOS Material effects (.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial)
- Implements glassmorphism effects for modern, layered visual depth
- Supports both light and dark mode with appropriate material adaptations

**Typography Hierarchy**
- Large Title: 34pt, Bold - Main screen titles
- Title 1: 28pt, Bold - Section headers
- Title 2: 22pt, Bold - Card titles, important labels
- Title 3: 20pt, Semibold - Subsection headers
- Headline: 17pt, Semibold - Post titles, button labels
- Body: 17pt, Regular - Main content text
- Callout: 16pt, Regular - Secondary content
- Subheadline: 15pt, Regular - Metadata, timestamps
- Footnote: 13pt, Regular - Fine print, disclaimers
- Caption 1: 12pt, Regular - Image captions, small labels
- Caption 2: 11pt, Regular - Smallest text elements

**Color System**
- Primary: Dynamic blue (#007AFF light, #0A84FF dark)
- Secondary: Dynamic gray (#8E8E93 light, #8E8E93 dark)
- Success: Dynamic green (#34C759 light, #30D158 dark)
- Warning: Dynamic orange (#FF9500 light, #FF9F0A dark)
- Error: Dynamic red (#FF3B30 light, #FF453A dark)
- Background: System background colors with material overlays
- Surface: Card backgrounds using thin material effects

**Spacing System**
- XXS: 2pt - Fine adjustments
- XS: 4pt - Tight spacing
- SM: 8pt - Small gaps
- MD: 16pt - Standard spacing
- LG: 24pt - Large gaps
- XL: 32pt - Section separation
- XXL: 48pt - Major layout breaks

### Component Architecture

**Atomic Design Approach**
- Atoms: Basic UI elements (buttons, inputs, labels)
- Molecules: Simple component combinations (search bars, post actions)
- Organisms: Complex UI sections (post cards, navigation bars)
- Templates: Page layouts and structures
- Pages: Complete screen implementations

**Reusable Components**
- GlassCard: Material-based card container
- ActionButton: Consistent button styling with haptics
- PostCard: Standardized post display component
- UserAvatar: Profile image with status indicators
- EngagementBar: Like, comment, share actions
- CategoryChip: Visual category and sentiment indicators
- LoadingState: Skeleton screens and progress indicators
- EmptyState: Engaging empty content displays

## Components and Interfaces

### Onboarding Flow Components

**Welcome Screen**
- Hero illustration or animation showcasing app value
- Compelling headline and subheadline text
- Progressive disclosure of key features
- Smooth transition animations between steps
- Skip option for returning users

**Authentication Interface**
- Prominent Apple Sign In button with system styling
- Anonymous option with clear benefit/limitation explanation
- Privacy-focused messaging and trust indicators
- Loading states with progress indication
- Error handling with retry mechanisms

**Interest Selection**
- Visual category grid with icons and descriptions
- Multi-select interface with visual feedback
- Recommended selections based on user type
- Progress indication and completion validation
- Smooth transition to main app

### Feed Interface Components

**Post Card Design**
```
┌─────────────────────────────────────┐
│ [Avatar] Username • 2h ago    [•••] │
│ [Category Badge] [Sentiment Badge]  │
│                                     │
│ Post Title (Headline font)          │
│ Post content preview with proper    │
│ line height and truncation...       │
│                                     │
│ [Image/Media if present]            │
│                                     │
│ [↑ 24] [↓ 3] [💬 12] [🔖] [↗]      │
└─────────────────────────────────────┘
```

**Feed Layout**
- Card-based design with proper spacing (16pt margins)
- Infinite scroll with smooth loading transitions
- Pull-to-refresh with haptic feedback
- Floating action button for quick post creation
- Category filter bar with horizontal scrolling
- Search integration with real-time results

**Navigation Structure**
- Tab bar with 5 primary sections: Feed, Search, Create, Notifications, Profile
- Contextual navigation bars with appropriate titles and actions
- Breadcrumb navigation for deep content
- Swipe gestures for back navigation
- Modal presentations for focused tasks

### Post Creation Interface

**Multi-Step Creation Flow**
1. Content Input: Rich text editor with formatting options
2. Categorization: Visual selection of category and sentiment
3. Media Addition: Image picker with cropping and filters
4. Review: Preview of final post appearance
5. Publishing: Progress indication and confirmation

**Content Editor Features**
- Real-time character counting with visual indicators
- Formatting toolbar (bold, italic, lists)
- Hashtag and mention suggestions
- Image insertion with drag-and-drop
- Auto-save functionality with recovery
- Accessibility support for screen readers

**Category Selection Interface**
- Grid layout with large, tappable category cards
- Visual icons and color coding for each category
- Sentiment selection with clear red/green/neutral options
- Tag suggestions based on content analysis
- Preview of how categorization will appear

### Profile Management Interface

**Profile Dashboard**
```
┌─────────────────────────────────────┐
│           [Large Avatar]            │
│         Username/Anonymous          │
│      [Reputation Badge/Level]       │
│                                     │
│  [Posts: 24] [Likes: 156] [Saved: 8] │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        Recent Activity          │ │
│ │  [Post thumbnails in grid]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Settings] [Privacy] [Help]         │
└─────────────────────────────────────┘
```

**Settings Organization**
- Grouped sections with clear visual hierarchy
- Toggle switches with immediate feedback
- Slider controls for granular preferences
- Action sheets for destructive actions
- In-line editing with validation feedback

### Notification Interface

**Notification List Design**
- Chronological list with clear read/unread states
- Rich notifications with contextual actions
- Swipe actions for quick management
- Bulk selection and actions
- Real-time updates with smooth animations

**Notification Types**
- Engagement: Likes, comments, shares with user avatars
- System: Updates, announcements with branded styling
- Moderation: Content status updates with clear explanations
- Social: New followers, mentions with profile links

## Data Models

### UI State Management

**AppState Extensions**
```swift
@Published var currentTheme: AppTheme = .system
@Published var animationsEnabled: Bool = true
@Published var hapticsEnabled: Bool = true
@Published var reducedMotion: Bool = false
@Published var currentOnboardingStep: OnboardingStep?
@Published var feedScrollPosition: CGFloat = 0
@Published var selectedFilters: Set<PostCategory> = []
```

**Theme Configuration**
```swift
enum AppTheme: String, CaseIterable {
    case light, dark, system
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
```

**Animation Preferences**
```swift
struct AnimationPreferences {
    let standardDuration: Double = 0.3
    let quickDuration: Double = 0.15
    let slowDuration: Double = 0.5
    let springResponse: Double = 0.6
    let springDamping: Double = 0.8
}
```

### Component State Models

**PostCardState**
```swift
struct PostCardState {
    var isLiked: Bool = false
    var isDisliked: Bool = false
    var isSaved: Bool = false
    var isExpanded: Bool = false
    var showingActions: Bool = false
    var loadingAction: PostAction?
}
```

**FeedState**
```swift
struct FeedState {
    var posts: [Post] = []
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var hasMoreContent: Bool = true
    var selectedCategory: PostCategory?
    var searchQuery: String = ""
    var sortOrder: SortOrder = .recent
}
```

## Error Handling

### User-Facing Error States

**Network Errors**
- Offline indicator with retry options
- Timeout messages with clear next steps
- Connection quality indicators
- Cached content availability notifications

**Content Errors**
- Failed to load states with refresh buttons
- Content not found with navigation suggestions
- Permission denied with explanation and alternatives
- Rate limiting with clear timing information

**Validation Errors**
- Real-time input validation with helpful suggestions
- Form submission errors with field-specific guidance
- Character limit warnings with visual indicators
- Content policy violations with improvement suggestions

### Error Recovery Patterns

**Graceful Degradation**
- Reduced functionality modes when services are unavailable
- Cached content display when real-time updates fail
- Offline post composition with sync when connected
- Progressive enhancement as services become available

**User Guidance**
- Clear error messages in plain language
- Actionable next steps for error resolution
- Contact support options for persistent issues
- FAQ links for common problems

## Testing Strategy

### Visual Regression Testing

**Screenshot Comparison**
- Automated screenshot capture for all major screens
- Pixel-perfect comparison across iOS versions
- Dark mode and light mode validation
- Accessibility mode testing (large text, high contrast)

**Component Testing**
- Individual component rendering validation
- State change verification (loading, error, success)
- Animation and transition testing
- Responsive layout validation

### Accessibility Testing

**VoiceOver Compliance**
- Screen reader navigation flow validation
- Proper labeling and hint provision
- Focus management and announcement testing
- Gesture support for accessibility users

**Dynamic Type Support**
- Text scaling validation across all size categories
- Layout adaptation for larger text sizes
- Button and touch target size compliance
- Readability maintenance at all scales

### Performance Testing

**Rendering Performance**
- 60fps maintenance during scrolling and animations
- Memory usage monitoring during extended use
- Image loading and caching efficiency
- Startup time and cold launch optimization

**Interaction Responsiveness**
- Touch response time measurement
- Animation smoothness validation
- Network request handling efficiency
- Background task performance monitoring

### User Experience Testing

**Usability Validation**
- Task completion rate measurement
- User flow efficiency analysis
- Error recovery success rates
- Feature discoverability assessment

**A/B Testing Framework**
- Component variation testing infrastructure
- User engagement metric collection
- Conversion rate optimization
- Feature adoption measurement

## Implementation Phases

### Phase 1: Design System Foundation (Week 1-2)
- Implement core design tokens and theme system
- Create atomic components (buttons, inputs, labels)
- Establish animation and transition patterns
- Set up accessibility infrastructure

### Phase 2: Core Interface Components (Week 3-4)
- Build post card and feed components
- Implement navigation and tab bar
- Create user avatar and profile components
- Develop loading and empty states

### Phase 3: Feature-Specific Interfaces (Week 5-6)
- Complete onboarding flow implementation
- Build post creation interface
- Implement profile management screens
- Create notification interface

### Phase 4: Advanced Interactions (Week 7-8)
- Add gesture support and swipe actions
- Implement search and filtering
- Create sharing and social features
- Add haptic feedback and animations

### Phase 5: Polish and Optimization (Week 9-10)
- Performance optimization and testing
- Accessibility compliance validation
- Visual polish and micro-interactions
- User testing and iteration

This design provides a comprehensive foundation for transforming the Dirt app into a polished, production-ready application that matches the quality and user experience expectations set by successful dating apps like Tea, while maintaining Dirt's unique community-focused approach.