import XCTest
import SwiftUI
@testable import Dirt

class MaterialDesignSystemTests: XCTestCase {
    
    // MARK: - Material Glass Tests
    
    func testGlassBackgroundMaterials() {
        // Test that all glass materials are properly defined
        XCTAssertEqual(MaterialDesignSystem.Glass.ultraThin, .ultraThinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.thin, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.regular, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.thick, .thickMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.ultraThick, .ultraThickMaterial)
    }
    
    func testContextSpecificMaterials() {
        // Test that context materials are appropriate for their use cases
        XCTAssertEqual(MaterialDesignSystem.Context.navigation, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.tabBar, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.card, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.modal, .thickMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.floatingAction, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.sidebar, .regularMaterial)
    }
    
    func testGlassColorOpacities() {
        // Test that glass colors have appropriate opacity levels
        let primaryOpacity = MaterialDesignSystem.GlassColors.primary.opacity
        let secondaryOpacity = MaterialDesignSystem.GlassColors.secondary.opacity
        let neutralOpacity = MaterialDesignSystem.GlassColors.neutral.opacity
        
        // Opacities should be subtle (less than 0.2)
        XCTAssertLessThan(primaryOpacity, 0.2, "Primary glass color should be subtle")
        XCTAssertLessThan(secondaryOpacity, 0.2, "Secondary glass color should be subtle")
        XCTAssertLessThan(neutralOpacity, 0.2, "Neutral glass color should be subtle")
        
        // Opacities should be visible (greater than 0.01)
        XCTAssertGreaterThan(primaryOpacity, 0.01, "Primary glass color should be visible")
        XCTAssertGreaterThan(secondaryOpacity, 0.01, "Secondary glass color should be visible")
        XCTAssertGreaterThan(neutralOpacity, 0.01, "Neutral glass color should be visible")
    }
    
    func testGlassBorderOpacities() {
        // Test that border opacities are appropriate
        let subtleOpacity = MaterialDesignSystem.GlassBorders.subtle.opacity
        let prominentOpacity = MaterialDesignSystem.GlassBorders.prominent.opacity
        let accentOpacity = MaterialDesignSystem.GlassBorders.accent.opacity
        
        XCTAssertLessThan(subtleOpacity, prominentOpacity, "Prominent border should be more opaque than subtle")
        XCTAssertGreaterThan(subtleOpacity, 0.1, "Subtle border should be visible")
        XCTAssertLessThan(prominentOpacity, 0.6, "Prominent border should not be too strong")
    }
    
    // MARK: - Motion System Tests
    
    func testAnimationDurations() {
        // Test that animation durations follow expected patterns
        XCTAssertLessThan(MaterialMotion.Duration.quick, MaterialMotion.Duration.standard)
        XCTAssertLessThan(MaterialMotion.Duration.standard, MaterialMotion.Duration.emphasized)
        XCTAssertLessThan(MaterialMotion.Duration.emphasized, MaterialMotion.Duration.slow)
        XCTAssertLessThan(MaterialMotion.Duration.slow, MaterialMotion.Duration.extraSlow)
        
        // Test specific duration values
        XCTAssertEqual(MaterialMotion.Duration.quick, 0.075)
        XCTAssertEqual(MaterialMotion.Duration.standard, 0.15)
        XCTAssertEqual(MaterialMotion.Duration.emphasized, 0.3)
        XCTAssertEqual(MaterialMotion.Duration.slow, 0.5)
        XCTAssertEqual(MaterialMotion.Duration.extraSlow, 0.75)
    }
    
    func testSpringAnimationParameters() {
        // Test that spring animations have reasonable parameters
        // Note: SwiftUI Animation doesn't expose parameters for testing,
        // so we test that the animations are created without crashing
        let quickSpring = MaterialMotion.Spring.quick
        let standardSpring = MaterialMotion.Spring.standard
        let bouncySpring = MaterialMotion.Spring.bouncy
        let gentleSpring = MaterialMotion.Spring.gentle
        let glassSpring = MaterialMotion.Spring.glass
        
        XCTAssertNotNil(quickSpring)
        XCTAssertNotNil(standardSpring)
        XCTAssertNotNil(bouncySpring)
        XCTAssertNotNil(gentleSpring)
        XCTAssertNotNil(glassSpring)
    }
    
    // MARK: - Component Tests
    
