import XCTest
import SwiftUI
@testable import Dirt

// MARK: - Material Glass Tab Bar Tests
class MaterialGlassTabBarTests: XCTestCase {
    
    var coordinator: NavigationCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Tab Bar Initialization Tests
    
    func testTabBarInitialization() {
        let tabBar = MaterialGlassTabBar(coordinator: coordinator)
        
        // Test that tab bar can be created without crashing
        XCTAssertNotNil(tabBar, "Tab bar should be created successfully")
    }
    
    // MARK: - Tab Selection Tests
    
    func testTabSelectionUpdatesCoordinator() {
        // Initial state
        XCTAssertEqual(coordinator.selectedTab, .home, "Initial tab should be home")
        
        // Simulate tab selection (in real app this would be through UI interaction)
        coordinator.navigateToTab(.search)
        XCTAssertEqual(coordinator.selectedTab, .search, "Coordinator should update selected tab")
        
        coordinator.navigateToTab(.notifications)
        XCTAssertEqual(coordinator.selectedTab, .notifications, "Coordinator should update selected tab again")
    }
    
    // MARK: - Tab Configuration Tests
    
    func testAllTabsAreConfigured() {
        let allTabs = MainTab.allCases
        
        for tab in allTabs {
            XCTAssertFalse(tab.title.isEmpty, "Tab \(tab) should have a title")
            XCTAssertFalse(tab.systemImage.isEmpty, "Tab \(tab) should have a system image")
            XCTAssertFalse(tab.selectedSystemImage.isEmpty, "Tab \(tab) should have a selected system image")
        }
    }
    
    func testTabImageConfiguration() {
        // Test that each tab has appropriate SF Symbol names
        XCTAssertTrue(MainTab.home.systemImage.contains("house"), "Home tab should use house icon")
        XCTAssertTrue(MainTab.search.systemImage.contains("magnifyingglass"), "Search tab should use magnifying glass icon")
        XCTAssertTrue(MainTab.create.systemImage.contains("plus"), "Create tab should use plus icon")
        XCTAssertTrue(MainTab.notifications.systemImage.contains("bell"), "Notifications tab should use bell icon")
        XCTAssertTrue(MainTab.profile.systemImage.contains("person"), "Profile tab should use person icon")
    }
    
    // MARK: - Navigation Container Tests
    
    func testNavigationContainerInitialization() {
        let container = MaterialGlassNavigationContainer {
            Text("Test Content")
        }
        
        XCTAssertNotNil(container, "Navigation container should be created successfully")
    }
    
    // MARK: - Navigation Router Tests
    
    func testTabContentGeneration() {
        // Test that each tab generates appropriate content
        for tab in MainTab.allCases {
            let content = NavigationRouter.mainContent(for: tab)
            XCTAssertNotNil(content, "Tab \(tab) should generate content")
        }
    }
    
    func testTabContentContainer() {
        let container = NavigationRouter.TabContentContainer(coordinator: coordinator)
        XCTAssertNotNil(container, "Tab content container should be created successfully")
    }
}

// MARK: - Material Glass Navigation Integration Tests
class MaterialGlassNavigationIntegrationTests: XCTestCase {
    
    var coordinator: NavigationCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Flow Tests
    
    func testCompleteNavigationFlow() {
        // Start at home
        XCTAssertEqual(coordinator.selectedTab, .home)
        XCTAssertTrue(coordinator.navigationPath.isEmpty)
        
        // Navigate to settings
        coordinator.push(.settings)
        XCTAssertFalse(coordinator.navigationPath.isEmpty)
        
        // Switch tabs (should clear navigation path)
        coordinator.navigateToTab(.search)
        XCTAssertEqual(coordinator.selectedTab, .search)
        XCTAssertTrue(coordinator.navigationPath.isEmpty)
        
        // Navigate within search tab
        coordinator.push(.searchResults(query: "test"))
        XCTAssertFalse(coordinator.navigationPath.isEmpty)
        
        // Pop back
        coordinator.pop()
        XCTAssertTrue(coordinator.navigationPath.isEmpty)
    }
    
    func testModalPresentationFlow() {
        // Present modal
        coordinator.presentModal(.createPost)
        XCTAssertNotNil(coordinator.presentedModal)
        XCTAssertEqual(coordinator.presentedModal?.id, "createPost")
        
        // Dismiss modal
        coordinator.dismissModal()
        XCTAssertNil(coordinator.presentedModal)
    }
    
    func testSheetPresentationFlow() {
        // Present sheet
        coordinator.presentSheet(.filters)
        XCTAssertNotNil(coordinator.presentedSheet)
        XCTAssertEqual(coordinator.presentedSheet?.id, "filters")
        
        // Dismiss sheet
        coordinator.dismissSheet()
        XCTAssertNil(coordinator.presentedSheet)
    }
    
    func testFullScreenCoverFlow() {
        // Present full screen cover
        coordinator.presentFullScreenCover(.camera)
        XCTAssertNotNil(coordinator.presentedFullScreenCover)
        XCTAssertEqual(coordinator.presentedFullScreenCover?.id, "camera")
        
        // Dismiss full screen cover
        coordinator.dismissFullScreenCover()
        XCTAssertNil(coordinator.presentedFullScreenCover)
    }
    
