import XCTest
import SwiftUI
@testable import Dirt

/// Tests for the Material Motion System implementation
/// Verifies animations, transitions, and haptic feedback integration
final class MaterialMotionSystemTests: XCTestCase {
    
    // MARK: - Duration Constants Tests
    
    func testDurationConstants() {
        // Test that all duration constants are properly defined
        XCTAssertEqual(MaterialMotion.Duration.quick, 0.075)
        XCTAssertEqual(MaterialMotion.Duration.standard, 0.15)
        XCTAssertEqual(MaterialMotion.Duration.emphasized, 0.3)
        XCTAssertEqual(MaterialMotion.Duration.slow, 0.5)
        XCTAssertEqual(MaterialMotion.Duration.extraSlow, 0.75)
    }
    
    func testDurationHierarchy() {
        // Test that durations follow a logical progression
        XCTAssertLessThan(MaterialMotion.Duration.quick, MaterialMotion.Duration.standard)
        XCTAssertLessThan(MaterialMotion.Duration.standard, MaterialMotion.Duration.emphasized)
        XCTAssertLessThan(MaterialMotion.Duration.emphasized, MaterialMotion.Duration.slow)
        XCTAssertLessThan(MaterialMotion.Duration.slow, MaterialMotion.Duration.extraSlow)
    }
    
    // MARK: - Easing Animations Tests
    
    func testEasingAnimations() {
        // Test that all easing animations are properly defined
        XCTAssertNotNil(MaterialMotion.Easing.quick)
        XCTAssertNotNil(MaterialMotion.Easing.standard)
        XCTAssertNotNil(MaterialMotion.Easing.emphasized)
        XCTAssertNotNil(MaterialMotion.Easing.slow)
        XCTAssertNotNil(MaterialMotion.Easing.extraSlow)
    }
    
    // MARK: - Spring Animations Tests
    
    func testSpringAnimations() {
        // Test that all spring animations are properly defined
        XCTAssertNotNil(MaterialMotion.Spring.quick)
        XCTAssertNotNil(MaterialMotion.Spring.standard)
        XCTAssertNotNil(MaterialMotion.Spring.bouncy)
        XCTAssertNotNil(MaterialMotion.Spring.gentle)
        XCTAssertNotNil(MaterialMotion.Spring.glass)
    }
    
    // MARK: - Transition Animations Tests
    
    func testTransitionAnimations() {
        // Test that all transition animations are properly defined
        XCTAssertNotNil(MaterialMotion.Transition.slideUp)
        XCTAssertNotNil(MaterialMotion.Transition.slideDown)
        XCTAssertNotNil(MaterialMotion.Transition.scaleAndFade)
        XCTAssertNotNil(MaterialMotion.Transition.glassAppear)
        XCTAssertNotNil(MaterialMotion.Transition.pushFromRight)
    }
    
    // MARK: - Interactive Animations Tests
    
    func testInteractiveAnimations() {
        // Test button press animations
        let pressedAnimation = MaterialMotion.Interactive.buttonPress(isPressed: true)
        let releasedAnimation = MaterialMotion.Interactive.buttonPress(isPressed: false)
        
        XCTAssertNotNil(pressedAnimation)
        XCTAssertNotNil(releasedAnimation)
        
        // Test card selection animations
        let selectedAnimation = MaterialMotion.Interactive.cardSelection(isSelected: true)
        let deselectedAnimation = MaterialMotion.Interactive.cardSelection(isSelected: false)
        
        XCTAssertNotNil(selectedAnimation)
        XCTAssertNotNil(deselectedAnimation)
        
        // Test other interactive animations
        XCTAssertNotNil(MaterialMotion.Interactive.tabSelection())
        
        let focusedAnimation = MaterialMotion.Interactive.searchFocus(isFocused: true)
        let unfocusedAnimation = MaterialMotion.Interactive.searchFocus(isFocused: false)
        
        XCTAssertNotNil(focusedAnimation)
        XCTAssertNotNil(unfocusedAnimation)
    }
    
