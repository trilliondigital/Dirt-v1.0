import XCTest
import SwiftUI
@testable import Dirt

// MARK: - Navigation Coordinator Tests
class NavigationCoordinatorTests: XCTestCase {
    
    var coordinator: NavigationCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = NavigationCoordinator()
    }
    
    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }
    
    // MARK: - Tab Navigation Tests
    
    func testInitialTabSelection() {
        XCTAssertEqual(coordinator.selectedTab, .home, "Initial tab should be home")
    }
    
    func testTabNavigation() {
        // Test navigating to different tabs
        coordinator.navigateToTab(.search)
        XCTAssertEqual(coordinator.selectedTab, .search, "Should navigate to search tab")
        
        coordinator.navigateToTab(.notifications)
        XCTAssertEqual(coordinator.selectedTab, .notifications, "Should navigate to notifications tab")
        
        coordinator.navigateToTab(.profile)
        XCTAssertEqual(coordinator.selectedTab, .profile, "Should navigate to profile tab")
    }
    
    func testTabNavigationClearsNavigationPath() {
        // Add some navigation path
        coordinator.push(.settings)
        coordinator.push(.editProfile)
        XCTAssertFalse(coordinator.navigationPath.isEmpty, "Navigation path should not be empty")
        
        // Navigate to different tab
        coordinator.navigateToTab(.search)
        XCTAssertTrue(coordinator.navigationPath.isEmpty, "Navigation path should be cleared when switching tabs")
    }
    
    // MARK: - Navigation Stack Tests
    
    func testPushNavigation() {
        let initialCount = coordinator.navigationPath.count
        
        coordinator.push(.settings)
        XCTAssertEqual(coordinator.navigationPath.count, initialCount + 1, "Navigation path count should increase")
        
        coordinator.push(.editProfile)
        XCTAssertEqual(coordinator.navigationPath.count, initialCount + 2, "Navigation path count should increase again")
    }
    
    func testPopNavigation() {
        // Push some destinations
        coordinator.push(.settings)
        coordinator.push(.editProfile)
        let countAfterPush = coordinator.navigationPath.count
        
        // Pop one destination
        coordinator.pop()
        XCTAssertEqual(coordinator.navigationPath.count, countAfterPush - 1, "Navigation path count should decrease")
        
        // Pop another destination
        coordinator.pop()
        XCTAssertEqual(coordinator.navigationPath.count, countAfterPush - 2, "Navigation path count should decrease again")
    }
    
    func testPopToRoot() {
        // Push multiple destinations
        coordinator.push(.settings)
        coordinator.push(.editProfile)
        coordinator.push(.notifications)
        XCTAssertFalse(coordinator.navigationPath.isEmpty, "Navigation path should not be empty")
        
        // Pop to root
        coordinator.popToRoot()
        XCTAssertTrue(coordinator.navigationPath.isEmpty, "Navigation path should be empty after pop to root")
    }
    
    func testPopFromEmptyStack() {
        // Ensure navigation path is empty
        coordinator.popToRoot()
        XCTAssertTrue(coordinator.navigationPath.isEmpty, "Navigation path should be empty")
        
        // Try to pop from empty stack (should not crash)
        coordinator.pop()
        XCTAssertTrue(coordinator.navigationPath.isEmpty, "Navigation path should still be empty")
    }
    
    // MARK: - Modal Presentation Tests
    
    func testModalPresentation() {
        XCTAssertNil(coordinator.presentedModal, "Initially no modal should be presented")
        
        coordinator.presentModal(.createPost)
        XCTAssertNotNil(coordinator.presentedModal, "Modal should be presented")
        XCTAssertEqual(coordinator.presentedModal?.id, "createPost", "Correct modal should be presented")
    }
    
    func testModalDismissal() {
        coordinator.presentModal(.settings)
        XCTAssertNotNil(coordinator.presentedModal, "Modal should be presented")
        
        coordinator.dismissModal()
        XCTAssertNil(coordinator.presentedModal, "Modal should be dismissed")
    }
    
    // MARK: - Sheet Presentation Tests
    
    func testSheetPresentation() {
        XCTAssertNil(coordinator.presentedSheet, "Initially no sheet should be presented")
        
        coordinator.presentSheet(.filters)
        XCTAssertNotNil(coordinator.presentedSheet, "Sheet should be presented")
        XCTAssertEqual(coordinator.presentedSheet?.id, "filters", "Correct sheet should be presented")
    }
    
    func testSheetDismissal() {
        coordinator.presentSheet(.sortOptions)
        XCTAssertNotNil(coordinator.presentedSheet, "Sheet should be presented")
        
        coordinator.dismissSheet()
        XCTAssertNil(coordinator.presentedSheet, "Sheet should be dismissed")
    }
    
    // MARK: - Full Screen Cover Tests
    
    func testFullScreenCoverPresentation() {
        XCTAssertNil(coordinator.presentedFullScreenCover, "Initially no full screen cover should be presented")
        
        coordinator.presentFullScreenCover(.camera)
        XCTAssertNotNil(coordinator.presentedFullScreenCover, "Full screen cover should be presented")
        XCTAssertEqual(coordinator.presentedFullScreenCover?.id, "camera", "Correct full screen cover should be presented")
    }
    
    func testFullScreenCoverDismissal() {
        coordinator.presentFullScreenCover(.onboarding)
        XCTAssertNotNil(coordinator.presentedFullScreenCover, "Full screen cover should be presented")
        
        coordinator.dismissFullScreenCover()
        XCTAssertNil(coordinator.presentedFullScreenCover, "Full screen cover should be dismissed")
    }
    
    // MARK: - Alert Tests
    
    func testAlertPresentation() {
        XCTAssertNil(coordinator.presentedAlert, "Initially no alert should be presented")
        
        let alert = AlertDestination(
            title: "Test Alert",
            message: "This is a test alert",
            primaryButton: nil,
            secondaryButton: nil
        )
        
        coordinator.presentAlert(alert)
        XCTAssertNotNil(coordinator.presentedAlert, "Alert should be presented")
        XCTAssertEqual(coordinator.presentedAlert?.title, "Test Alert", "Correct alert should be presented")
    }
    
    func testAlertDismissal() {
        let alert = AlertDestination(
            title: "Test Alert",
            message: "This is a test alert",
            primaryButton: nil,
            secondaryButton: nil
        )
        
        coordinator.presentAlert(alert)
        XCTAssertNotNil(coordinator.presentedAlert, "Alert should be presented")
        
        coordinator.dismissAlert()
        XCTAssertNil(coordinator.presentedAlert, "Alert should be dismissed")
    }
    
    // MARK: - Toast Tests
    
    func testToastPresentation() {
        XCTAssertNil(coordinator.presentedToast, "Initially no toast should be presented")
        
        let toast = ToastDestination(message: "Test toast", type: .info)
        coordinator.showToast(toast)
        
        XCTAssertNotNil(coordinator.presentedToast, "Toast should be presented")
        XCTAssertEqual(coordinator.presentedToast?.message, "Test toast", "Correct toast should be presented")
    }
    
    func testToastDismissal() {
        let toast = ToastDestination(message: "Test toast", type: .info)
        coordinator.showToast(toast)
        XCTAssertNotNil(coordinator.presentedToast, "Toast should be presented")
        
        coordinator.dismissToast()
        XCTAssertNil(coordinator.presentedToast, "Toast should be dismissed")
    }
    
    func testToastAutoDismiss() {
        let expectation = XCTestExpectation(description: "Toast should auto-dismiss")
        
        let toast = ToastDestination(message: "Test toast", type: .info, duration: 0.1) // Short duration for test
        coordinator.showToast(toast)
        XCTAssertNotNil(coordinator.presentedToast, "Toast should be presented")
        
        // Wait for auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertNil(self.coordinator.presentedToast, "Toast should be auto-dismissed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Deep Link Tests
    
    func testDeepLinkToProfile() {
        let url = URL(string: "dirt://profile?id=user123")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .profile, "Should navigate to profile tab")
        // Note: In a real implementation, we would also check if the profile view is pushed with the correct user ID
    }
    
    func testDeepLinkToPost() {
        let url = URL(string: "dirt://post?id=post456")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .home, "Should navigate to home tab for post")
        // Note: In a real implementation, we would also check if the post detail view is pushed
    }
    
    func testDeepLinkToSearch() {
        let url = URL(string: "dirt://search?q=test%20query")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .search, "Should navigate to search tab")
        // Note: In a real implementation, we would also check if search results are shown
    }
    
    func testDeepLinkToCreate() {
        let url = URL(string: "dirt://create")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .create, "Should navigate to create tab")
    }
    
    func testDeepLinkToNotifications() {
        let url = URL(string: "dirt://notifications")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .notifications, "Should navigate to notifications tab")
    }
    
    func testInvalidDeepLink() {
        let url = URL(string: "dirt://invalid")!
        coordinator.handleDeepLink(url)
        
        XCTAssertEqual(coordinator.selectedTab, .home, "Should default to home tab for invalid deep links")
    }
    
    // MARK: - State Management Tests
    
    func testMultipleModalsPrevention() {
        coordinator.presentModal(.createPost)
        XCTAssertEqual(coordinator.presentedModal?.id, "createPost", "First modal should be presented")
        
        coordinator.presentModal(.settings)
        XCTAssertEqual(coordinator.presentedModal?.id, "settings", "Second modal should replace first")
    }
    
    func testMultipleSheetsPrevention() {
        coordinator.presentSheet(.filters)
        XCTAssertEqual(coordinator.presentedSheet?.id, "filters", "First sheet should be presented")
        
        coordinator.presentSheet(.sortOptions)
        XCTAssertEqual(coordinator.presentedSheet?.id, "sortOptions", "Second sheet should replace first")
    }
    
    func testConcurrentPresentations() {
        // Test that different presentation types can coexist
        coordinator.presentModal(.createPost)
        coordinator.presentSheet(.filters)
        let toast = ToastDestination(message: "Test", type: .info)
        coordinator.showToast(toast)
        
        XCTAssertNotNil(coordinator.presentedModal, "Modal should be presented")
        XCTAssertNotNil(coordinator.presentedSheet, "Sheet should be presented")
        XCTAssertNotNil(coordinator.presentedToast, "Toast should be presented")
    }
}