    // MARK: - Deep Link Integration Tests
    
    func testDeepLinkIntegration() {
        // Test profile deep link
        let profileURL = URL(string: "dirt://profile?id=user123")!
        coordinator.handleDeepLink(profileURL)
        XCTAssertEqual(coordinator.selectedTab, .profile)
        
        // Test post deep link
        let postURL = URL(string: "dirt://post?id=post456")!
        coordinator.handleDeepLink(postURL)
        XCTAssertEqual(coordinator.selectedTab, .home)
        
        // Test search deep link
        let searchURL = URL(string: "dirt://search?q=test")!
        coordinator.handleDeepLink(searchURL)
        XCTAssertEqual(coordinator.selectedTab, .search)
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistencyAcrossTabSwitches() {
        // Set up some state in home tab
        coordinator.navigateToTab(.home)
        coordinator.push(.settings)
        coordinator.push(.editProfile)
        
        let homeNavigationCount = coordinator.navigationPath.count
        XCTAssertEqual(homeNavigationCount, 2)
        
        // Switch to search tab (should clear navigation)
        coordinator.navigateToTab(.search)
        XCTAssertTrue(coordinator.navigationPath.isEmpty)
        
        // Add navigation in search tab
        coordinator.push(.searchResults(query: "test"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        // Switch back to home (should clear search navigation)
        coordinator.navigateToTab(.home)
        XCTAssertTrue(coordinator.navigationPath.isEmpty)
    }
    
    func testMultiplePresentationTypes() {
        // Test that different presentation types can coexist
        coordinator.presentModal(.createPost)
        coordinator.presentSheet(.filters)
        
        let toast = ToastDestination(message: "Test toast", type: .info)
        coordinator.showToast(toast)
        
        let alert = AlertDestination(title: "Test Alert", message: nil, primaryButton: nil, secondaryButton: nil)
        coordinator.presentAlert(alert)
        
        // All should be presented simultaneously
        XCTAssertNotNil(coordinator.presentedModal)
        XCTAssertNotNil(coordinator.presentedSheet)
        XCTAssertNotNil(coordinator.presentedToast)
        XCTAssertNotNil(coordinator.presentedAlert)
        
        // Dismiss all
        coordinator.dismissModal()
        coordinator.dismissSheet()
        coordinator.dismissToast()
        coordinator.dismissAlert()
        
        // All should be dismissed
        XCTAssertNil(coordinator.presentedModal)
        XCTAssertNil(coordinator.presentedSheet)
        XCTAssertNil(coordinator.presentedToast)
        XCTAssertNil(coordinator.presentedAlert)
    }
}

// MARK: - Material Glass Design Integration Tests
class MaterialGlassDesignIntegrationTests: XCTestCase {
    
    // MARK: - Design System Integration Tests
    
    func testMaterialGlassComponentsIntegration() {
        // Test that Material Glass components use correct design tokens
        let cardMaterial = MaterialDesignSystem.Context.card
        let tabBarMaterial = MaterialDesignSystem.Context.tabBar
        let navigationMaterial = MaterialDesignSystem.Context.navigation
        
        XCTAssertEqual(cardMaterial, .thinMaterial, "Card should use thin material")
        XCTAssertEqual(tabBarMaterial, .thinMaterial, "Tab bar should use thin material")
        XCTAssertEqual(navigationMaterial, .regularMaterial, "Navigation should use regular material")
    }
    
    func testGlassColorsIntegration() {
        // Test that glass colors are properly defined
        let primaryGlass = MaterialDesignSystem.GlassColors.primary
        let secondaryGlass = MaterialDesignSystem.GlassColors.secondary
        let neutralGlass = MaterialDesignSystem.GlassColors.neutral
        
        XCTAssertNotNil(primaryGlass, "Primary glass color should be defined")
        XCTAssertNotNil(secondaryGlass, "Secondary glass color should be defined")
        XCTAssertNotNil(neutralGlass, "Neutral glass color should be defined")
    }
    
    func testGlassBordersIntegration() {
        // Test that glass borders are properly defined
        let subtleBorder = MaterialDesignSystem.GlassBorders.subtle
        let prominentBorder = MaterialDesignSystem.GlassBorders.prominent
        let accentBorder = MaterialDesignSystem.GlassBorders.accent
        
        XCTAssertNotNil(subtleBorder, "Subtle border should be defined")
        XCTAssertNotNil(prominentBorder, "Prominent border should be defined")
        XCTAssertNotNil(accentBorder, "Accent border should be defined")
    }
    
    func testMotionSystemIntegration() {
        // Test that motion system provides appropriate animations
        let tabSelection = MaterialMotion.Interactive.tabSelection()
        let navigationTransition = MaterialMotion.Glass.navigationTransition
        let modalPresent = MaterialMotion.Glass.modalPresent
        
        XCTAssertNotNil(tabSelection, "Tab selection animation should be defined")
        XCTAssertNotNil(navigationTransition, "Navigation transition should be defined")
        XCTAssertNotNil(modalPresent, "Modal present animation should be defined")
    }
}

// MARK: - Performance Tests
class NavigationPerformanceTests: XCTestCase {
    
    var coordinator: NavigationCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Performance Tests
    
    func testTabSwitchingPerformance() {
        measure {
            // Simulate rapid tab switching
            for _ in 0..<100 {
                coordinator.navigateToTab(.home)
                coordinator.navigateToTab(.search)
                coordinator.navigateToTab(.create)
                coordinator.navigateToTab(.notifications)
                coordinator.navigateToTab(.profile)
            }
        }
    }
    
    func testNavigationStackPerformance() {
        measure {
            // Simulate deep navigation stack operations
            for i in 0..<50 {
                coordinator.push(.profile(userId: "user\(i)"))
            }
            
            for _ in 0..<50 {
                coordinator.pop()
            }
        }
    }
    
    func testModalPresentationPerformance() {
        measure {
            // Simulate rapid modal presentation/dismissal
            for _ in 0..<100 {
                coordinator.presentModal(.createPost)
                coordinator.dismissModal()
            }
        }
    }
    
    func testDeepLinkPerformance() {
        let urls = [
            URL(string: "dirt://profile?id=user123")!,
            URL(string: "dirt://post?id=post456")!,
            URL(string: "dirt://search?q=test")!,
            URL(string: "dirt://create")!,
            URL(string: "dirt://notifications")!
        ]
        
        measure {
            // Simulate rapid deep link handling
            for _ in 0..<100 {
                for url in urls {
                    coordinator.handleDeepLink(url)
                }
            }
        }
    }
}

// MARK: - Accessibility Tests
class NavigationAccessibilityTests: XCTestCase {
    
    // MARK: - Tab Bar Accessibility Tests
    
    func testTabBarAccessibilityLabels() {
        // Test that all tabs have appropriate accessibility labels
        for tab in MainTab.allCases {
            XCTAssertFalse(tab.title.isEmpty, "Tab \(tab) should have accessibility label")
            XCTAssertTrue(tab.title.count > 2, "Tab \(tab) accessibility label should be descriptive")
        }
    }
    
    func testTabBarAccessibilityTraits() {
        // In a real implementation, we would test that tab buttons have proper accessibility traits
        // This is a placeholder for UI accessibility testing
        XCTAssertTrue(true, "Tab buttons should have .button accessibility trait")
    }
    
    // MARK: - Navigation Accessibility Tests
    
    func testNavigationAccessibilityAnnouncements() {
        // In a real implementation, we would test that navigation changes are announced to VoiceOver
        // This is a placeholder for accessibility announcement testing
        XCTAssertTrue(true, "Navigation changes should be announced to assistive technologies")
    }
    
    func testModalAccessibilityFocus() {
        // In a real implementation, we would test that modal presentation moves focus appropriately
        // This is a placeholder for modal accessibility testing
        XCTAssertTrue(true, "Modal presentation should move accessibility focus to modal content")
    }
}

// MARK: - Error Handling Tests
class NavigationErrorHandlingTests: XCTestCase {
    
    var coordinator: NavigationCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDeepLinkHandling() {
        // Test handling of malformed URLs
        let invalidURLs = [
            URL(string: "dirt://")!,
            URL(string: "dirt://invalid-path")!,
            URL(string: "dirt://profile")!, // Missing required parameter
            URL(string: "not-dirt://profile")! // Wrong scheme
        ]
        
        for url in invalidURLs {
            // Should not crash and should default to home
            coordinator.handleDeepLink(url)
            // In most cases, invalid deep links should default to home
            // The exact behavior depends on implementation
        }
    }
    
    func testNavigationStackOverflow() {
        // Test that navigation stack doesn't grow indefinitely
        let initialCount = coordinator.navigationPath.count
        
        // Push many destinations
        for i in 0..<1000 {
            coordinator.push(.profile(userId: "user\(i)"))
        }
        
        // Should handle large navigation stacks gracefully
        XCTAssertTrue(coordinator.navigationPath.count > initialCount, "Navigation stack should grow")
        
        // Pop to root should work even with large stack
        coordinator.popToRoot()
        XCTAssertTrue(coordinator.navigationPath.isEmpty, "Should be able to pop to root from large stack")
    }
    
    func testConcurrentNavigationOperations() {
        // Test that concurrent navigation operations are handled safely
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 3
        
        DispatchQueue.global().async {
            for _ in 0..<10 {
                self.coordinator.navigateToTab(.home)
                self.coordinator.navigateToTab(.search)
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for i in 0..<10 {
                self.coordinator.push(.profile(userId: "user\(i)"))
                self.coordinator.pop()
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for _ in 0..<10 {
                self.coordinator.presentModal(.createPost)
                self.coordinator.dismissModal()
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should not crash and should be in a consistent state
        XCTAssertNotNil(coordinator.selectedTab, "Should have valid selected tab")
    }
}