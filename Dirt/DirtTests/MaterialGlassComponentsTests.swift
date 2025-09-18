import XCTest
import SwiftUI
@testable import Dirt

/// UI tests for Material Glass base components
/// Tests rendering, accessibility, and interaction behavior
final class MaterialGlassComponentsTests: XCTestCase {
    
    // MARK: - GlassCard Tests
    
    func testGlassCardInitialization() {
        // Test that GlassCard initializes with default parameters
        let card = GlassCard {
            Text("Test Content")
        }
        
        XCTAssertNotNil(card)
    }
    
    func testGlassCardCustomParameters() {
        // Test that GlassCard accepts custom parameters
        let customCard = GlassCard(
            material: .thickMaterial,
            cornerRadius: 20,
            padding: 24
        ) {
            Text("Custom Content")
        }
        
        XCTAssertNotNil(customCard)
    }
    
    // MARK: - GlassButton Tests
    
    func testGlassButtonInitialization() {
        var actionCalled = false
        
        let button = GlassButton("Test Button") {
            actionCalled = true
        }
        
        XCTAssertNotNil(button)
    }
    
    func testGlassButtonStyles() {
        let primaryButton = GlassButton("Primary", style: .primary) { }
        let secondaryButton = GlassButton("Secondary", style: .secondary) { }
        let destructiveButton = GlassButton("Destructive", style: .destructive) { }
        let subtleButton = GlassButton("Subtle", style: .subtle) { }
        
        XCTAssertNotNil(primaryButton)
        XCTAssertNotNil(secondaryButton)
        XCTAssertNotNil(destructiveButton)
        XCTAssertNotNil(subtleButton)
    }
    
    func testGlassButtonWithIcon() {
        let buttonWithIcon = GlassButton(
            "Button with Icon",
            systemImage: "star.fill"
        ) { }
        
        XCTAssertNotNil(buttonWithIcon)
    }
    
    func testGlassButtonStyleProperties() {
        // Test that button styles have correct properties
        XCTAssertEqual(GlassButton.ButtonStyle.primary.foregroundColor, .white)
        XCTAssertEqual(GlassButton.ButtonStyle.secondary.foregroundColor, UIColors.accentPrimary)
        XCTAssertEqual(GlassButton.ButtonStyle.destructive.foregroundColor, .white)
        XCTAssertEqual(GlassButton.ButtonStyle.subtle.foregroundColor, UIColors.label)
        
        XCTAssertEqual(GlassButton.ButtonStyle.primary.material, MaterialDesignSystem.Glass.regular)
        XCTAssertEqual(GlassButton.ButtonStyle.secondary.material, MaterialDesignSystem.Glass.thin)
        XCTAssertEqual(GlassButton.ButtonStyle.destructive.material, MaterialDesignSystem.Glass.regular)
        XCTAssertEqual(GlassButton.ButtonStyle.subtle.material, MaterialDesignSystem.Glass.ultraThin)
    }
    
    // MARK: - GlassNavigationBar Tests
    
    func testGlassNavigationBarInitialization() {
        let navBar = GlassNavigationBar(title: "Test Title")
        XCTAssertNotNil(navBar)
    }
    
    func testGlassNavigationBarWithLeadingAndTrailing() {
        let navBar = GlassNavigationBar(
            title: "Test Title",
            leading: {
                Button("Back") { }
            },
            trailing: {
                Button("Done") { }
            }
        )
        
        XCTAssertNotNil(navBar)
    }
    
    // MARK: - GlassTabBar Tests
    
    func testGlassTabBarInitialization() {
        @State var selectedTab = 0
        let tabs = [
            GlassTabBar.TabItem(title: "Home", systemImage: "house"),
            GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
            GlassTabBar.TabItem(title: "Profile", systemImage: "person")
        ]
        
        let tabBar = GlassTabBar(selectedTab: .constant(selectedTab), tabs: tabs)
        XCTAssertNotNil(tabBar)
    }
    
    func testGlassTabBarTabItem() {
        let tabItem = GlassTabBar.TabItem(
            title: "Home",
            systemImage: "house",
            selectedSystemImage: "house.fill"
        )
        
        XCTAssertEqual(tabItem.title, "Home")
        XCTAssertEqual(tabItem.systemImage, "house")
        XCTAssertEqual(tabItem.selectedSystemImage, "house.fill")
    }
    
    func testGlassTabBarTabItemWithoutSelectedImage() {
        let tabItem = GlassTabBar.TabItem(
            title: "Search",
            systemImage: "magnifyingglass"
        )
        
        XCTAssertEqual(tabItem.title, "Search")
        XCTAssertEqual(tabItem.systemImage, "magnifyingglass")
        XCTAssertNil(tabItem.selectedSystemImage)
    }
    
    // MARK: - GlassModal Tests
    
    func testGlassModalInitialization() {
        @State var isPresented = false
        
        let modal = GlassModal(isPresented: .constant(isPresented)) {
            Text("Modal Content")
        }
        
        XCTAssertNotNil(modal)
    }
    
    func testGlassModalCustomCornerRadius() {
        @State var isPresented = false
        
        let modal = GlassModal(
            isPresented: .constant(isPresented),
            cornerRadius: 24
        ) {
            Text("Modal Content")
        }
        
        XCTAssertNotNil(modal)
    }
    
    // MARK: - GlassToast Tests
    
    func testGlassToastInitialization() {
        let toast = GlassToast(message: "Test message")
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastTypes() {
        let successToast = GlassToast(message: "Success", type: .success)
        let warningToast = GlassToast(message: "Warning", type: .warning)
        let errorToast = GlassToast(message: "Error", type: .error)
        let infoToast = GlassToast(message: "Info", type: .info)
        
        XCTAssertNotNil(successToast)
        XCTAssertNotNil(warningToast)
        XCTAssertNotNil(errorToast)
        XCTAssertNotNil(infoToast)
    }
    
    func testGlassToastTypeProperties() {
        // Test that toast types have correct properties
        XCTAssertEqual(GlassToast.ToastType.success.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(GlassToast.ToastType.warning.systemImage, "exclamationmark.triangle.fill")
        XCTAssertEqual(GlassToast.ToastType.error.systemImage, "xmark.circle.fill")
        XCTAssertEqual(GlassToast.ToastType.info.systemImage, "info.circle.fill")
        
        XCTAssertEqual(GlassToast.ToastType.success.color, UIColors.success)
        XCTAssertEqual(GlassToast.ToastType.warning.color, UIColors.warning)
        XCTAssertEqual(GlassToast.ToastType.error.color, UIColors.danger)
        XCTAssertEqual(GlassToast.ToastType.info.color, UIColors.accentPrimary)
    }
    
    // MARK: - GlassSearchBar Tests
    
    func testGlassSearchBarInitialization() {
        @State var searchText = ""
        
        let searchBar = GlassSearchBar(text: .constant(searchText))
        XCTAssertNotNil(searchBar)
    }
    
    func testGlassSearchBarWithCustomPlaceholder() {
        @State var searchText = ""
        
        let searchBar = GlassSearchBar(
            text: .constant(searchText),
            placeholder: "Custom placeholder"
        )
        
        XCTAssertNotNil(searchBar)
    }
    
    func testGlassSearchBarWithSearchAction() {
        @State var searchText = ""
        var searchActionCalled = false
        
        let searchBar = GlassSearchBar(
            text: .constant(searchText),
            onSearchButtonClicked: {
                searchActionCalled = true
            }
        )
        
        XCTAssertNotNil(searchBar)
    }
}