// MARK: - Main Tab Tests
class MainTabTests: XCTestCase {
    
    func testMainTabProperties() {
        // Test home tab
        XCTAssertEqual(MainTab.home.title, "Home")
        XCTAssertEqual(MainTab.home.systemImage, "house")
        XCTAssertEqual(MainTab.home.selectedSystemImage, "house.fill")
        
        // Test search tab
        XCTAssertEqual(MainTab.search.title, "Search")
        XCTAssertEqual(MainTab.search.systemImage, "magnifyingglass")
        XCTAssertEqual(MainTab.search.selectedSystemImage, "magnifyingglass")
        
        // Test create tab
        XCTAssertEqual(MainTab.create.title, "Create")
        XCTAssertEqual(MainTab.create.systemImage, "plus.circle")
        XCTAssertEqual(MainTab.create.selectedSystemImage, "plus.circle.fill")
        
        // Test notifications tab
        XCTAssertEqual(MainTab.notifications.title, "Notifications")
        XCTAssertEqual(MainTab.notifications.systemImage, "bell")
        XCTAssertEqual(MainTab.notifications.selectedSystemImage, "bell.fill")
        
        // Test profile tab
        XCTAssertEqual(MainTab.profile.title, "Profile")
        XCTAssertEqual(MainTab.profile.systemImage, "person.circle")
        XCTAssertEqual(MainTab.profile.selectedSystemImage, "person.circle.fill")
    }
    
