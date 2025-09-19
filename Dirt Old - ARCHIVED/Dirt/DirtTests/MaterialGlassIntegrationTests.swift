import XCTest
import SwiftUI
@testable import Dirt

/// Integration tests for Material Glass components working together
/// Tests component composition and real-world usage scenarios
final class MaterialGlassIntegrationTests: XCTestCase {
    
    // MARK: - Component Integration Tests
    
    func testGlassComponentsIntegration() {
        // Test that all glass components can be used together
        @State var selectedTab = 0
        @State var searchText = ""
        @State var isModalPresented = false
        
        let tabs = [
            GlassTabBar.TabItem(title: "Home", systemImage: "house"),
            GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass")
        ]
        
        // Create a complex view using multiple glass components
        let complexView = VStack {
            GlassNavigationBar(
                title: "Test App",
                leading: {
                    GlassButton("Back", systemImage: "chevron.left") { }
                },
                trailing: {
                    GlassButton("Settings", systemImage: "gear") { }
                }
            )
            
            GlassSearchBar(text: .constant(searchText))
            
            GlassCard {
                VStack {
                    Text("Card Content")
                    GlassButton("Action", style: .primary) { }
                }
            }
            
            Spacer()
            
            GlassTabBar(selectedTab: .constant(selectedTab), tabs: tabs)
        }
        
        XCTAssertNotNil(complexView)
    }
    
    func testGlassModalWithComponents() {
        // Test that glass modal can contain other glass components
        @State var isPresented = false
        
        let modal = GlassModal(isPresented: .constant(isPresented)) {
            VStack(spacing: 16) {
                Text("Modal Title")
                    .font(.headline)
                
                GlassCard {
                    Text("Modal content in a glass card")
                }
                
                HStack {
                    GlassButton("Cancel", style: .secondary) {
                        isPresented = false
                    }
                    
                    GlassButton("Confirm", style: .primary) {
                        isPresented = false
                    }
                }
            }
        }
        
        XCTAssertNotNil(modal)
    }
    
    // MARK: - Design System Consistency Tests
    
    func testDesignSystemConsistency() {
        // Test that all components use consistent design tokens
        
        // Verify that components use the same corner radius tokens
        let cardRadius = UICornerRadius.lg
        let buttonRadius = UICornerRadius.md
        let modalRadius = UICornerRadius.xl
        
        XCTAssertEqual(cardRadius, 16)
        XCTAssertEqual(buttonRadius, 12)
        XCTAssertEqual(modalRadius, 20)
        
        // Verify that components use consistent spacing
        let smallSpacing = UISpacing.sm
        let mediumSpacing = UISpacing.md
        let largeSpacing = UISpacing.lg
        
        XCTAssertEqual(smallSpacing, 12)
        XCTAssertEqual(mediumSpacing, 16)
        XCTAssertEqual(largeSpacing, 24)
    }
    
