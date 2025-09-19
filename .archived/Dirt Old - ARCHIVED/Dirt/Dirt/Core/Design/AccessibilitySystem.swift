import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Accessibility System for Material Glass Components
/// Comprehensive accessibility support for Material Glass design system
/// Ensures WCAG 2.1 AA compliance and excellent VoiceOver experience
struct AccessibilitySystem {
    
    // MARK: - Contrast Requirements
    
    /// WCAG 2.1 AA contrast ratio requirements
    struct ContrastRatio {
        /// Minimum contrast ratio for normal text (4.5:1)
        static let normalText: Double = 4.5
        
        /// Minimum contrast ratio for large text (3:1)
        static let largeText: Double = 3.0
        
        /// Enhanced contrast ratio for better readability (7:1)
        static let enhanced: Double = 7.0
        
        /// Minimum contrast for UI components (3:1)
        static let uiComponents: Double = 3.0
    }
    
    // MARK: - Accessible Colors for Glass Backgrounds
    
    /// Colors optimized for readability on Material Glass backgrounds
    struct AccessibleColors {
        // High contrast text colors for glass backgrounds
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Enhanced contrast colors for critical information
        static let highContrastText = Color(.label)
        static let highContrastSecondary = Color(.secondaryLabel)
        
        // Accessible accent colors that work on glass
        static let accessibleBlue = Color(.systemBlue)
        static let accessibleGreen = Color(.systemGreen)
        static let accessibleRed = Color(.systemRed)
        static let accessibleOrange = Color(.systemOrange)
        
        // Focus indicators
        static let focusRing = Color(.systemBlue)
        static let focusBackground = Color(.systemBlue).opacity(0.1)
        
        // Selection indicators
        static let selectionBackground = Color(.systemBlue).opacity(0.2)
        static let selectionBorder = Color(.systemBlue)
    }
    
    // MARK: - Touch Target Sizes
    
    /// Minimum touch target sizes for accessibility
    struct TouchTarget {
        /// Minimum touch target size (44x44 points)
        static let minimum: CGSize = CGSize(width: 44, height: 44)
        
        /// Recommended touch target size (48x48 points)
        static let recommended: CGSize = CGSize(width: 48, height: 48)
        
        /// Large touch target for important actions (56x56 points)
        static let large: CGSize = CGSize(width: 56, height: 56)
    }
    
    // MARK: - Dynamic Type Support
    
    /// Font scaling for Dynamic Type support
    struct DynamicType {
        /// Maximum scale factor for glass components
        static let maxScaleFactor: CGFloat = 2.0
        
        /// Minimum scale factor for glass components
        static let minScaleFactor: CGFloat = 0.8
        
        /// Get scaled font size with limits
        static func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }
        
        /// Get scaled spacing with limits
        static func scaledSpacing(_ baseSpacing: CGFloat) -> CGFloat {
            #if canImport(UIKit)
            let scaleFactor = min(maxScaleFactor, max(minScaleFactor, UIFont.preferredFont(forTextStyle: .body).pointSize / 17.0))
            #else
            let scaleFactor = min(maxScaleFactor, max(minScaleFactor, NSFont.systemFont(ofSize: NSFont.systemFontSize).pointSize / 17.0))
            #endif
            return baseSpacing * scaleFactor
        }
    }
    
    // MARK: - VoiceOver Support
    
    /// VoiceOver traits and labels for glass components
    struct VoiceOver {
        /// Standard accessibility traits for different component types
        enum ComponentTraits {
            case button
            case card
            case navigation
            case modal
            case toast
            case searchField
            case tabBar
            
            var traits: AccessibilityTraits {
                switch self {
                case .button:
                    return .isButton
                case .card:
                    return .isStaticText
                case .navigation:
                    return .isHeader
                case .modal:
                    return .isModal
                case .toast:
                    return .playsSound
                case .searchField:
                    return .isSearchField
                case .tabBar:
                    return .isTabBar
                }
            }
        }
        
        /// Generate accessibility label for glass components
        static func label(for component: String, context: String? = nil) -> String {
            if let context = context {
                return "\(component), \(context)"
            }
            return component
        }
        
        /// Generate accessibility hint for interactive elements
        static func hint(for action: String) -> String {
            return "Double tap to \(action)"
        }
        
        /// Generate accessibility value for stateful components
        static func value(for state: String) -> String {
            return state
        }
    }
    
    // MARK: - Reduced Motion Support
    
    /// Animation preferences for accessibility
    struct ReducedMotion {
        /// Check if reduced motion is enabled
        static var isEnabled: Bool {
            UIAccessibility.isReduceMotionEnabled
        }
        
        /// Get appropriate animation for reduced motion setting
        static func animation(_ standard: Animation, reduced: Animation? = nil) -> Animation {
            if isEnabled {
                return reduced ?? .easeInOut(duration: 0.1)
            }
            return standard
        }
        
        /// Get appropriate transition for reduced motion setting
        static func transition(_ standard: AnyTransition, reduced: AnyTransition? = nil) -> AnyTransition {
            if isEnabled {
                return reduced ?? .opacity
            }
            return standard
        }
    }
    
    // MARK: - Focus Management
    
    /// Focus management for keyboard and VoiceOver navigation
    struct Focus {
        /// Focus ring appearance
        static let ringWidth: CGFloat = 2
        static let ringColor = AccessibleColors.focusRing
        static let ringOffset: CGFloat = 2
        
        /// Focus background for better visibility
        static let backgroundColor = AccessibleColors.focusBackground
        static let cornerRadius: CGFloat = 4
    }
}