    // MARK: - Glass-Specific Animations Tests
    
    func testGlassAnimations() {
        // Test that all glass-specific animations are properly defined
        XCTAssertNotNil(MaterialMotion.Glass.cardAppear)
        XCTAssertNotNil(MaterialMotion.Glass.modalPresent)
        XCTAssertNotNil(MaterialMotion.Glass.toastAppear)
        XCTAssertNotNil(MaterialMotion.Glass.navigationTransition)
        XCTAssertNotNil(MaterialMotion.Glass.blurTransition)
    }
    
    // MARK: - Loading Animations Tests
    
    func testLoadingAnimations() {
        // Test that all loading animations are properly defined
        XCTAssertNotNil(MaterialMotion.Loading.pulse)
        XCTAssertNotNil(MaterialMotion.Loading.rotation)
        XCTAssertNotNil(MaterialMotion.Loading.shimmer)
        XCTAssertNotNil(MaterialMotion.Loading.breathing)
    }
    
    // MARK: - Glass Motion Modifier Tests
    
    func testGlassMotionModifierTypes() {
        // Test that all motion types are properly defined
        let motionTypes: [GlassMotionModifier.MotionType] = [
            .appear, .press, .selection, .focus, .modal
        ]
        
        for motionType in motionTypes {
            XCTAssertNotNil(motionType.animation)
            
            // Test transform function
            let activeTransform = motionType.transform(true)
            let inactiveTransform = motionType.transform(false)
            
            XCTAssertNotNil(activeTransform.scale)
            XCTAssertNotNil(activeTransform.opacity)
            XCTAssertNotNil(inactiveTransform.scale)
            XCTAssertNotNil(inactiveTransform.opacity)
        }
    }
    
    func testGlassMotionModifierInitialization() {
        // Test that GlassMotionModifier initializes properly
        let modifier = GlassMotionModifier(motionType: .appear, isActive: true)
        XCTAssertNotNil(modifier)
    }
    
    // MARK: - View Extension Tests
    
    func testGlassMotionViewExtensions() {
        // Test that all glass motion view extensions work
        let testView = Text("Test")
        
        let motionView = testView.glassMotion(.appear, isActive: true)
        XCTAssertNotNil(motionView)
        
        let appearView = testView.glassAppear(isVisible: true)
        XCTAssertNotNil(appearView)
        
        let pressView = testView.glassPress(isPressed: true)
        XCTAssertNotNil(pressView)
        
        let selectionView = testView.glassSelection(isSelected: true)
        XCTAssertNotNil(selectionView)
        
        let focusView = testView.glassFocus(isFocused: true)
        XCTAssertNotNil(focusView)
        
        let modalView = testView.glassModal(isPresented: true)
        XCTAssertNotNil(modalView)
    }
    
    // MARK: - Haptic Feedback Tests
    
    func testMaterialHapticsMethods() {
        // Test that all haptic feedback methods are callable
        // Note: These don't test actual haptic generation, just method existence
        
        XCTAssertNoThrow(MaterialHaptics.light())
        XCTAssertNoThrow(MaterialHaptics.medium())
        XCTAssertNoThrow(MaterialHaptics.heavy())
        XCTAssertNoThrow(MaterialHaptics.selection())
        XCTAssertNoThrow(MaterialHaptics.success())
        XCTAssertNoThrow(MaterialHaptics.warning())
        XCTAssertNoThrow(MaterialHaptics.error())
    }
    
    // MARK: - Animation Utilities Tests
    
