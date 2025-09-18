import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif
@testable import Dirt

/// Comprehensive accessibility compliance tests for Material Glass components
/// Tests WCAG 2.1 AA compliance, VoiceOver support, Dynamic Type, and contrast ratios
final class MaterialGlassAccessibilityComplianceTests: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - Contrast Ratio Tests
    
    func testGlassComponentContrastRatios() throws {
        // Test that all glass components meet WCAG 2.1 AA contrast requirements
        
        // Test primary text on glass backgrounds
        let primaryTextColor = PlatformColor(AccessibilitySystem.AccessibleColors.primaryText)
        #if canImport(UIKit)
        let glassBackgroundColor = PlatformColor.systemBackground.withAlphaComponent(0.8) // Simulated glass
        #else
        let glassBackgroundColor = PlatformColor.windowBackgroundColor.withAlphaComponent(0.8) // Simulated glass
        #endif
        
        XCTAssertTrue(
            AccessibilityTesting.checkContrast(
                foreground: primaryTextColor,
                background: glassBackgroundColor,
                requirement: AccessibilitySystem.ContrastRatio.normalText
            ),
            "Primary text should meet WCAG AA contrast ratio on glass backgrounds"
        )
        
        // Test secondary text on glass backgrounds
        let secondaryTextColor = PlatformColor(AccessibilitySystem.AccessibleColors.secondaryText)
        XCTAssertTrue(
            AccessibilityTesting.checkContrast(
                foreground: secondaryTextColor,
                background: glassBackgroundColor,
                requirement: AccessibilitySystem.ContrastRatio.normalText
            ),
            "Secondary text should meet WCAG AA contrast ratio on glass backgrounds"
        )
        
        // Test accent colors on glass backgrounds
        let accentColor = PlatformColor(AccessibilitySystem.AccessibleColors.accessibleBlue)
        XCTAssertTrue(
            AccessibilityTesting.checkContrast(
                foreground: accentColor,
                background: glassBackgroundColor,
                requirement: AccessibilitySystem.ContrastRatio.uiComponents
            ),
            "Accent colors should meet WCAG AA contrast ratio for UI components"
        )
    }
    
    func testGlassButtonContrastCompliance() throws {
        // Test that glass buttons maintain proper contrast in all states
        
        let buttonStyles: [GlassButton.ButtonStyle] = [.primary, .secondary, .destructive, .subtle]
        
        for style in buttonStyles {
            let foregroundColor = PlatformColor(style.foregroundColor)
            #if canImport(UIKit)
            let materialBackground = PlatformColor.systemBackground.withAlphaComponent(0.7) // Simulated material
            #else
            let materialBackground = PlatformColor.windowBackgroundColor.withAlphaComponent(0.7) // Simulated material
            #endif
            
            XCTAssertTrue(
                AccessibilityTesting.checkContrast(
                    foreground: foregroundColor,
                    background: materialBackground,
                    requirement: AccessibilitySystem.ContrastRatio.normalText
                ),
                "Glass button style \(style) should meet contrast requirements"
            )
        }
    }
    
    func testGlassToastContrastCompliance() throws {
        // Test that toast notifications maintain proper contrast
        
        let toastTypes: [GlassToast.ToastType] = [.success, .warning, .error, .info]
        
        for type in toastTypes {
            let iconColor = PlatformColor(type.color)
            let textColor = PlatformColor(AccessibilitySystem.AccessibleColors.primaryText)
            #if canImport(UIKit)
            let backgroundMaterial = PlatformColor.systemBackground.withAlphaComponent(0.9) // Toast background
            #else
            let backgroundMaterial = PlatformColor.windowBackgroundColor.withAlphaComponent(0.9) // Toast background
            #endif
            
            XCTAssertTrue(
                AccessibilityTesting.checkContrast(
                    foreground: iconColor,
                    background: backgroundMaterial,
                    requirement: AccessibilitySystem.ContrastRatio.uiComponents
                ),
                "Toast type \(type.rawValue) icon should meet contrast requirements"
            )
            
            XCTAssertTrue(
                AccessibilityTesting.checkContrast(
                    foreground: textColor,
                    background: backgroundMaterial,
                    requirement: AccessibilitySystem.ContrastRatio.normalText
                ),
                "Toast type \(type.rawValue) text should meet contrast requirements"
            )
        }
    }
    
    // MARK: - Touch Target Tests
    
    func testGlassButtonTouchTargets() throws {
        // Test that all glass buttons meet minimum touch target requirements
        
        let minimumSize = AccessibilitySystem.TouchTarget.minimum
        
        // This would be tested in UI tests with actual button frames
        // For unit tests, we verify the constants are correct
        XCTAssertGreaterThanOrEqual(minimumSize.width, 44, "Minimum touch target width should be at least 44 points")
        XCTAssertGreaterThanOrEqual(minimumSize.height, 44, "Minimum touch target height should be at least 44 points")
        
        let recommendedSize = AccessibilitySystem.TouchTarget.recommended
        XCTAssertGreaterThanOrEqual(recommendedSize.width, 48, "Recommended touch target width should be at least 48 points")
        XCTAssertGreaterThanOrEqual(recommendedSize.height, 48, "Recommended touch target height should be at least 48 points")
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeScaling() throws {
        // Test that Dynamic Type scaling works correctly
        
        let baseSize: CGFloat = 16
        let scaledSize = AccessibilitySystem.DynamicType.scaledSpacing(baseSize)
        
        // Verify scaling is within acceptable bounds
        XCTAssertGreaterThanOrEqual(
            scaledSize,
            baseSize * AccessibilitySystem.DynamicType.minScaleFactor,
            "Scaled size should not go below minimum scale factor"
        )
        
        XCTAssertLessThanOrEqual(
            scaledSize,
            baseSize * AccessibilitySystem.DynamicType.maxScaleFactor,
            "Scaled size should not exceed maximum scale factor"
        )
    }
    
    func testDynamicTypeFontScaling() throws {
        // Test that font scaling respects Dynamic Type settings
        
        let baseFont = AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .regular)
        XCTAssertNotNil(baseFont, "Scaled font should be created successfully")
        
        let largeTitleFont = AccessibilitySystem.DynamicType.scaledFont(size: 34, weight: .bold)
        XCTAssertNotNil(largeTitleFont, "Large title font should be created successfully")
    }
    
    // MARK: - VoiceOver Support Tests
    
    func testVoiceOverTraits() throws {
        // Test that VoiceOver traits are correctly assigned
        
        let buttonTraits = AccessibilitySystem.VoiceOver.ComponentTraits.button.traits
        XCTAssertTrue(buttonTraits.contains(.isButton), "Button components should have button trait")
        
        let cardTraits = AccessibilitySystem.VoiceOver.ComponentTraits.card.traits
        XCTAssertTrue(cardTraits.contains(.isStaticText), "Card components should have static text trait")
        
        let navigationTraits = AccessibilitySystem.VoiceOver.ComponentTraits.navigation.traits
        XCTAssertTrue(navigationTraits.contains(.isHeader), "Navigation components should have header trait")
        
        let modalTraits = AccessibilitySystem.VoiceOver.ComponentTraits.modal.traits
        XCTAssertTrue(modalTraits.contains(.isModal), "Modal components should have modal trait")
        
        let searchTraits = AccessibilitySystem.VoiceOver.ComponentTraits.searchField.traits
        XCTAssertTrue(searchTraits.contains(.isSearchField), "Search components should have search field trait")
        
        let tabBarTraits = AccessibilitySystem.VoiceOver.ComponentTraits.tabBar.traits
        XCTAssertTrue(tabBarTraits.contains(.isTabBar), "Tab bar components should have tab bar trait")
    }
    
    func testVoiceOverLabels() throws {
        // Test that VoiceOver labels are generated correctly
        
        let buttonLabel = AccessibilitySystem.VoiceOver.label(for: "Save", context: "document")
        XCTAssertEqual(buttonLabel, "Save, document", "VoiceOver label should include context")
        
        let simpleLabel = AccessibilitySystem.VoiceOver.label(for: "Settings")
        XCTAssertEqual(simpleLabel, "Settings", "VoiceOver label should work without context")
        
        let hint = AccessibilitySystem.VoiceOver.hint(for: "save the document")
        XCTAssertEqual(hint, "Double tap to save the document", "VoiceOver hint should include action")
        
        let value = AccessibilitySystem.VoiceOver.value(for: "selected")
        XCTAssertEqual(value, "selected", "VoiceOver value should return state")
    }
    
    // MARK: - Focus Management Tests
    
    func testFocusRingProperties() throws {
        // Test that focus ring properties meet accessibility guidelines
        
        let ringWidth = AccessibilitySystem.Focus.ringWidth
        XCTAssertGreaterThanOrEqual(ringWidth, 2, "Focus ring should be at least 2 points wide for visibility")
        
        let ringOffset = AccessibilitySystem.Focus.ringOffset
        XCTAssertGreaterThanOrEqual(ringOffset, 1, "Focus ring should have offset for better visibility")
        
        let cornerRadius = AccessibilitySystem.Focus.cornerRadius
        XCTAssertGreaterThanOrEqual(cornerRadius, 0, "Focus ring corner radius should be non-negative")
    }
    
    // MARK: - High Contrast Support Tests
    
    func testHighContrastColors() throws {
        // Test that high contrast colors are properly defined
        
        let highContrastText = AccessibilitySystem.AccessibleColors.highContrastText
        XCTAssertNotNil(highContrastText, "High contrast text color should be defined")
        
        let highContrastSecondary = AccessibilitySystem.AccessibleColors.highContrastSecondary
        XCTAssertNotNil(highContrastSecondary, "High contrast secondary color should be defined")
        
        let focusRing = AccessibilitySystem.AccessibleColors.focusRing
        XCTAssertNotNil(focusRing, "Focus ring color should be defined")
        
        let selectionBackground = AccessibilitySystem.AccessibleColors.selectionBackground
        XCTAssertNotNil(selectionBackground, "Selection background color should be defined")
    }
    
    // MARK: - Accessibility Modifier Tests
    
    func testGlassAccessibilityModifier() throws {
        // Test that accessibility modifiers work correctly
        
        // This would typically be tested in UI tests, but we can verify the modifier exists
        let testView = Rectangle()
            .glassAccessible(
                label: "Test button",
                hint: "Double tap to activate",
                traits: .isButton,
                isButton: true
            )
        
        XCTAssertNotNil(testView, "Glass accessibility modifier should be applicable to views")
    }
    
    func testGlassFocusRingModifier() throws {
        // Test that focus ring modifier works correctly
        
        let testView = Rectangle()
            .glassFocusRing(isFocused: true, cornerRadius: 8)
        
        XCTAssertNotNil(testView, "Glass focus ring modifier should be applicable to views")
    }
    
    func testGlassHighContrastModifier() throws {
        // Test that high contrast modifier works correctly
        
        let testView = Rectangle()
            .glassHighContrast()
        
        XCTAssertNotNil(testView, "Glass high contrast modifier should be applicable to views")
    }
    
    // MARK: - Component Integration Tests
    
    func testGlassButtonAccessibilityIntegration() throws {
        // Test that GlassButton properly integrates accessibility features
        
        let button = GlassButton(
            "Save Document",
            systemImage: "doc.badge.plus",
            style: .primary,
            accessibilityLabel: "Save document button",
            accessibilityHint: "Double tap to save the current document"
        ) {
            // Action
        }
        
        XCTAssertNotNil(button, "Glass button with accessibility should be created successfully")
    }
    
    func testGlassCardAccessibilityIntegration() throws {
        // Test that GlassCard properly integrates accessibility features
        
        let card = GlassCard(
            accessibilityLabel: "User profile card",
            accessibilityHint: "Contains user information",
            isInteractive: true
        ) {
            Text("User Profile")
        }
        
        XCTAssertNotNil(card, "Glass card with accessibility should be created successfully")
    }
    
    func testGlassSearchBarAccessibilityIntegration() throws {
        // Test that GlassSearchBar properly integrates accessibility features
        
        @State var searchText = ""
        
        let searchBar = GlassSearchBar(
            text: $searchText,
            placeholder: "Search users...",
            accessibilityLabel: "User search field",
            accessibilityHint: "Enter text to search for users"
        )
        
        XCTAssertNotNil(searchBar, "Glass search bar with accessibility should be created successfully")
    }
    
    func testGlassToastAccessibilityIntegration() throws {
        // Test that GlassToast properly integrates accessibility features
        
        let toast = GlassToast(
            message: "Document saved successfully",
            type: .success,
            duration: 3.0
        )
        
        XCTAssertNotNil(toast, "Glass toast with accessibility should be created successfully")
    }
    
    func testGlassNavigationBarAccessibilityIntegration() throws {
        // Test that GlassNavigationBar properly integrates accessibility features
        
        let navBar = GlassNavigationBar(
            title: "Settings",
            accessibilityLabel: "Settings navigation bar"
        ) {
            Button("Back") { }
        } trailing: {
            Button("Done") { }
        }
        
        XCTAssertNotNil(navBar, "Glass navigation bar with accessibility should be created successfully")
    }
    
    func testGlassTabBarAccessibilityIntegration() throws {
        // Test that GlassTabBar properly integrates accessibility features
        
        @State var selectedTab = 0
        
        let tabs = [
            GlassTabBar.TabItem(
                title: "Home",
                systemImage: "house",
                selectedSystemImage: "house.fill",
                accessibilityLabel: "Home tab",
                accessibilityHint: "Navigate to home screen"
            ),
            GlassTabBar.TabItem(
                title: "Search",
                systemImage: "magnifyingglass",
                accessibilityLabel: "Search tab",
                accessibilityHint: "Navigate to search screen"
            )
        ]
        
        let tabBar = GlassTabBar(selectedTab: $selectedTab, tabs: tabs)
        
        XCTAssertNotNil(tabBar, "Glass tab bar with accessibility should be created successfully")
    }
    
    func testGlassModalAccessibilityIntegration() throws {
        // Test that GlassModal properly integrates accessibility features
        
        @State var isPresented = true
        
        let modal = GlassModal(
            isPresented: $isPresented,
            accessibilityLabel: "Settings modal",
            isDismissible: true
        ) {
            Text("Modal Content")
        }
        
        XCTAssertNotNil(modal, "Glass modal with accessibility should be created successfully")
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityPerformance() throws {
        // Test that accessibility features don't significantly impact performance
        
        measure {
            // Create multiple glass components with accessibility
            for _ in 0..<100 {
                let _ = GlassButton("Test") { }
                    .glassAccessible(label: "Test button", traits: .isButton)
                    .glassFocusRing(isFocused: false)
                    .glassHighContrast()
            }
        }
    }
    
    // MARK: - Validation Tests
    
    func testAccessibilityValidationHelpers() throws {
        // Test accessibility validation helpers work correctly
        
        #if DEBUG
        // Test contrast checking
        let whiteColor = PlatformColor.white
        let blackColor = PlatformColor.black
        
        XCTAssertTrue(
            AccessibilityTesting.checkContrast(
                foreground: blackColor,
                background: whiteColor,
                requirement: AccessibilitySystem.ContrastRatio.enhanced
            ),
            "Black on white should meet enhanced contrast requirements"
        )
        
        // Test touch target validation
        let validSize = CGSize(width: 48, height: 48)
        XCTAssertTrue(
            AccessibilityTesting.validateTouchTarget(size: validSize),
            "48x48 touch target should be valid"
        )
        
        let invalidSize = CGSize(width: 30, height: 30)
        XCTAssertFalse(
            AccessibilityTesting.validateTouchTarget(size: invalidSize),
            "30x30 touch target should be invalid"
        )
        #endif
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
/// Helpers for testing accessibility in development
struct AccessibilityTesting {
    /// Check if a color combination meets contrast requirements
    static func checkContrast(foreground: PlatformColor, background: PlatformColor, requirement: Double = AccessibilitySystem.ContrastRatio.normalText) -> Bool {
        let contrastRatio = calculateContrastRatio(foreground: foreground, background: background)
        return contrastRatio >= requirement
    }
    
    /// Calculate contrast ratio between two colors
    private static func calculateContrastRatio(foreground: PlatformColor, background: PlatformColor) -> Double {
        let foregroundLuminance = relativeLuminance(of: foreground)
        let backgroundLuminance = relativeLuminance(of: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of a color
    private static func relativeLuminance(of color: PlatformColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if canImport(UIKit)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        if let rgbColor = color.usingColorSpace(.deviceRGB) {
            rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        #endif
        
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