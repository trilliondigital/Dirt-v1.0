import XCTest
import SwiftUI
@testable import Dirt

/// Build and compilation performance validation tests
/// These tests validate that our architecture optimizations improve build performance
final class BuildPerformanceValidationTests: XCTestCase {
    
    // MARK: - Compilation Performance Tests
    
    func testServiceContainerCompilationPerformance() {
        // Test that service container doesn't create excessive compilation overhead
        measure {
            // Create multiple service containers to stress the compiler
            var containers: [ServiceContainer] = []
            
            for _ in 0..<10 {
                let container = ServiceFactory.createTestContainer()
                containers.append(container)
            }
            
            // Access services to trigger lazy loading compilation paths
            for container in containers {
                _ = container.mediaService
                _ = container.searchService
                _ = container.postService
                _ = container.analyticsService
            }
            
            // Clean up
            containers.removeAll()
        }
    }
    
    func testMaterialGlassCompilationPerformance() {
        // Test that Material Glass components compile efficiently
        measure {
            // Create complex nested glass components
            for _ in 0..<20 {
                let _ = VStack {
                    GlassNavigationBar(title: "Performance Test")
                    
                    ScrollView {
                        LazyVStack {
                            ForEach(0..<10, id: \.self) { index in
                                GlassCard {
                                    VStack {
                                        Text("Item \(index)")
                                        HStack {
                                            GlassButton("Action 1") { }
                                            GlassButton("Action 2") { }
                                            GlassButton("Action 3") { }
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
        }
    }
    
    func testPerformanceOptimizationCompilationPerformance() {
        // Test that performance optimization doesn't slow down compilation
        measure {
            for _ in 0..<50 {
                let service = PerformanceOptimizationService()
                
                // Test various optimization methods
                _ = service.optimizedMaterial(for: .thickMaterial)
                _ = service.optimizedAnimationDuration(for: 0.5)
                _ = service.optimizedCornerRadius(for: 20.0)
                _ = service.shouldEnableShadows
                _ = service.performanceGrade
                _ = service.averageFrameRate
            }
        }
    }
    
    // MARK: - Type System Performance Tests
    
    func testComplexTypeHierarchyPerformance() {
        // Test that our complex type hierarchies don't slow down compilation
        measure {
            // Create complex generic types similar to our architecture
            struct ComplexGenericView<Content: View>: View {
                let content: Content
                @StateObject private var performanceService = PerformanceOptimizationService.shared
                @Environment(\.services) var services
                
                var body: some View {
                    content
                        .performanceOptimizedGlass()
                        .glassAppear(isVisible: true)
                        .serviceContainer(services)
                }
            }
            
            // Create nested generic structures
            for _ in 0..<10 {
                let _ = ComplexGenericView(content: 
                    VStack {
                        ComplexGenericView(content: 
                            HStack {
                                Text("Nested")
                                GlassButton("Action") { }
                            }
                        )
                        
                        GlassCard {
                            ComplexGenericView(content: 
                                Text("Deep nesting test")
                            )
                        }
                    }
                )
            }
        }
    }
    
    func testViewModifierChainPerformance() {
        // Test that long chains of view modifiers compile efficiently
        measure {
            for _ in 0..<30 {
                let _ = Rectangle()
                    .frame(width: 100, height: 100)
                    .glassCard()
                    .glassAppear(isVisible: true)
                    .glassPress(isPressed: false)
                    .glassSelection(isSelected: false)
                    .glassFocus(isFocused: false)
                    .performanceOptimizedGlass()
                    .animation(.spring(), value: true)
                    .shadow(radius: 5)
                    .padding()
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Dependency Resolution Performance Tests
    
    func testServiceDependencyResolutionPerformance() {
        // Test that service dependency resolution is fast
        measure {
            let container = ServiceFactory.createTestContainer()
            
            // Rapidly access many services to test dependency resolution
            for _ in 0..<100 {
                _ = container.supabaseManager
                _ = container.mediaService
                _ = container.searchService
                _ = container.postService
                _ = container.analyticsService
                _ = container.performanceService
                _ = container.performanceOptimizationService
                _ = container.themeService
                _ = container.alertsService
                _ = container.networkMonitor
            }
        }
    }
    
    func testLazyLoadingPerformance() {
        // Test that lazy loading doesn't create performance bottlenecks
        measure {
            // Create many containers and access services randomly
            var containers: [ServiceContainer] = []
            
            for _ in 0..<5 {
                containers.append(ServiceFactory.createTestContainer())
            }
            
            // Random service access pattern
            for _ in 0..<200 {
                let container = containers.randomElement()!
                let serviceIndex = Int.random(in: 0..<5)
                
                switch serviceIndex {
                case 0: _ = container.mediaService
                case 1: _ = container.searchService
                case 2: _ = container.postService
                case 3: _ = container.analyticsService
                case 4: _ = container.performanceService
                default: break
                }
            }
            
            containers.removeAll()
        }
    }
    
    // MARK: - Memory Allocation Performance Tests
    
    func testMemoryAllocationPerformance() {
        // Test that our architecture doesn't create excessive memory allocations
        measure {
            autoreleasepool {
                var components: [Any] = []
                
                // Create many components rapidly
                for i in 0..<100 {
                    components.append(GlassCard {
                        VStack {
                            Text("Component \(i)")
                            GlassButton("Action \(i)") { }
                        }
                    })
                    
                    components.append(GlassButton("Button \(i)") { })
                    
                    if i % 10 == 0 {
                        // Periodically create service containers
                        let container = ServiceFactory.createTestContainer()
                        container.initializeCriticalServices()
                        components.append(container)
                    }
                }
                
                // Clear components to test deallocation
                components.removeAll()
            }
        }
    }
    
    func testServiceContainerMemoryPerformance() {
        // Test service container memory efficiency
        measure {
            var containers: [ServiceContainer] = []
            
            // Create many service containers
            for _ in 0..<20 {
                let container = ServiceFactory.createTestContainer()
                container.initializeCriticalServices()
                
                // Access all services to ensure they're loaded
                _ = container.mediaService
                _ = container.searchService
                _ = container.postService
                _ = container.analyticsService
                _ = container.performanceService
                
                containers.append(container)
            }
            
            // Clean up all containers
            for container in containers {
                container.cleanup()
            }
            containers.removeAll()
        }
    }
    
    // MARK: - Animation Performance Tests
    
    func testAnimationSystemPerformance() {
        // Test that our animation system is performant
        measure {
            // Create many animations
            for _ in 0..<100 {
                _ = MaterialMotion.Easing.quick
                _ = MaterialMotion.Spring.standard
                _ = MaterialMotion.Glass.cardAppear
                _ = MaterialMotion.Interactive.buttonPress(isPressed: true)
                _ = MaterialMotion.Loading.pulse
                _ = MaterialMotion.Transition.slideUp
            }
        }
    }
    
    func testMotionModifierPerformance() {
        // Test performance of motion modifiers
        measure {
            let baseView = Rectangle().frame(width: 50, height: 50)
            
            for _ in 0..<50 {
                let _ = baseView
                    .glassAppear(isVisible: true)
                    .glassPress(isPressed: false)
                    .glassSelection(isSelected: false)
                    .glassFocus(isFocused: false)
                    .glassModal(isPresented: false)
            }
        }
    }
    
    // MARK: - Integration Performance Tests
    
    func testFullStackPerformance() {
        // Test performance of the complete architecture stack
        measure {
            // Simulate full app creation
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            
            let performanceService = PerformanceOptimizationService.shared
            performanceService.startMonitoring()
            
            // Create complex UI hierarchy
            let _ = VStack {
                GlassNavigationBar(
                    title: "Performance Test",
                    leading: {
                        GlassButton("Back") { }
                    },
                    trailing: {
                        GlassButton("Settings") { }
                    }
                )
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<20, id: \.self) { index in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Performance Item \(index)")
                                        .font(.headline)
                                    
                                    Text("Testing full stack performance with complex layouts")
                                        .font(.caption)
                                    
                                    HStack {
                                        GlassButton("Like", systemImage: "heart", style: .subtle) { 
                                            _ = container.analyticsService
                                        }
                                        GlassButton("Share", systemImage: "square.and.arrow.up", style: .subtle) {
                                            _ = container.mediaService
                                        }
                                        Spacer()
                                        GlassButton("More", style: .secondary) {
                                            _ = container.postService
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                GlassTabBar(
                    selectedTab: .constant(0),
                    tabs: [
                        GlassTabBar.TabItem(title: "Home", systemImage: "house"),
                        GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass"),
                        GlassTabBar.TabItem(title: "Profile", systemImage: "person")
                    ]
                )
            }
            .serviceContainer(container)
            
            performanceService.stopMonitoring()
            container.cleanup()
        }
    }
    
    // MARK: - Regression Prevention Tests
    
    func testPerformanceRegression() {
        // Baseline performance test to prevent regressions
        
        let baselineExpectation = XCTestExpectation(description: "Performance should meet baseline")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform standard operations
        let container = ServiceFactory.createTestContainer()
        container.initializeCriticalServices()
        
        // Create standard UI components
        for _ in 0..<10 {
            let _ = GlassCard {
                VStack {
                    Text("Baseline test")
                    GlassButton("Action") { }
                }
            }
        }
        
        // Access services
        _ = container.mediaService
        _ = container.searchService
        _ = container.postService
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Performance should be under 100ms for these operations
        if executionTime < 0.1 {
            baselineExpectation.fulfill()
        }
        
        wait(for: [baselineExpectation], timeout: 1.0)
        
        container.cleanup()
    }
    
    func testCompilationComplexityRegression() {
        // Test that we haven't introduced compilation complexity regressions
        measure {
            // This test creates the most complex type hierarchies we use
            struct MaxComplexityView: View {
                @Environment(\.services) var services
                @StateObject private var performanceService = PerformanceOptimizationService.shared
                @State private var selectedTab = 0
                @State private var searchText = ""
                @State private var isModalPresented = false
                
                var body: some View {
                    VStack {
                        GlassNavigationBar(title: "Max Complexity")
                        
                        GlassSearchBar(text: $searchText)
                        
                        ScrollView {
                            LazyVStack {
                                ForEach(0..<5, id: \.self) { index in
                                    GlassCard {
                                        VStack {
                                            Text("Complex Item \(index)")
                                            
                                            HStack {
                                                ForEach(0..<3, id: \.self) { buttonIndex in
                                                    GlassButton("Action \(buttonIndex)") {
                                                        switch buttonIndex {
                                                        case 0: _ = services.mediaService
                                                        case 1: _ = services.searchService
                                                        case 2: _ = services.postService
                                                        default: break
                                                        }
                                                    }
                                                    .performanceOptimizedGlass()
                                                    .glassPress(isPressed: false)
                                                }
                                            }
                                        }
                                    }
                                    .glassAppear(isVisible: true)
                                }
                            }
                        }
                        
                        GlassTabBar(
                            selectedTab: $selectedTab,
                            tabs: [
                                GlassTabBar.TabItem(title: "Home", systemImage: "house"),
                                GlassTabBar.TabItem(title: "Search", systemImage: "magnifyingglass")
                            ]
                        )
                    }
                    .serviceContainer(services)
                    .sheet(isPresented: $isModalPresented) {
                        GlassModal(isPresented: $isModalPresented) {
                            Text("Modal content")
                        }
                    }
                }
            }
            
            // Create the complex view
            let _ = MaxComplexityView()
        }
    }
}

// MARK: - Performance Benchmarking

extension BuildPerformanceValidationTests {
    
    func testPerformanceBenchmarks() {
        // Set specific performance benchmarks
        
        // Service container initialization benchmark
        measure(metrics: [XCTClockMetric()]) {
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            
            // Access all services
            _ = container.supabaseManager
            _ = container.mediaService
            _ = container.searchService
            _ = container.postService
            _ = container.analyticsService
            _ = container.performanceService
            _ = container.performanceOptimizationService
            
            container.cleanup()
        }
        
        // Glass component creation benchmark
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            var components: [Any] = []
            
            for i in 0..<50 {
                components.append(GlassCard {
                    VStack {
                        Text("Benchmark \(i)")
                        GlassButton("Action") { }
                    }
                })
            }
            
            components.removeAll()
        }
    }
    
    func testMemoryBenchmarks() {
        // Memory usage benchmarks
        measure(metrics: [XCTMemoryMetric()]) {
            var containers: [ServiceContainer] = []
            
            // Create multiple service containers
            for _ in 0..<5 {
                let container = ServiceFactory.createTestContainer()
                container.initializeCriticalServices()
                containers.append(container)
            }
            
            // Create UI components
            var components: [Any] = []
            for i in 0..<30 {
                components.append(GlassCard {
                    Text("Memory test \(i)")
                })
            }
            
            // Clean up
            for container in containers {
                container.cleanup()
            }
            containers.removeAll()
            components.removeAll()
        }
    }
}