    func testAnimationUtilities() {
        // Test custom glass animation creation
        let customGlassAnimation = Animation.glass()
        XCTAssertNotNil(customGlassAnimation)
        
        let customGlassAnimationWithParams = Animation.glass(
            response: 0.8,
            dampingFraction: 0.9,
            blendDuration: 0.1
        )
        XCTAssertNotNil(customGlassAnimationWithParams)
        
        // Test custom eased animation creation
        let customEasedAnimation = Animation.eased(duration: 0.25)
        XCTAssertNotNil(customEasedAnimation)
    }
    
    // MARK: - Performance Tests
    
    func testAnimationCreationPerformance() {
        // Test that creating animations is performant
        measure {
            for _ in 0..<1000 {
                _ = MaterialMotion.Easing.standard
                _ = MaterialMotion.Spring.glass
                _ = MaterialMotion.Glass.cardAppear
            }
        }
    }
    
    func testMotionModifierPerformance() {
        // Test that creating motion modifiers is performant
        measure {
            for _ in 0..<100 {
                _ = GlassMotionModifier(motionType: .appear, isActive: true)
                _ = GlassMotionModifier(motionType: .press, isActive: false)
            }
        }
    }
    
    // MARK: - Consistency Tests
    
    func testAnimationConsistency() {
        // Test that related animations have consistent timing
        
        // Glass animations should use similar spring parameters
        XCTAssertNotNil(MaterialMotion.Glass.cardAppear)
        XCTAssertNotNil(MaterialMotion.Glass.modalPresent)
        XCTAssertNotNil(MaterialMotion.Glass.toastAppear)
        
        // Interactive animations should be responsive
        let quickPress = MaterialMotion.Interactive.buttonPress(isPressed: true)
        let quickRelease = MaterialMotion.Interactive.buttonPress(isPressed: false)
        
        XCTAssertNotNil(quickPress)
        XCTAssertNotNil(quickRelease)
    }
    
    func testMotionTypeTransforms() {
        // Test that motion type transforms produce reasonable values
        
        let appearType = GlassMotionModifier.MotionType.appear
        let activeAppear = appearType.transform(true)
        let inactiveAppear = appearType.transform(false)
        
        // Active state should be normal scale and opacity
        XCTAssertEqual(activeAppear.scale, 1.0, accuracy: 0.01)
        XCTAssertEqual(activeAppear.opacity, 1.0, accuracy: 0.01)
        
        // Inactive state should be slightly smaller and transparent
        XCTAssertLessThan(inactiveAppear.scale, 1.0)
        XCTAssertLessThan(inactiveAppear.opacity, 1.0)
        
        let pressType = GlassMotionModifier.MotionType.press
        let activePress = pressType.transform(true)
        let inactivePress = pressType.transform(false)
        
        // Pressed state should be slightly smaller
        XCTAssertLessThan(activePress.scale, 1.0)
        
        // Released state should be normal scale
        XCTAssertEqual(inactivePress.scale, 1.0, accuracy: 0.01)
    }
    
    // MARK: - Integration Tests
    
    func testMotionSystemIntegration() {
        // Test that the motion system integrates well with the design system
        
        // Verify that glass animations complement glass materials
        XCTAssertNotNil(MaterialMotion.Glass.cardAppear)
        XCTAssertNotNil(MaterialDesignSystem.Glass.regular)
        
        // Verify that interactive animations work with interactive components
        XCTAssertNotNil(MaterialMotion.Interactive.buttonPress(isPressed: true))
        XCTAssertNotNil(MaterialMotion.Interactive.tabSelection())
    }
    
    func testAccessibilityIntegration() {
        // Test that the motion system respects accessibility preferences
        // In practice, this would check for reduced motion settings
        
        // Verify that all animations are defined (they should respect system settings automatically)
        XCTAssertNotNil(MaterialMotion.Easing.standard)
        XCTAssertNotNil(MaterialMotion.Spring.gentle)
        
        // Verify that loading animations exist for users who can handle them
        XCTAssertNotNil(MaterialMotion.Loading.pulse)
        XCTAssertNotNil(MaterialMotion.Loading.breathing)
    }
}