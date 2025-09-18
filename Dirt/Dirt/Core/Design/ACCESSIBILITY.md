# Material Glass Accessibility Guide

This document provides comprehensive guidelines for implementing and maintaining accessibility in Material Glass components, ensuring WCAG 2.1 AA compliance and excellent user experience for all users.

## Table of Contents

1. [Overview](#overview)
2. [Accessibility System](#accessibility-system)
3. [Component Guidelines](#component-guidelines)
4. [Testing & Validation](#testing--validation)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

## Overview

The Material Glass design system prioritizes accessibility through:

- **WCAG 2.1 AA Compliance**: Meeting international accessibility standards
- **VoiceOver Support**: Full screen reader compatibility
- **Dynamic Type**: Responsive text scaling
- **Keyboard Navigation**: Complete keyboard accessibility
- **Reduced Motion**: Respecting user motion preferences
- **High Contrast**: Enhanced visibility options
- **Touch Targets**: Minimum 44x44pt interactive areas

## Accessibility System

### Core Components

The `AccessibilitySystem` provides centralized accessibility support:

```swift
import AccessibilitySystem

// Use accessible colors
.foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)

// Apply Dynamic Type scaling
.font(AccessibilitySystem.DynamicType.scaledFont(size: 16))

// Ensure minimum touch targets
.accessibleTouchTarget()

// Add focus support
.glassFocusRing(isFocused: isFocused)
```

### Key Features

#### Contrast Ratios
- **Normal Text**: 4.5:1 minimum contrast ratio
- **Large Text**: 3:1 minimum contrast ratio
- **UI Components**: 3:1 minimum contrast ratio
- **Enhanced**: 7:1 for better readability

#### Touch Targets
- **Minimum**: 44x44 points (iOS requirement)
- **Recommended**: 48x48 points
- **Large**: 56x56 points for important actions

#### Dynamic Type Support
- Automatic font and spacing scaling
- Maximum scale factor: 2.0x
- Minimum scale factor: 0.8x
- Respects user's text size preferences

## Component Guidelines

### GlassButton

```swift
GlassButton(
    "Save Document",
    systemImage: "doc.badge.plus",
    style: .primary,
    accessibilityLabel: "Save document button",
    accessibilityHint: "Double tap to save the current document"
) {
    // Action
}
```

**Accessibility Features:**
- ✅ Accessibility labels and hints
- ✅ Minimum 44x44pt touch target
- ✅ Dynamic Type support
- ✅ Focus ring for keyboard navigation
- ✅ High contrast support
- ✅ Reduced motion animations
- ✅ VoiceOver button trait

### GlassCard

```swift
GlassCard(
    accessibilityLabel: "User profile card",
    accessibilityHint: "Contains user information",
    isInteractive: true
) {
    // Card content
}
```

**Accessibility Features:**
- ✅ Configurable accessibility labels
- ✅ Interactive vs. static content support
- ✅ Dynamic Type scaling
- ✅ Focus support for interactive cards
- ✅ High contrast support

### GlassSearchBar

```swift
GlassSearchBar(
    text: $searchText,
    placeholder: "Search users...",
    accessibilityLabel: "User search field",
    accessibilityHint: "Enter text to search for users"
)
```

**Accessibility Features:**
- ✅ Search field accessibility trait
- ✅ Clear button with proper labeling
- ✅ Focus management
- ✅ VoiceOver announcements
- ✅ Keyboard navigation

### GlassToast

```swift
GlassToast(
    message: "Document saved successfully",
    type: .success,
    duration: 3.0
)
```

**Accessibility Features:**
- ✅ Automatic VoiceOver announcements
- ✅ Dismissible with accessibility action
- ✅ Proper notification traits
- ✅ Reduced motion support
- ✅ Unlimited text length for accessibility

### GlassNavigationBar

```swift
GlassNavigationBar(
    title: "Settings",
    accessibilityLabel: "Settings navigation bar"
) {
    // Leading content
} trailing: {
    // Trailing content
}
```

**Accessibility Features:**
- ✅ Header accessibility trait
- ✅ Minimum touch targets for buttons
- ✅ Dynamic Type support
- ✅ High contrast support

### GlassTabBar

```swift
let tabs = [
    GlassTabBar.TabItem(
        title: "Home",
        systemImage: "house",
        accessibilityLabel: "Home tab",
        accessibilityHint: "Navigate to home screen"
    )
]

GlassTabBar(selectedTab: $selectedTab, tabs: tabs)
```

**Accessibility Features:**
- ✅ Tab bar accessibility trait
- ✅ Selection state announcements
- ✅ Individual tab labeling
- ✅ Keyboard navigation support
- ✅ VoiceOver selection feedback

### GlassModal

```swift
GlassModal(
    isPresented: $isPresented,
    accessibilityLabel: "Settings modal",
    isDismissible: true
) {
    // Modal content
}
```

**Accessibility Features:**
- ✅ Modal accessibility trait
- ✅ Focus management
- ✅ VoiceOver announcements
- ✅ Dismissal accessibility actions
- ✅ Backdrop interaction handling

## Testing & Validation

### Automated Testing

Run the accessibility audit script:

```bash
./Dirt/Scripts/accessibility_audit.swift
```

This generates a comprehensive report covering:
- Component compliance scores
- Missing accessibility features
- Contrast ratio validation
- Best practice recommendations

### Manual Testing Checklist

#### VoiceOver Testing
- [ ] Enable VoiceOver (Settings > Accessibility > VoiceOver)
- [ ] Navigate through all components using swipe gestures
- [ ] Verify all interactive elements are announced
- [ ] Test custom actions and gestures
- [ ] Confirm proper reading order

#### Dynamic Type Testing
- [ ] Test with largest text size (Settings > Accessibility > Display & Text Size)
- [ ] Verify text remains readable and doesn't truncate
- [ ] Check that layouts adapt properly
- [ ] Ensure touch targets remain accessible

#### Keyboard Navigation Testing
- [ ] Connect external keyboard
- [ ] Navigate using Tab key
- [ ] Verify focus indicators are visible
- [ ] Test all keyboard shortcuts
- [ ] Confirm proper focus management

#### Reduced Motion Testing
- [ ] Enable Reduce Motion (Settings > Accessibility > Motion)
- [ ] Verify animations are simplified or removed
- [ ] Check that functionality remains intact
- [ ] Test transition alternatives

#### High Contrast Testing
- [ ] Enable Increase Contrast (Settings > Accessibility > Display & Text Size)
- [ ] Verify text remains readable
- [ ] Check that UI elements are distinguishable
- [ ] Test focus indicators visibility

### Unit Testing

```swift
func testGlassButtonAccessibility() {
    let button = GlassButton("Test") { }
        .glassAccessible(label: "Test button", traits: .isButton)
    
    // Verify accessibility properties
    XCTAssertNotNil(button)
}
```

### UI Testing

```swift
func testGlassButtonVoiceOver() {
    let app = XCUIApplication()
    app.launch()
    
    let button = app.buttons["Test Glass Button"]
    XCTAssertTrue(button.exists)
    XCTAssertTrue(button.isHittable)
}
```

## Best Practices

### 1. Always Provide Accessibility Labels

```swift
// ✅ Good
GlassButton("Save", accessibilityLabel: "Save document") { }

// ❌ Bad
GlassButton("💾") { } // Icon without label
```

### 2. Use Semantic Accessibility Traits

```swift
// ✅ Good
.accessibilityAddTraits(.isButton)
.accessibilityAddTraits(.isHeader)

// ❌ Bad
// No traits specified
```

### 3. Implement Dynamic Type Support

```swift
// ✅ Good
.font(AccessibilitySystem.DynamicType.scaledFont(size: 16))

// ❌ Bad
.font(.system(size: 16)) // Fixed size
```

### 4. Ensure Minimum Touch Targets

```swift
// ✅ Good
.accessibleTouchTarget()

// ❌ Bad
.frame(width: 20, height: 20) // Too small
```

### 5. Respect Reduced Motion

```swift
// ✅ Good
.animation(AccessibilitySystem.ReducedMotion.animation(.easeInOut))

// ❌ Bad
.animation(.bouncy) // Always animated
```

### 6. Provide VoiceOver Announcements

```swift
// ✅ Good
UIAccessibility.post(notification: .announcement, argument: "Document saved")

// ❌ Bad
// Silent state changes
```

### 7. Use High Contrast Colors

```swift
// ✅ Good
.foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)

// ❌ Bad
.foregroundColor(.gray) // May not meet contrast requirements
```

### 8. Implement Focus Management

```swift
// ✅ Good
@FocusState private var isFocused: Bool

var body: some View {
    TextField("Search", text: $text)
        .focused($isFocused)
        .glassFocusRing(isFocused: isFocused)
}
```

## Troubleshooting

### Common Issues

#### VoiceOver Not Announcing Elements

**Problem**: Interactive elements are not announced by VoiceOver.

**Solution**:
```swift
// Add accessibility label and traits
.accessibilityLabel("Button description")
.accessibilityAddTraits(.isButton)
```

#### Text Too Small with Dynamic Type

**Problem**: Text becomes unreadable at large Dynamic Type sizes.

**Solution**:
```swift
// Use scaled fonts with appropriate limits
.font(AccessibilitySystem.DynamicType.scaledFont(size: 16))
```

#### Touch Targets Too Small

**Problem**: Buttons are difficult to tap for users with motor impairments.

**Solution**:
```swift
// Ensure minimum 44x44pt touch targets
.accessibleTouchTarget()
```

#### Poor Contrast on Glass Backgrounds

**Problem**: Text is hard to read on Material Glass backgrounds.

**Solution**:
```swift
// Use accessible colors designed for glass backgrounds
.foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)
.glassHighContrast()
```

#### Animations Cause Motion Sickness

**Problem**: Animations are too intense for users with vestibular disorders.

**Solution**:
```swift
// Respect reduced motion preferences
.animation(AccessibilitySystem.ReducedMotion.animation(.spring()))
```

#### Focus Not Visible

**Problem**: Keyboard focus indicators are not visible.

**Solution**:
```swift
// Add visible focus ring
.glassFocusRing(isFocused: isFocused)
```

### Debugging Tools

#### Accessibility Inspector

1. Open Xcode
2. Go to Xcode > Open Developer Tool > Accessibility Inspector
3. Select your app
4. Run audit and inspect elements

#### VoiceOver Practice

1. Enable VoiceOver in Settings
2. Practice navigation gestures
3. Test your app regularly
4. Get feedback from VoiceOver users

#### Simulator Testing

1. Use iOS Simulator accessibility features
2. Test different Dynamic Type sizes
3. Enable accessibility settings
4. Verify behavior across devices

## Resources

### Apple Documentation
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [VoiceOver Testing Guide](https://developer.apple.com/documentation/accessibility/voiceover)
- [Dynamic Type Guide](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)

### WCAG Guidelines
- [WCAG 2.1 AA Guidelines](https://www.w3.org/WAI/WCAG21/quickref/?versions=2.1&levels=aa)
- [Color Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Testing Tools
- Xcode Accessibility Inspector
- iOS Simulator Accessibility Settings
- Physical Device Testing
- User Testing with Disabled Users

## Conclusion

Accessibility is not an afterthought but a fundamental part of the Material Glass design system. By following these guidelines and using the provided tools, you can create inclusive experiences that work for all users.

Remember to:
- Test early and often
- Get feedback from users with disabilities
- Stay updated with accessibility best practices
- Make accessibility a team responsibility

For questions or improvements to this guide, please reach out to the development team.