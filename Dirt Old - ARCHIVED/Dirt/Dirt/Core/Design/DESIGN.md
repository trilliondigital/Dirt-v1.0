# Design System

This directory contains the Material Glass design system components that provide consistent visual styling throughout the Dirt iOS app.

## Overview

The design system implements iOS 18+ Material Glass effects with proper accessibility support, dark mode compatibility, and performance optimization.

## Components

### Core Design System
- **`MaterialDesignSystem.swift`** - Central design system with Material effects and color tokens
- **`DesignTokens.swift`** - Enhanced color system with Material Glass support
- **`GlassComponents.swift`** - Reusable Material Glass UI components
- **`MotionSystem.swift`** - Animation and transition definitions for consistent motion
- **`CardStyles.swift`** - Card styling with Material Glass effects

### Accessibility
- **`AccessibilitySystem.swift`** - Accessibility utilities and compliance helpers
- **`ACCESSIBILITY.md`** - Comprehensive accessibility guidelines and standards

### Examples
- **`MaterialGlassExampleView.swift`** - Example implementations and usage patterns

## Usage

### Basic Glass Components

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack {
            // Glass card with content
            GlassCard {
                Text("Content goes here")
                    .padding()
            }
            
            // Glass button
            GlassButton("Tap me") {
                // Action
            }
            
            // Glass navigation bar
            GlassNavigationBar(title: "My Screen")
        }
    }
}
```

### Design Tokens

```swift
// Using Material colors
Text("Hello")
    .foregroundColor(MaterialColors.primary)
    .background(MaterialColors.glassPrimary)

// Using motion system
Button("Animate") {
    withAnimation(MaterialMotion.standardTransition) {
        // Animate changes
    }
}
```

### Accessibility

```swift
// Using accessibility system
Text("Important content")
    .accessibilityLabel("Descriptive label")
    .accessibilityAddTraits(.isButton)
    .materialGlassAccessible() // Custom modifier for glass components
```

## Design Principles

1. **Material First**: All components use iOS Material effects (.ultraThinMaterial, .thinMaterial, etc.)
2. **Accessibility Compliant**: Proper contrast ratios, VoiceOver support, Dynamic Type
3. **Performance Optimized**: Efficient rendering for smooth 60fps animations
4. **Dark Mode Native**: Full dark mode support with appropriate Material effects
5. **Consistent Motion**: Standardized animations and transitions

## Material Glass Hierarchy

- **Ultra Thin Material**: Subtle overlays, floating elements
- **Thin Material**: Cards, secondary surfaces
- **Regular Material**: Primary surfaces, navigation bars
- **Thick Material**: Modals, prominent surfaces

## Accessibility Standards

All components meet WCAG 2.1 AA standards:
- Minimum 4.5:1 contrast ratio for normal text
- Minimum 3:1 contrast ratio for large text
- Full VoiceOver support with descriptive labels
- Dynamic Type support up to accessibility sizes
- Reduced motion respect for accessibility preferences

## Testing

Design system components include comprehensive tests:
- Visual regression tests for Material Glass consistency
- Accessibility compliance tests
- Performance tests for animation smoothness
- Dark mode compatibility tests

## Contributing

When adding new design components:
1. Follow Material Glass patterns established in existing components
2. Include accessibility support from the start
3. Add comprehensive tests including accessibility tests
4. Update this README with usage examples
5. Ensure dark mode compatibility

## Performance Considerations

- Use appropriate Material thickness for context
- Optimize animations for 60fps performance
- Consider battery impact of Material effects
- Test on older devices for performance validation