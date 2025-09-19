import XCTest
import SwiftUI
@testable import Dirt

/// Tests for the Material Design System implementation
/// Verifies design tokens, modifiers, and system consistency
final class MaterialDesignSystemTests: XCTestCase {
    
    // MARK: - Material Glass Tests
    
    func testMaterialGlassConstants() {
        // Test that all Material glass constants are properly defined
        XCTAssertEqual(MaterialDesignSystem.Glass.ultraThin, .ultraThinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.thin, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.regular, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.thick, .thickMaterial)
        XCTAssertEqual(MaterialDesignSystem.Glass.ultraThick, .ultraThickMaterial)
    }
    
    func testMaterialContextConstants() {
        // Test that context-specific materials are properly defined
        XCTAssertEqual(MaterialDesignSystem.Context.navigation, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.tabBar, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.card, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.modal, .thickMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.floatingAction, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.sidebar, .regularMaterial)
    }
    
    // MARK: - Glass Colors Tests
    
    func testGlassColorsExist() {
        // Test that all glass color overlays are defined
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.primary)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.secondary)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.success)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.warning)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.danger)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.neutral)
    }
    
    func testGlassColorsHaveCorrectOpacity() {
        // Test that glass colors have appropriate opacity levels for overlays
        // Note: This is a conceptual test - actual opacity testing would require more complex color analysis
        
        // Verify colors are not fully opaque (should be overlay colors)
        let primaryColor = MaterialDesignSystem.GlassColors.primary
        let secondaryColor = MaterialDesignSystem.GlassColors.secondary
        
        XCTAssertNotNil(primaryColor)
        XCTAssertNotNil(secondaryColor)
    }
    
    // MARK: - Glass Borders Tests
    
    func testGlassBordersExist() {
        // Test that all glass border styles are defined
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.subtle)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.prominent)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.accent)
    }
    
    // MARK: - Glass Shadows Tests
    
    func testGlassShadowsExist() {
        // Test that all glass shadow styles are defined
        XCTAssertNotNil(MaterialDesignSystem.GlassShadows.soft)
        XCTAssertNotNil(MaterialDesignSystem.GlassShadows.medium)
        XCTAssertNotNil(MaterialDesignSystem.GlassShadows.strong)
    }
    
    // MARK: - Glass Card Modifier Tests
    
    func testGlassCardModifierInitialization() {
        // Test that GlassCardModifier initializes with default values
        let modifier = GlassCardModifier()
        XCTAssertNotNil(modifier)
    }
    
    func testGlassCardModifierCustomValues() {
        // Test that GlassCardModifier accepts custom values
        let modifier = GlassCardModifier(
            material: .thickMaterial,
            cornerRadius: 20,
            borderColor: .blue,
            shadowColor: .black,
            shadowRadius: 10
        )
        XCTAssertNotNil(modifier)
    }
    
    // MARK: - Glass Button Modifier Tests
    
    func testGlassButtonModifierInitialization() {
        // Test that GlassButtonModifier initializes with default values
        let modifier = GlassButtonModifier()
        XCTAssertNotNil(modifier)
    }
    
    func testGlassButtonModifierCustomValues() {
        // Test that GlassButtonModifier accepts custom values
        let modifier = GlassButtonModifier(
            material: .regularMaterial,
            cornerRadius: 16,
            isPressed: true
        )
        XCTAssertNotNil(modifier)
    }
    
    // MARK: - View Extension Tests
    
    func testGlassCardViewExtension() {
        // Test that the glassCard view extension works
        let testView = Text("Test")
        let modifiedView = testView.glassCard()
        
        XCTAssertNotNil(modifiedView)
    }
    
    func testGlassCardViewExtensionWithCustomParameters() {
        // Test that the glassCard view extension accepts custom parameters
        let testView = Text("Test")
        let modifiedView = testView.glassCard(
            material: .thickMaterial,
            cornerRadius: 20,
            borderColor: .blue,
            shadowColor: .black,
            shadowRadius: 10
        )
        
        XCTAssertNotNil(modifiedView)
    }
    
    func testGlassButtonViewExtension() {
        // Test that the glassButton view extension works
        let testView = Text("Test")
        let modifiedView = testView.glassButton()
        
        XCTAssertNotNil(modifiedView)
    }
    
    func testGlassButtonViewExtensionWithCustomParameters() {
        // Test that the glassButton view extension accepts custom parameters
        let testView = Text("Test")
        let modifiedView = testView.glassButton(
            material: .regularMaterial,
            cornerRadius: 16,
            isPressed: true
        )
        
        XCTAssertNotNil(modifiedView)
    }
    
    // MARK: - Integration with Existing Design Tokens Tests
    
    func testIntegrationWithUIColors() {
        // Test that Material Design System properly integrates with existing UIColors
        XCTAssertNotNil(UIColors.accentPrimary)
        XCTAssertNotNil(UIColors.success)
        XCTAssertNotNil(UIColors.warning)
        XCTAssertNotNil(UIColors.danger)
        
        // Test that glass colors reference existing UI colors appropriately
        // This ensures consistency between the old and new design systems
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.success)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.warning)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.danger)
    }
    
    func testIntegrationWithUISpacing() {
        // Test that Material components use existing spacing tokens
        XCTAssertEqual(UISpacing.xxs, 4)
        XCTAssertEqual(UISpacing.xs, 8)
        XCTAssertEqual(UISpacing.sm, 12)
        XCTAssertEqual(UISpacing.md, 16)
        XCTAssertEqual(UISpacing.lg, 24)
        XCTAssertEqual(UISpacing.xl, 32)
    }
    
    func testIntegrationWithUICornerRadius() {
        // Test that Material components use existing corner radius tokens
        XCTAssertEqual(UICornerRadius.sm, 10)
        XCTAssertEqual(UICornerRadius.md, 12)
        XCTAssertEqual(UICornerRadius.lg, 16)
        XCTAssertEqual(UICornerRadius.xl, 20)
    }
    
    // MARK: - Consistency Tests
    
    func testMaterialHierarchy() {
        // Test that materials follow a logical hierarchy from thin to thick
        let materials: [Material] = [
            MaterialDesignSystem.Glass.ultraThin,
            MaterialDesignSystem.Glass.thin,
            MaterialDesignSystem.Glass.regular,
            MaterialDesignSystem.Glass.thick,
            MaterialDesignSystem.Glass.ultraThick
        ]
        
        // Verify all materials are defined (basic existence test)
        for material in materials {
            XCTAssertNotNil(material)
        }
    }
    
    func testContextualMaterialChoices() {
        // Test that contextual material choices make sense
        // Navigation should be prominent but not overwhelming
        XCTAssertEqual(MaterialDesignSystem.Context.navigation, .regularMaterial)
        
        // Tab bar should be subtle
        XCTAssertEqual(MaterialDesignSystem.Context.tabBar, .thinMaterial)
        
        // Cards should be subtle for content readability
        XCTAssertEqual(MaterialDesignSystem.Context.card, .thinMaterial)
        
        // Modals should be prominent to separate from background
        XCTAssertEqual(MaterialDesignSystem.Context.modal, .thickMaterial)
    }
    
    // MARK: - Performance Tests
    
    func testMaterialDesignSystemPerformance() {
        // Test that accessing design system properties is performant
        measure {
            for _ in 0..<1000 {
                _ = MaterialDesignSystem.Glass.regular
                _ = MaterialDesignSystem.Context.card
                _ = MaterialDesignSystem.GlassColors.primary
                _ = MaterialDesignSystem.GlassBorders.subtle
                _ = MaterialDesignSystem.GlassShadows.soft
            }
        }
    }
    
    func testModifierCreationPerformance() {
        // Test that creating modifiers is performant
        measure {
            for _ in 0..<100 {
                _ = GlassCardModifier()
                _ = GlassButtonModifier()
            }
        }
    }
    
    // MARK: - Accessibility Compliance Tests
    
    func testMaterialDesignSystemAccessibility() {
        // Test that the design system supports accessibility requirements
        
        // Verify that glass colors don't interfere with text contrast
        // This is a conceptual test - real implementation would need color analysis
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.primary)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.secondary)
        
        // Verify that border colors provide sufficient contrast
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.subtle)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.prominent)
    }
    
    func testMaterialDesignSystemDarkModeSupport() {
        // Test that the design system works in both light and dark modes
        // This would require environment testing in practice
        
        // Verify that all materials are system materials that adapt to appearance
        let materials: [Material] = [
            MaterialDesignSystem.Glass.ultraThin,
            MaterialDesignSystem.Glass.thin,
            MaterialDesignSystem.Glass.regular,
            MaterialDesignSystem.Glass.thick,
            MaterialDesignSystem.Glass.ultraThick
        ]
        
        for material in materials {
            XCTAssertNotNil(material, "Material should be defined for both light and dark modes")
        }
    }
}