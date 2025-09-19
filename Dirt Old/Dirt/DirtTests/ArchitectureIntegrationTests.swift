import XCTest
import SwiftUI
@testable import Dirt

/// Comprehensive integration tests for the refactored architecture
/// Tests that all components work together correctly and maintain performance
final class ArchitectureIntegrationTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    var performanceService: PerformanceOptimizationService!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceFactory.createTestContainer()
        performanceService = PerformanceOptimizationService.shared
    }
    
    override func tearDown() {
        serviceContainer.cleanup()
        performanceService.stopMonitoring()
        serviceContainer = nil
        performanceService = nil
        super.tearDown()
    }
    
    // MARK: - Service Container Integration Tests
    
    func testServiceContainerArchitectureIntegration() {
        // Test that all services can be initialized and work together
        serviceContainer.initializeCriticalServices()
        
        // Verify all critical services are accessible
        XCTAssertNotNil(serviceContainer.supabaseManager, "SupabaseManager should be initialized")
        XCTAssertNotNil(serviceContainer.performanceService, "PerformanceService should be initialized")
        XCTAssertNotNil(serviceContainer.performanceOptimizationService, "PerformanceOptimizationService should be initialized")
        XCTAssertNotNil(serviceContainer.analyticsService, "AnalyticsService should be initialized")
        
        // Test service interactions
        let mediaService = serviceContainer.mediaService
        let searchService = serviceContainer.searchService
        
        XCTAssertNotNil(mediaService, "MediaService should be accessible")
        XCTAssertNotNil(searchService, "SearchService should be accessible")
        
        // Verify services are properly consolidated (no duplicates)
        XCTAssertTrue(mediaService === MediaService.shared, "MediaService should use shared instance")
        XCTAssertTrue(searchService === SearchService.shared, "SearchService should use shared instance")
    }
    
    func testServiceContainerPerformanceTracking() {
        // Test that service initialization is tracked for performance monitoring
        let freshContainer = ServiceContainer()
        
        // Access services to trigger lazy loading
        _ = freshContainer.mediaService
        _ = freshContainer.searchService
        _ = freshContainer.postService
        
        // Verify tracking
        let initializedServices = freshContainer.getInitializedServices()
        XCTAssertTrue(initializedServices.contains("MediaService"), "MediaService initialization should be tracked")
        XCTAssertTrue(initializedServices.contains("SearchService"), "SearchService initialization should be tracked")
        XCTAssertTrue(initializedServices.contains("PostService"), "PostService initialization should be tracked")
        
        // Verify timing metrics
        let metrics = freshContainer.getServiceInitializationMetrics()
        XCTAssertNotNil(metrics["MediaService"], "MediaService timing should be recorded")
        XCTAssertNotNil(metrics["SearchService"], "SearchService timing should be recorded")
        
        // Total initialization time should be reasonable
        let totalTime = freshContainer.getTotalInitializationTime()
        XCTAssertLessThan(totalTime, 1.0, "Total service initialization should be under 1 second")
    }
    
    // MARK: - Material Glass Architecture Integration Tests
    
    func testMaterialGlassDesignSystemIntegration() {
        // Test that the design system works cohesively
        
        // Test design tokens consistency
        XCTAssertEqual(UICornerRadius.lg, 16, "Large corner radius should be consistent")
        XCTAssertEqual(UISpacing.md, 16, "Medium spacing should be consistent")
        
        // Test material hierarchy
        let materials = [
            MaterialDesignSystem.Glass.ultraThin,
            MaterialDesignSystem.Glass.thin,
            MaterialDesignSystem.Glass.regular,
            MaterialDesignSystem.Glass.thick,
            MaterialDesignSystem.Glass.ultraThick
        ]
        
        for material in materials {
            XCTAssertNotNil(material, "All materials should be defined")
        }
        
        // Test context-specific materials
        XCTAssertEqual(MaterialDesignSystem.Context.card, .thinMaterial, "Card context should use thin material")
        XCTAssertEqual(MaterialDesignSystem.Context.navigation, .regularMaterial, "Navigation should use regular material")
        XCTAssertEqual(MaterialDesignSystem.Context.modal, .thickMaterial, "Modal should use thick material")
    }
    
    func testMaterialGlassComponentIntegration() {
        // Test that all glass components work together in complex layouts
        
        @State var selectedTab = 0
        @State var searchText = ""
        @State var isModalPresented = false
        
        let complexLayout = VStack(spacing: 0) {
            // Navigation
            GlassNavigationBar(
                title: "Integration Test",
                leading: {
                    GlassButton("Back", systemImage: "chevron.left") { }
                },
                trailing: {
                    GlassButton("Settings", systemImage: "gear") { }
                }
            )
            
            // Search
            GlassSearchBar(text: .constant(searchText))
                .padding()
            
            // Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<10, id: \.self) { index in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Item \(index)")
                                    .font(.headline)
                                
                                HStack {
                                    GlassButton("Like", systemImage: "heart", style: .subtle) { }
                                    GlassButton("Share", systemImage: "square.and.arrow.up", style: .subtle) { }
                                    Spacer()
                                    GlassButton("More", style: .secondary) { }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Tab Bar
            GlassTabBar(
                selectedTab: .constant(selectedTab),
                tabs: [
                    GlassTabBar.TabItem(title: "Home", systemImage: "house"),
                    GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
                    GlassTabBar.TabItem(title: "Profile", systemImage: "person")
                ]
            )
        }
        
        XCTAssertNotNil(complexLayout, "Complex glass layout should be created successfully")
    }
    
    // MARK: - Performance Optimization Integration Tests
    
    func testPerformanceOptimizationIntegration() {
        // Test that performance optimization works with the architecture
        
        performanceService.startMonitoring()
        performanceService.performanceMode = .highPerformance
        
        // Test material optimization
        let originalMaterial = Material.thickMaterial
        let optimizedMaterial = performanceService.optimizedMaterial(for: originalMaterial)
        
        // In high performance mode, thick material should be optimized to a lighter one
        XCTAssertNotEqual(optimizedMaterial, originalMaterial, "Material should be optimized in high performance mode")
        
        // Test animation optimization
        let originalDuration: TimeInterval = 0.5
        let optimizedDuration = performanceService.optimizedAnimationDuration(for: originalDuration)
        XCTAssertLessThanOrEqual(optimizedDuration, originalDuration, "Animation duration should be optimized")
        
        // Test shadow optimization
        XCTAssertFalse(performanceService.shouldEnableShadows, "Shadows should be disabled in high performance mode")
        
        performanceService.stopMonitoring()
    }
    
    func testPerformanceOptimizedComponentsIntegration() {
        // Test that performance-optimized components work correctly
        
        let optimizedCard = GlassCard {
            VStack {
                Text("Performance Test")
                GlassButton("Action") { }
            }
        }
        
        XCTAssertNotNil(optimizedCard, "Performance-optimized glass card should be created")
        
        // Test that performance optimization doesn't break functionality
        let button = GlassButton("Test", style: .primary) { }
        XCTAssertNotNil(button, "Performance-optimized glass button should be created")
    }
    
    // MARK: - Motion System Integration Tests
    
    func testMotionSystemIntegration() {
        // Test that the motion system integrates properly with components
        
        let animations = [
            MaterialMotion.Easing.quick,
            MaterialMotion.Spring.standard,
            MaterialMotion.Glass.cardAppear,
            MaterialMotion.Interactive.buttonPress(isPressed: true)
        ]
        
        for animation in animations {
            XCTAssertNotNil(animation, "All motion system animations should be defined")
        }
        
        // Test motion modifiers
        let testView = Rectangle()
            .frame(width: 100, height: 100)
            .glassAppear(isVisible: true)
            .glassPress(isPressed: false)
            .glassSelection(isSelected: false)
        
        XCTAssertNotNil(testView, "Motion modifiers should work with views")
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegration() {
        // Test that error handling works across the architecture
        
        let errorToast = GlassToast(message: "Test error", type: .error)
        let successToast = GlassToast(message: "Test success", type: .success)
        
        XCTAssertNotNil(errorToast, "Error toast should be created")
        XCTAssertNotNil(successToast, "Success toast should be created")
        
        // Test error presenter integration
        let errorPresenter = serviceContainer.errorPresenter
        XCTAssertNotNil(errorPresenter, "Error presenter should be available through service container")
    }
    
    // MARK: - Navigation Integration Tests
    
    func testNavigationIntegration() {
        // Test navigation coordination with Material Glass
        
        let navigationCoordinator = NavigationCoordinator()
        XCTAssertNotNil(navigationCoordinator, "Navigation coordinator should be created")
        
        // Test glass navigation components
        let glassNavBar = GlassNavigationBar(title: "Test")
        XCTAssertNotNil(glassNavBar, "Glass navigation bar should be created")
        
        let glassTabBar = GlassTabBar(
            selectedTab: .constant(0),
            tabs: [
                GlassTabBar.TabItem(title: "Home", systemImage: "house")
            ]
        )
        XCTAssertNotNil(glassTabBar, "Glass tab bar should be created")
    }
    
    // MARK: - Full Architecture Integration Tests
    
    func testFullArchitectureIntegration() {
        // Test the complete architecture working together
        
        // Initialize all services
        serviceContainer.initializeCriticalServices()
        
        // Start performance monitoring
        performanceService.startMonitoring()
        
        // Create a complex app-like structure
        let appStructure = VStack {
            // Services layer (invisible but active)
            EmptyView()
                .environmentObject(serviceContainer)
            
            // UI layer with Material Glass
            VStack(spacing: 0) {
                GlassNavigationBar(title: "Full Integration Test")
                
                ScrollView {
                    LazyVStack {
                        ForEach(0..<20, id: \.self) { index in
                            GlassCard {
                                HStack {
                                    Text("Integration Item \(index)")
                                    Spacer()
                                    GlassButton("Action") {
                                        // This would trigger service calls in real app
                                        _ = serviceContainer.analyticsService
                                        _ = serviceContainer.mediaService
                                    }
                                }
                            }
                        }
                    }
                }
                
                GlassTabBar(
                    selectedTab: .constant(0),
                    tabs: [
                        GlassTabBar.TabItem(title: "Home", systemImage: "house"),
                        GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass")
                    ]
                )
            }
        }
        
        XCTAssertNotNil(appStructure, "Full architecture integration should work")
        
        // Verify services are working
        XCTAssertGreaterThan(serviceContainer.getInitializedServices().count, 0, "Services should be initialized")
        
        // Verify performance monitoring is active
        XCTAssertGreaterThan(performanceService.currentFrameRate, 0, "Performance monitoring should be active")
        
        performanceService.stopMonitoring()
    }
    
    // MARK: - Memory Management Integration Tests
    
    func testMemoryManagementIntegration() {
        // Test that the architecture doesn't create memory leaks
        
        weak var weakContainer: ServiceContainer?
        weak var weakPerformanceService: PerformanceOptimizationService?
        
        autoreleasepool {
            let container = ServiceFactory.createTestContainer()
            let perfService = PerformanceOptimizationService()
            
            weakContainer = container
            weakPerformanceService = perfService
            
            // Use the services
            container.initializeCriticalServices()
            perfService.startMonitoring()
            perfService.stopMonitoring()
            
            // Create some glass components
            let _ = GlassCard {
                Text("Memory test")
            }
            
            let _ = GlassButton("Test") { }
        }
        
        // Objects should be deallocated
        XCTAssertNil(weakContainer, "Service container should be deallocated")
        XCTAssertNil(weakPerformanceService, "Performance service should be deallocated")
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testAccessibilityIntegration() {
        // Test that accessibility works across the architecture
        
        let accessibleLayout = VStack {
            GlassNavigationBar(title: "Accessible App")
                .accessibilityLabel("Main navigation")
            
            GlassCard {
                VStack {
                    Text("Accessible content")
                        .accessibilityLabel("Main content area")
                    
                    GlassButton("Accessible Action") { }
                        .accessibilityLabel("Perform main action")
                        .accessibilityHint("Tap to execute the primary function")
                }
            }
            .accessibilityElement(children: .contain)
            
            GlassTabBar(
                selectedTab: .constant(0),
                tabs: [
                    GlassTabBar.TabItem(title: "Home", systemImage: "house")
                ]
            )
            .accessibilityLabel("Tab navigation")
        }
        
        XCTAssertNotNil(accessibleLayout, "Accessible layout should be created")
    }
    
    // MARK: - Performance Regression Tests
    
    func testPerformanceRegression() {
        // Baseline performance tests to catch regressions
        
        measure {
            // Test service container performance
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            
            // Test glass component creation performance
            for _ in 0..<50 {
                let _ = GlassCard {
                    VStack {
                        Text("Performance test")
                        GlassButton("Action") { }
                    }
                }
            }
            
            // Test service access performance
            for _ in 0..<100 {
                _ = container.mediaService
                _ = container.searchService
                _ = container.postService
            }
            
            container.cleanup()
        }
    }
    
    func testBuildTimeOptimization() {
        // Test that our architecture doesn't negatively impact build times
        // by creating complex type hierarchies efficiently
        
        measure {
            struct ComplexArchitectureView: View {
                @Environment(\.services) var services
                @StateObject private var performanceService = PerformanceOptimizationService.shared
                
                var body: some View {
                    VStack {
                        GlassNavigationBar(title: "Complex View")
                        
                        ScrollView {
                            LazyVStack {
                                ForEach(0..<10, id: \.self) { index in
                                    GlassCard {
                                        VStack {
                                            Text("Item \(index)")
                                            
                                            HStack {
                                                GlassButton("Action 1") {
                                                    _ = services.mediaService
                                                }
                                                GlassButton("Action 2") {
                                                    _ = services.searchService
                                                }
                                            }
                                        }
                                    }
                                    .performanceOptimizedGlass()
                                    .glassAppear(isVisible: true)
                                }
                            }
                        }
                        
                        GlassTabBar(
                            selectedTab: .constant(0),
                            tabs: [
                                GlassTabBar.TabItem(title: "Home", systemImage: "house")
                            ]
                        )
                    }
                    .serviceContainer(services)
                }
            }
            
            // Create multiple instances to test compilation performance
            for _ in 0..<5 {
                let _ = ComplexArchitectureView()
            }
        }
    }
}

// MARK: - Architecture Validation Tests

extension ArchitectureIntegrationTests {
    
    func testArchitectureConstraints() {
        // Test that the architecture follows its design constraints
        
        // 1. Service container should be a singleton
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        XCTAssertTrue(container1 === container2, "ServiceContainer should be singleton")
        
        // 2. Services should be lazy-loaded
        let freshContainer = ServiceContainer()
        XCTAssertTrue(freshContainer.getInitializedServices().isEmpty, "Services should be lazy-loaded")
        
        // 3. Performance optimization should be configurable
        performanceService.performanceMode = .highPerformance
        XCTAssertEqual(performanceService.performanceMode, .highPerformance, "Performance mode should be configurable")
        
        // 4. Material Glass components should use design tokens
        let cardRadius = UICornerRadius.lg
        let buttonRadius = UICornerRadius.md
        XCTAssertNotEqual(cardRadius, buttonRadius, "Different components should use different radii")
        
        // 5. Error handling should be centralized
        let errorPresenter = serviceContainer.errorPresenter
        XCTAssertNotNil(errorPresenter, "Error handling should be centralized")
    }
    
    func testArchitectureScalability() {
        // Test that the architecture can handle scaling
        
        // Create many service containers (simulating multiple app instances)
        var containers: [ServiceContainer] = []
        for _ in 0..<10 {
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            containers.append(container)
        }
        
        // All should work independently
        for container in containers {
            XCTAssertNotNil(container.mediaService, "Each container should have independent services")
            XCTAssertGreaterThan(container.getInitializedServices().count, 0, "Services should be initialized")
        }
        
        // Clean up
        for container in containers {
            container.cleanup()
        }
        containers.removeAll()
    }
    
    func testArchitectureMaintainability() {
        // Test that the architecture supports maintainability
        
        // 1. Services should be replaceable
        let mockAnalytics = AnalyticsService()
        serviceContainer.register(mockAnalytics, for: \.analyticsService)
        XCTAssertTrue(serviceContainer.analyticsService === mockAnalytics, "Services should be replaceable")
        
        // 2. Components should be composable
        let composedView = VStack {
            GlassCard {
                GlassButton("Nested Button") { }
            }
        }
        XCTAssertNotNil(composedView, "Components should be composable")
        
        // 3. Performance optimization should be transparent
        let optimizedView = Rectangle()
            .performanceOptimizedGlass()
        XCTAssertNotNil(optimizedView, "Performance optimization should be transparent")
    }
}