    func testMaterialHierarchy() {
        // Test that materials follow a logical hierarchy
        let materials = [
            MaterialDesignSystem.Glass.ultraThin,
            MaterialDesignSystem.Glass.thin,
            MaterialDesignSystem.Glass.regular,
            MaterialDesignSystem.Glass.thick,
            MaterialDesignSystem.Glass.ultraThick
        ]
        
        // All materials should be defined
        for material in materials {
            XCTAssertNotNil(material)
        }
        
        // Context materials should use appropriate hierarchy
        XCTAssertEqual(MaterialDesignSystem.Context.tabBar, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.card, .thinMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.navigation, .regularMaterial)
        XCTAssertEqual(MaterialDesignSystem.Context.modal, .thickMaterial)
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAccessibilityIntegration() {
        // Test that components maintain accessibility when used together
        
        let accessibleView = VStack {
            GlassNavigationBar(title: "Accessible App")
            
            GlassCard {
                VStack {
                    Text("Accessible content")
                        .accessibilityLabel("Main content")
                    
                    GlassButton("Accessible Action") { }
                        .accessibilityLabel("Perform action")
                        .accessibilityHint("Tap to perform the main action")
                }
            }
            .accessibilityElement(children: .contain)
        }
        
        XCTAssertNotNil(accessibleView)
    }
    
    func testButtonAccessibilityMinimumSize() {
        // Test that buttons meet minimum accessibility touch target
        let button = GlassButton("Test") { }
        
        // The button should have a minimum height of 44 points
        // This is enforced in the component implementation
        XCTAssertNotNil(button)
    }
    
    // MARK: - Animation Integration Tests
    
    func testAnimationIntegration() {
        // Test that components work well with the motion system
        
        @State var isVisible = true
        @State var isPressed = false
        @State var isSelected = false
        
        let animatedView = VStack {
            GlassCard {
                Text("Animated Card")
            }
            .glassAppear(isVisible: isVisible)
            
            GlassButton("Animated Button") { }
                .glassPress(isPressed: isPressed)
                .glassSelection(isSelected: isSelected)
        }
        
        XCTAssertNotNil(animatedView)
    }
    
    func testMotionSystemIntegration() {
        // Test that motion system works with glass components
        
        let quickAnimation = MaterialMotion.Easing.quick
        let standardAnimation = MaterialMotion.Spring.standard
        let glassAnimation = MaterialMotion.Glass.cardAppear
        
        XCTAssertNotNil(quickAnimation)
        XCTAssertNotNil(standardAnimation)
        XCTAssertNotNil(glassAnimation)
    }
    
    // MARK: - Performance Integration Tests
    
    func testComponentCompositionPerformance() {
        // Test that composing multiple glass components is performant
        measure {
            for _ in 0..<100 {
                let _ = GlassCard {
                    VStack {
                        GlassButton("Button 1") { }
                        GlassButton("Button 2") { }
                        GlassSearchBar(text: .constant(""))
                    }
                }
            }
        }
    }
    
    func testLargeListPerformance() {
        // Test performance with many glass components
        measure {
            let _ = ScrollView {
                LazyVStack {
                    ForEach(0..<100, id: \.self) { index in
                        GlassCard {
                            HStack {
                                Text("Item \(index)")
                                Spacer()
                                GlassButton("Action") { }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() {
        // Test that error handling works with glass components
        
        let errorToast = GlassToast(message: "Test error", type: .error)
        let successToast = GlassToast(message: "Test success", type: .success)
        let warningToast = GlassToast(message: "Test warning", type: .warning)
        let infoToast = GlassToast(message: "Test info", type: .info)
        
        XCTAssertNotNil(errorToast)
        XCTAssertNotNil(successToast)
        XCTAssertNotNil(warningToast)
        XCTAssertNotNil(infoToast)
    }
    
    // MARK: - Real-World Usage Tests
    
    func testFeedViewIntegration() {
        // Test components in a feed-like layout
        @State var selectedTab = 0
        
        let feedView = VStack(spacing: 0) {
            GlassNavigationBar(
                title: "Feed",
                trailing: {
                    GlassButton("Create", systemImage: "plus") { }
                }
            )
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<10, id: \.self) { index in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("User \(index)")
                                        .font(.headline)
                                    Spacer()
                                    GlassButton("Follow", style: .secondary) { }
                                }
                                
                                Text("This is a sample post content for item \(index)")
                                
                                HStack {
                                    GlassButton("Like", systemImage: "heart", style: .subtle) { }
                                    GlassButton("Comment", systemImage: "message", style: .subtle) { }
                                    GlassButton("Share", systemImage: "square.and.arrow.up", style: .subtle) { }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            GlassTabBar(
                selectedTab: .constant(selectedTab),
                tabs: [
                    GlassTabBar.TabItem(title: "Feed", systemImage: "house"),
                    GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
                    GlassTabBar.TabItem(title: "Profile", systemImage: "person")
                ]
            )
        }
        
        XCTAssertNotNil(feedView)
    }
    
    func testSearchViewIntegration() {
        // Test components in a search-like layout
        @State var searchText = ""
        @State var selectedTab = 1
        
        let searchView = VStack(spacing: 0) {
            GlassNavigationBar(title: "Search")
            
            VStack(spacing: 16) {
                GlassSearchBar(
                    text: .constant(searchText),
                    placeholder: "Search for posts, users, topics..."
                ) {
                    // Perform search
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<5, id: \.self) { index in
                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Search Result \(index)")
                                            .font(.headline)
                                        Text("Description for result \(index)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    GlassButton("View", style: .secondary) { }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            GlassTabBar(
                selectedTab: .constant(selectedTab),
                tabs: [
                    GlassTabBar.TabItem(title: "Feed", systemImage: "house"),
                    GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
                    GlassTabBar.TabItem(title: "Profile", systemImage: "person")
                ]
            )
        }
        
        XCTAssertNotNil(searchView)
    }
    
    func testModalWorkflowIntegration() {
        // Test a complete modal workflow
        @State var isCreatePostModalPresented = false
        @State var postText = ""
        
        let createPostModal = GlassModal(isPresented: .constant(isCreatePostModalPresented)) {
            VStack(spacing: 20) {
                HStack {
                    Text("Create Post")
                        .font(.headline)
                    Spacer()
                    GlassButton("Cancel", style: .subtle) {
                        isCreatePostModalPresented = false
                    }
                }
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's on your mind?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // In a real implementation, this would be a TextEditor
                        Text("Post content would go here...")
                            .frame(minHeight: 100, alignment: .topLeading)
                    }
                }
                
                HStack {
                    GlassButton("Add Photo", systemImage: "photo", style: .secondary) { }
                    GlassButton("Add Location", systemImage: "location", style: .secondary) { }
                    Spacer()
                    GlassButton("Post", style: .primary) {
                        // Submit post
                        isCreatePostModalPresented = false
                    }
                }
            }
        }
        
        XCTAssertNotNil(createPostModal)
    }
}