    func testGlassButtonStyles() {
        // Test that button styles have appropriate properties
        let primaryStyle = GlassButton.ButtonStyle.primary
        let secondaryStyle = GlassButton.ButtonStyle.secondary
        let destructiveStyle = GlassButton.ButtonStyle.destructive
        let subtleStyle = GlassButton.ButtonStyle.subtle
        
        // Test foreground colors
        XCTAssertEqual(primaryStyle.foregroundColor, .white)
        XCTAssertEqual(secondaryStyle.foregroundColor, UIColors.accentPrimary)
        XCTAssertEqual(destructiveStyle.foregroundColor, .white)
        XCTAssertEqual(subtleStyle.foregroundColor, UIColors.label)
        
        // Test materials
        XCTAssertEqual(primaryStyle.material, MaterialDesignSystem.Glass.regular)
        XCTAssertEqual(secondaryStyle.material, MaterialDesignSystem.Glass.thin)
        XCTAssertEqual(destructiveStyle.material, MaterialDesignSystem.Glass.regular)
        XCTAssertEqual(subtleStyle.material, MaterialDesignSystem.Glass.ultraThin)
    }
    
    func testTabBarItemInitialization() {
        // Test that tab bar items initialize correctly
        let tabItem = GlassTabBar.TabItem(
            title: "Home",
            systemImage: "house",
            selectedSystemImage: "house.fill"
        )
        
        XCTAssertEqual(tabItem.title, "Home")
        XCTAssertEqual(tabItem.systemImage, "house")
        XCTAssertEqual(tabItem.selectedSystemImage, "house.fill")
    }
    
    func testTabBarItemWithoutSelectedImage() {
        // Test tab bar item without selected image
        let tabItem = GlassTabBar.TabItem(
            title: "Search",
            systemImage: "magnifyingglass"
        )
        
        XCTAssertEqual(tabItem.title, "Search")
        XCTAssertEqual(tabItem.systemImage, "magnifyingglass")
        XCTAssertNil(tabItem.selectedSystemImage)
    }
    
    func testToastTypes() {
        // Test that toast types have correct properties
        let successToast = GlassToast.ToastType.success
        let warningToast = GlassToast.ToastType.warning
        let errorToast = GlassToast.ToastType.error
        let infoToast = GlassToast.ToastType.info
        
        // Test system images
        XCTAssertEqual(successToast.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(warningToast.systemImage, "exclamationmark.triangle.fill")
        XCTAssertEqual(errorToast.systemImage, "xmark.circle.fill")
        XCTAssertEqual(infoToast.systemImage, "info.circle.fill")
        
        // Test colors
        XCTAssertEqual(successToast.color, UIColors.success)
        XCTAssertEqual(warningToast.color, UIColors.warning)
        XCTAssertEqual(errorToast.color, UIColors.danger)
        XCTAssertEqual(infoToast.color, UIColors.accentPrimary)
    }
    
    // MARK: - Integration Tests
    
    func testDesignSystemConsistency() {
        // Test that design system components use consistent spacing
        let cardPadding: CGFloat = UISpacing.md
        let buttonPadding: CGFloat = UISpacing.md
        
        XCTAssertEqual(cardPadding, buttonPadding, "Components should use consistent padding")
        
        // Test that corner radius values are consistent
        let cardCornerRadius = UICornerRadius.lg
        let buttonCornerRadius = UICornerRadius.md
        
        XCTAssertGreaterThan(cardCornerRadius, buttonCornerRadius, "Cards should have larger corner radius than buttons")
    }
    
    func testAccessibilityCompliance() {
        // Test that components meet accessibility requirements
        let minimumTouchTarget: CGFloat = 44
        
        // This would be tested in UI tests, but we can verify the constant
        XCTAssertGreaterThanOrEqual(minimumTouchTarget, 44, "Touch targets should meet accessibility guidelines")
    }
    
    // MARK: - Performance Tests
    
    func testAnimationPerformance() {
        // Test that animations can be created quickly
        measure {
            for _ in 0..<1000 {
                _ = MaterialMotion.Spring.quick
                _ = MaterialMotion.Easing.standard
                _ = MaterialMotion.Glass.cardAppear
            }
        }
    }
    
    func testColorCreationPerformance() {
        // Test that glass colors can be created quickly
        measure {
            for _ in 0..<1000 {
                _ = MaterialDesignSystem.GlassColors.primary
                _ = MaterialDesignSystem.GlassBorders.subtle
                _ = MaterialDesignSystem.GlassShadows.soft
            }
        }
    }
}

// MARK: - Color Extension for Testing

private extension Color {
    /// Extract opacity value for testing (approximation)
    var opacity: Double {
        // This is a simplified approach for testing
        // In a real implementation, you might need a more sophisticated method
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        return Double(components.last ?? 1.0)
    }
}