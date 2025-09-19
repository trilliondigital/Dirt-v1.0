# Design System Foundation

This directory contains the complete design system foundation for the Dirt app UI remaster. The design system provides a comprehensive set of tokens, components, and utilities for building consistent, accessible, and polished user interfaces.

## 📁 Structure

```
DesignSystem/
├── README.md                           # This file
├── DesignTokens.swift                  # Core design tokens (spacing, typography, colors, etc.)
├── MaterialDesignSystem.swift          # Glass effects and material components
├── ThemeManager.swift                  # Light/dark mode theme management
├── AnimationPreferences.swift          # Animation system and haptic feedback
├── TypographyStyles.swift              # Typography system with semantic styles
├── ColorPalette.swift                  # Comprehensive color palette
├── DynamicColor.swift                  # Dynamic color extensions for theme adaptation
├── AccessibilityColorValidator.swift   # WCAG compliance validation utilities
└── Components/
    ├── GlassCard.swift                 # Material glass card component
    ├── ActionButton.swift              # Versatile button with haptic feedback
    ├── CustomTextField.swift           # Text field with validation and states
    └── LoadingSpinner.swift            # Loading indicators and progress components
```

## 🎨 Design Tokens

### Spacing System
- **XXS**: 2pt - Fine adjustments
- **XS**: 4pt - Tight spacing
- **SM**: 8pt - Small gaps
- **MD**: 16pt - Standard spacing (default)
- **LG**: 24pt - Large gaps
- **XL**: 32pt - Section separation
- **XXL**: 48pt - Major layout breaks

### Typography Hierarchy
- **Large Title**: 34pt, Bold - Main screen titles
- **Title 1**: 28pt, Bold - Section headers
- **Title 2**: 22pt, Bold - Card titles, important labels
- **Title 3**: 20pt, Semibold - Subsection headers
- **Headline**: 17pt, Semibold - Post titles, button labels
- **Body**: 17pt, Regular - Main content text
- **Callout**: 16pt, Regular - Secondary content
- **Subheadline**: 15pt, Regular - Metadata, timestamps
- **Footnote**: 13pt, Regular - Fine print, disclaimers
- **Caption 1**: 12pt, Regular - Image captions, small labels
- **Caption 2**: 11pt, Regular - Smallest text elements

### Color System
- **Primary Colors**: Dynamic blue with light/dark variants
- **Semantic Colors**: Success (green), Warning (orange), Error (red)
- **Neutral Grays**: 10-step gray scale with adaptive variants
- **Category Colors**: Specific colors for post categorization
- **Sentiment Colors**: Positive (green), Negative (red), Neutral (gray)

## 🌓 Theme Management

The `ThemeManager` class provides:
- **Light/Dark/System** theme options
- Automatic system theme detection
- Persistent theme preferences
- Theme-aware color adaptations

## 🎭 Material Design System

### Glass Effects
- **Card**: Thin material for content cards
- **Overlay**: Regular material for modal overlays
- **Navigation**: Thick material for navigation bars
- **Modal**: Ultra-thick material for modal presentations

### Material Types
- Ultra Thin, Thin, Regular, Thick, Ultra Thick materials
- Automatic theme adaptation
- Consistent shadow and elevation system

## 🎬 Animation System

### Animation Preferences
- **Quick**: 0.15s - Immediate feedback
- **Standard**: 0.3s - Default animations
- **Slow**: 0.5s - Dramatic effects
- **Spring**: Consistent spring parameters
- **Reduced Motion**: Accessibility support

### Haptic Feedback
- Light, Medium, Heavy impact feedback
- Success, Warning, Error notification feedback
- Selection feedback for interactions
- User preference controls

## 🧩 Atomic Components

### GlassCard
- Material background effects
- Interactive and static variants
- Consistent styling and animations
- Press state handling

### ActionButton
- Multiple styles: Primary, Secondary, Tertiary, Destructive, Ghost
- Three sizes: Small, Medium, Large
- Loading states and haptic feedback
- Accessibility support