    func testMainTabAllCases() {
        let allTabs = MainTab.allCases
        XCTAssertEqual(allTabs.count, 5, "Should have 5 main tabs")
        XCTAssertTrue(allTabs.contains(.home), "Should contain home tab")
        XCTAssertTrue(allTabs.contains(.search), "Should contain search tab")
        XCTAssertTrue(allTabs.contains(.create), "Should contain create tab")
        XCTAssertTrue(allTabs.contains(.notifications), "Should contain notifications tab")
        XCTAssertTrue(allTabs.contains(.profile), "Should contain profile tab")
    }
}

// MARK: - Navigation Destination Tests
class NavigationDestinationTests: XCTestCase {
    
    func testNavigationDestinationEquality() {
        let profile1 = NavigationDestination.profile(userId: "user123")
        let profile2 = NavigationDestination.profile(userId: "user123")
        let profile3 = NavigationDestination.profile(userId: "user456")
        
        XCTAssertEqual(profile1, profile2, "Same profile destinations should be equal")
        XCTAssertNotEqual(profile1, profile3, "Different profile destinations should not be equal")
        
        let post1 = NavigationDestination.postDetail(postId: "post123")
        let post2 = NavigationDestination.postDetail(postId: "post123")
        
        XCTAssertEqual(post1, post2, "Same post destinations should be equal")
        XCTAssertNotEqual(profile1, post1, "Different destination types should not be equal")
    }
    