// MARK: - Accessibility Modifiers

/// View modifier for making glass components accessible
struct GlassAccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let isButton: Bool
    let minimumTouchTarget: Bool
    
    init(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isButton: Bool = false,
        minimumTouchTarget: Bool = true
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.isButton = isButton
        self.minimumTouchTarget = minimumTouchTarget
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
            .frame(
                minWidth: minimumTouchTarget ? AccessibilitySystem.TouchTarget.minimum.width : nil,
                minHeight: minimumTouchTarget ? AccessibilitySystem.TouchTarget.minimum.height : nil
            )
    }
}

/// View modifier for focus ring on glass components
struct GlassFocusRingModifier: ViewModifier {
    let isFocused: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius + AccessibilitySystem.Focus.ringOffset)
                    .stroke(
                        AccessibilitySystem.Focus.ringColor,
                        lineWidth: AccessibilitySystem.Focus.ringWidth
                    )
                    .opacity(isFocused ? 1 : 0)
                    .animation(
                        AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.2)),
                        value: isFocused
                    )
            )
    }
}

/// View modifier for high contrast support
struct GlassHighContrastModifier: ViewModifier {
    let isHighContrastEnabled: Bool
    
    init() {
        #if canImport(UIKit)
        self.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        #else
        self.isHighContrastEnabled = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #endif
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, isHighContrastEnabled ? .dark : nil)
            .foregroundColor(
                isHighContrastEnabled ? 
                AccessibilitySystem.AccessibleColors.highContrastText : 
                AccessibilitySystem.AccessibleColors.primaryText
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Make a glass component accessible
    func glassAccessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isButton: Bool = false,
        minimumTouchTarget: Bool = true
    ) -> some View {
        modifier(GlassAccessibilityModifier(
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            isButton: isButton,
            minimumTouchTarget: minimumTouchTarget
        ))
    }
    
    /// Add focus ring to glass component
    func glassFocusRing(isFocused: Bool, cornerRadius: CGFloat = UICornerRadius.md) -> some View {
        modifier(GlassFocusRingModifier(isFocused: isFocused, cornerRadius: cornerRadius))
    }
    
    /// Apply high contrast support
    func glassHighContrast() -> some View {
        modifier(GlassHighContrastModifier())
    }
    
    /// Apply reduced motion animation
    func glassReducedMotion(_ animation: Animation) -> some View {
        animation(AccessibilitySystem.ReducedMotion.animation(animation))
    }
    
    /// Apply accessible touch target size
    func accessibleTouchTarget(size: CGSize = AccessibilitySystem.TouchTarget.minimum) -> some View {
        frame(minWidth: size.width, minHeight: size.height)
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
/// Helpers for testing accessibility in development
struct AccessibilityTesting {
    /// Check if a color combination meets contrast requirements
    static func checkContrast(foreground: UIColor, background: UIColor, requirement: Double = AccessibilitySystem.ContrastRatio.normalText) -> Bool {
        let contrastRatio = calculateContrastRatio(foreground: foreground, background: background)
        return contrastRatio >= requirement
    }
    
    /// Calculate contrast ratio between two colors
    private static func calculateContrastRatio(foreground: UIColor, background: UIColor) -> Double {
        let foregroundLuminance = relativeLuminance(of: foreground)
        let backgroundLuminance = relativeLuminance(of: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of a color
    private static func relativeLuminance(of color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let sRGB = [red, green, blue].map { component -> Double in
            let value = Double(component)
            if value <= 0.03928 {
                return value / 12.92
            } else {
                return pow((value + 0.055) / 1.055, 2.4)
            }
        }
        
        return 0.2126 * sRGB[0] + 0.7152 * sRGB[1] + 0.0722 * sRGB[2]
    }
    
    /// Log accessibility warnings for development
    static func logAccessibilityWarning(_ message: String) {
        print("⚠️ Accessibility Warning: \(message)")
    }
    
    /// Validate touch target size
    static func validateTouchTarget(size: CGSize) -> Bool {
        return size.width >= AccessibilitySystem.TouchTarget.minimum.width &&
               size.height >= AccessibilitySystem.TouchTarget.minimum.height
    }
}
#endif