### CustomTextField
- Multiple types: Text, Email, Password, Search, Multiline
- Validation states and error handling
- Character counting and limits
- Focus states and animations

### LoadingSpinner
- Multiple styles: Circular, Dots, Pulse
- Three sizes with consistent scaling
- Progress indicators (linear and circular)
- Loading overlays

## 🎨 Typography System

### Semantic Styles
- Primary, Secondary, Tertiary text colors
- Success, Warning, Error message colors
- Link and placeholder text colors
- Automatic theme adaptation

### Font Weights
- Ultra Light through Black (9 weight variants)
- Consistent weight application
- Accessibility-friendly scaling

### Line Heights and Spacing
- Tight, Normal, Relaxed, Loose line heights
- Letter spacing variants
- Responsive text scaling

## 🌈 Color Palette

### Brand Colors
- Primary, Secondary, Accent colors
- Fallback colors for missing assets
- Consistent brand identity

### Semantic Colors
- Status colors (success, warning, error, info)
- Interactive colors (link, focus, selection)
- Content colors (text hierarchy)
- Background and surface colors

### Extended Palette
- Blues, Greens, Reds, Oranges, Purples
- 50/500/900 variants for each hue
- Category-specific color assignments

## ♿ Accessibility Features

### Color Contrast Validation
- WCAG AA/AAA compliance checking
- Automatic contrast ratio calculation
- Accessible color variant suggestions
- Real-time validation feedback

### Dynamic Type Support
- All text scales with system preferences
- Maintains readability at all sizes
- Proper touch target sizing

### Reduced Motion Support
- Respects system accessibility settings
- Graceful animation degradation
- Alternative interaction patterns

## 🚀 Usage Examples

### Basic Usage
```swift
// Using design tokens
VStack(spacing: DesignTokens.Spacing.md) {
    Text("Hello World")
        .font(DesignTokens.Typography.headline)
        .foregroundColor(DesignTokens.Colors.textPrimary)
}
.padding(DesignTokens.Spacing.lg)

// Using components
GlassCard.interactive(onTap: { print("Tapped!") }) {
    VStack {
        Text("Card Title")
            .font(DesignTokens.Typography.headline)
        Text("Card content goes here")
            .font(DesignTokens.Typography.body)
    }
}

ActionButton.primary("Save Changes") {
    // Handle save action
}
```

### Theme Management
```swift
struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        NavigationView {
            // Your content
        }
        .withThemeManagement()
        .environment(\.themeManager, themeManager)
    }
}
```

### Typography and Colors
```swift
// Using typography system
TypographyText("Welcome", style: .title1, weight: .bold)
TypographyText("Subtitle", style: .callout, semanticStyle: .secondary)

// Using dynamic colors
Rectangle()
    .fill(Color.dynamicPrimary)
    .foregroundColor(Color.dynamicText)
```

## 🔧 Integration

To integrate this design system into your views:

1. **Import the design system** in your SwiftUI views
2. **Apply theme management** at the app level using `.withThemeManagement()`
3. **Use design tokens** instead of hardcoded values
4. **Leverage atomic components** for consistent UI elements
5. **Follow accessibility guidelines** using the validation tools

## 📱 Requirements Satisfied

This implementation satisfies the following requirements from the UI remaster specification:

- **6.1**: Consistent styling, spacing, and visual hierarchy ✅
- **6.2**: Light and dark mode support with appropriate contrast ✅
- **6.3**: Smooth animations and transitions ✅
- **6.4**: Responsive layouts for different screen sizes ✅
- **6.5**: VoiceOver, Dynamic Type, and accessibility support ✅
- **6.6**: Polished skeleton screens and progress indicators ✅
- **6.7**: Clear, helpful error states and messaging ✅
- **8.4**: Haptic feedback for enhanced interactions ✅

The design system provides a solid foundation for building the rest of the UI remaster with consistency, accessibility, and polish.