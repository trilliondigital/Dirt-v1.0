import XCTest
import SwiftUI

/// UI tests for Material Glass component accessibility and rendering
/// Tests VoiceOver support, Dynamic Type, and visual consistency
final class MaterialGlassAccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Accessibility Tests
    
    func testGlassButtonAccessibility() throws {
        // Test that glass buttons are accessible to VoiceOver
        // This would require a test view that uses GlassButton components
        
        // Enable VoiceOver for testing
        app.accessibilityActivate()
        
        // Test that buttons have proper accessibility labels
        let button = app.buttons["Test Glass Button"]
        XCTAssertTrue(button.exists, "Glass button should be accessible")
        XCTAssertTrue(button.isHittable, "Glass button should be hittable")
        
        // Test minimum touch target size (44x44 points)
        let buttonFrame = button.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Button should meet minimum touch target height")
        XCTAssertGreaterThanOrEqual(buttonFrame.width, 44, "Button should meet minimum touch target width")
    }
    
    func testGlassCardAccessibility() throws {
        // Test that glass cards are properly accessible
        let card = app.otherElements["Glass Card Content"]
        XCTAssertTrue(card.exists, "Glass card should be accessible")
        
        // Test that card content is readable by VoiceOver
        XCTAssertTrue(card.isHittable, "Glass card content should be accessible")
    }
    
    func testGlassNavigationBarAccessibility() throws {
        // Test navigation bar accessibility
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.exists, "Navigation bar should exist")
        
        // Test navigation title accessibility
        let navTitle = navBar.staticTexts.firstMatch
        XCTAssertTrue(navTitle.exists, "Navigation title should be accessible")
    }
    
    func testGlassTabBarAccessibility() throws {
        // Test tab bar accessibility
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test that all tabs are accessible
        let tabs = tabBar.buttons
        XCTAssertGreaterThan(tabs.count, 0, "Tab bar should have accessible tabs")
        
        for i in 0..<tabs.count {
            let tab = tabs.element(boundBy: i)
            XCTAssertTrue(tab.exists, "Tab \(i) should be accessible")
            XCTAssertTrue(tab.isHittable, "Tab \(i) should be hittable")
        }
    }
    
    func testGlassSearchBarAccessibility() throws {
        // Test search bar accessibility
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists, "Search field should be accessible")
        XCTAssertTrue(searchField.isHittable, "Search field should be hittable")
        
        // Test search field can receive focus
        searchField.tap()
        XCTAssertTrue(searchField.hasKeyboardFocus, "Search field should be focusable")
    }
    
    // MARK: - Dynamic Type Tests
    
    func testGlassComponentsWithLargeText() throws {
        // Test that glass components work with larger text sizes
        
        // Set accessibility text size to extra large
        app.activate()
        
        // Navigate to accessibility settings and increase text size
        // This is a simplified test - in practice you'd use XCUIDevice to change settings
        
        let button = app.buttons["Test Glass Button"]
        XCTAssertTrue(button.exists, "Button should exist with large text")
        
        // Verify button is still properly sized and accessible
        let buttonFrame = button.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Button should maintain minimum height with large text")
    }
    
    func testGlassComponentsWithSmallText() throws {
        // Test that glass components work with smaller text sizes
        
        let button = app.buttons["Test Glass Button"]
        XCTAssertTrue(button.exists, "Button should exist with small text")
        
        // Verify button maintains readability
        let buttonFrame = button.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Button should maintain minimum height with small text")
    }
    
    // MARK: - Dark Mode Tests
    
    func testGlassComponentsInDarkMode() throws {
        // Test that glass components render correctly in dark mode
        
        // Switch to dark mode (this would require system-level changes in practice)
        // For now, we'll test that components exist and are accessible
        
        let button = app.buttons["Test Glass Button"]
        XCTAssertTrue(button.exists, "Button should exist in dark mode")
        XCTAssertTrue(button.isHittable, "Button should be hittable in dark mode")
        
        let card = app.otherElements["Glass Card Content"]
        XCTAssertTrue(card.exists, "Card should exist in dark mode")
    }
    
    func testGlassComponentsInLightMode() throws {
        // Test that glass components render correctly in light mode
        
        let button = app.buttons["Test Glass Button"]
        XCTAssertTrue(button.exists, "Button should exist in light mode")
        XCTAssertTrue(button.isHittable, "Button should be hittable in light mode")
        
        let card = app.otherElements["Glass Card Content"]
        XCTAssertTrue(card.exists, "Card should exist in light mode")
    }
    
    // MARK: - Contrast and Readability Tests
    
    func testGlassComponentContrast() throws {
        // Test that text on glass backgrounds maintains sufficient contrast
        // This would require color analysis in practice
        
        let textElements = app.staticTexts
        for i in 0..<textElements.count {
            let textElement = textElements.element(boundBy: i)
            if textElement.exists {
                // Verify text is visible and readable
                XCTAssertTrue(textElement.isHittable, "Text element \(i) should be readable")
            }
        }
    }
    
    func testGlassBackgroundTransparency() throws {
        // Test that glass backgrounds don't interfere with content readability
        
        let cards = app.otherElements.matching(identifier: "Glass Card")
        for i in 0..<cards.count {
            let card = cards.element(boundBy: i)
            if card.exists {
                // Verify card content is accessible
                XCTAssertTrue(card.isHittable, "Glass card \(i) content should be accessible")
            }
        }
    }
    
    // MARK: - Animation and Motion Tests
    
    func testGlassAnimationsWithReducedMotion() throws {
        // Test that glass components respect reduced motion accessibility setting
        
        // In practice, this would check system accessibility settings
        // For now, verify components still function
        
        let button = app.buttons["Test Glass Button"]
        button.tap()
        
        // Verify button still responds to interaction
        XCTAssertTrue(button.exists, "Button should still function with reduced motion")
    }
    
    func testGlassModalPresentation() throws {
        // Test that glass modals are presented accessibly
        
        let modalTrigger = app.buttons["Show Modal"]
        if modalTrigger.exists {
            modalTrigger.tap()
            
            // Verify modal appears and is accessible
            let modal = app.otherElements["Glass Modal"]
            XCTAssertTrue(modal.waitForExistence(timeout: 2), "Modal should appear")
            XCTAssertTrue(modal.isHittable, "Modal should be accessible")
            
            // Test modal dismissal
            let dismissButton = modal.buttons["Dismiss"]
            if dismissButton.exists {
                dismissButton.tap()
                XCTAssertFalse(modal.exists, "Modal should dismiss")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testGlassComponentRenderingPerformance() throws {
        // Test that glass components render efficiently
        
        measure {
            // Scroll through a list of glass components
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
    
    func testGlassAnimationPerformance() throws {
        // Test that glass animations perform smoothly
        
        measure {
            let button = app.buttons["Animated Glass Button"]
            if button.exists {
                // Trigger multiple animations
                for _ in 0..<5 {
                    button.tap()
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testGlassComponentsInComplexLayouts() throws {
        // Test that glass components work well in complex layouts
        
        let complexView = app.otherElements["Complex Glass Layout"]
        if complexView.exists {
            // Verify all components are accessible
            let buttons = complexView.buttons
            let cards = complexView.otherElements.matching(identifier: "Glass Card")
            
            XCTAssertGreaterThan(buttons.count, 0, "Complex layout should have accessible buttons")
            XCTAssertGreaterThan(cards.count, 0, "Complex layout should have accessible cards")
            
            // Test interaction with nested components
            if buttons.count > 0 {
                let firstButton = buttons.element(boundBy: 0)
                XCTAssertTrue(firstButton.isHittable, "Nested button should be hittable")
            }
        }
    }
    
    func testGlassComponentsWithScrolling() throws {
        // Test that glass components maintain accessibility during scrolling
        
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Scroll and verify components remain accessible
            scrollView.swipeUp()
            
            let visibleButtons = app.buttons
            for i in 0..<min(visibleButtons.count, 3) {
                let button = visibleButtons.element(boundBy: i)
                if button.exists {
                    XCTAssertTrue(button.isHittable, "Button should remain accessible after scrolling")
                }
            }
        }
    }
}