    func testNavigationDestinationHashing() {
        let profile = NavigationDestination.profile(userId: "user123")
        let post = NavigationDestination.postDetail(postId: "post123")
        let settings = NavigationDestination.settings
        
        let destinations: Set<NavigationDestination> = [profile, post, settings]
        XCTAssertEqual(destinations.count, 3, "All destinations should be unique in set")
    }
}

// MARK: - Toast Destination Tests
class ToastDestinationTests: XCTestCase {
    
    func testToastDestinationInitialization() {
        let toast = ToastDestination(message: "Test message", type: .success)
        
        XCTAssertEqual(toast.message, "Test message")
        XCTAssertEqual(toast.type, .success)
        XCTAssertEqual(toast.duration, toast.type.defaultDuration)
        XCTAssertTrue(toast.isDismissible)
    }
    
    func testToastDestinationCustomDuration() {
        let toast = ToastDestination(message: "Test", type: .info, duration: 5.0)
        
        XCTAssertEqual(toast.duration, 5.0)
    }
    
    func testToastDestinationNonDismissible() {
        let toast = ToastDestination(message: "Test", isDismissible: false)
        
        XCTAssertFalse(toast.isDismissible)
    }
}

// MARK: - Alert Destination Tests
class AlertDestinationTests: XCTestCase {
    
    func testAlertDestinationInitialization() {
        let alert = AlertDestination(
            title: "Test Alert",
            message: "Test message",
            primaryButton: AlertDestination.AlertButton(
                title: "OK",
                style: .default,
                action: nil
            ),
            secondaryButton: AlertDestination.AlertButton(
                title: "Cancel",
                style: .cancel,
                action: nil
            )
        )
        
        XCTAssertEqual(alert.title, "Test Alert")
        XCTAssertEqual(alert.message, "Test message")
        XCTAssertNotNil(alert.primaryButton)
        XCTAssertNotNil(alert.secondaryButton)
        XCTAssertEqual(alert.primaryButton?.title, "OK")
        XCTAssertEqual(alert.secondaryButton?.title, "Cancel")
    }
    
    func testAlertButtonStyles() {
        let defaultButton = AlertDestination.AlertButton(title: "Default", style: .default, action: nil)
        let cancelButton = AlertDestination.AlertButton(title: "Cancel", style: .cancel, action: nil)
        let destructiveButton = AlertDestination.AlertButton(title: "Delete", style: .destructive, action: nil)
        
        XCTAssertEqual(defaultButton.style, .default)
        XCTAssertEqual(cancelButton.style, .cancel)
        XCTAssertEqual(destructiveButton.style, .destructive)
    }
}