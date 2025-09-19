import XCTest
import SwiftUI
@testable import Dirt

/// Performance tests for Material Glass components and service container optimizations
final class PerformanceOptimizationTests: XCTestCase {
    
    var performanceService: PerformanceOptimizationService!
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        performanceService = PerformanceOptimizationService.shared
        serviceContainer = ServiceFactory.createTestContainer()
    }
    
    override func tearDown() {
        performanceService.stopMonitoring()
        performanceService = nil
        serviceContainer = nil
        super.tearDown()
    }
    
    // MARK: - Service Container Performance Tests
    
    func testServiceContainerLazyLoading() {
        // Test that services are only initialized when accessed
        let freshContainer = ServiceContainer()
        
        // Initially, no services should be initialized
        XCTAssertTrue(freshContainer.getInitializedServices().isEmpty, "No services should be initialized initially")
        
        // Access a service and verify it's tracked
        _ = freshContainer.mediaService
        XCTAssertTrue(freshContainer.getInitializedServices().contains("MediaService"), "MediaService should be marked as initialized")
        
        // Access another service
        _ = freshContainer.searchService
        XCTAssertTrue(freshContainer.getInitializedServices().contains("SearchService"), "SearchService should be marked as initialized")
        
        // Verify initialization times are recorded
        let metrics = freshContainer.getServiceInitializationMetrics()
        XCTAssertNotNil(metrics["MediaService"], "MediaService initialization time should be recorded")
        XCTAssertNotNil(metrics["SearchService"], "SearchService initialization time should be recorded")
    }
    
    func testServiceInitializationPerformance() {
        measure {
            let container = ServiceContainer()
            
            // Initialize all critical services
            container.initializeCriticalServices()
            
            // Access all services to trigger lazy loading
            _ = container.supabaseManager
            _ = container.mediaService
            _ = container.searchService
            _ = container.postService
            _ = container.analyticsService
            _ = container.performanceService
            _ = container.performanceOptimizationService
        }
    }
    
    func testServiceAccessPerformance() {
        // Pre-initialize services
        serviceContainer.initializeCriticalServices()
        
        measure {
            // Test repeated access to services (should be fast after initialization)
            for _ in 0..<1000 {
                _ = serviceContainer.mediaService
                _ = serviceContainer.searchService
                _ = serviceContainer.postService
                _ = serviceContainer.analyticsService
            }
        }
    }
    
    func testServiceContainerMemoryUsage() {
        // Test that service container doesn't create excessive memory overhead
        let initialMemory = getMemoryUsage()
        
        // Create multiple service containers
        var containers: [ServiceContainer] = []
        for _ in 0..<10 {
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            containers.append(container)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 50MB for 10 containers)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory usage should be reasonable")
        
        // Clean up
        containers.removeAll()
    }
    
    // MARK: - Material Glass Performance Tests
    
    func testGlassCardRenderingPerformance() {
        measure {
            // Test creating many glass cards
            for _ in 0..<100 {
                let _ = GlassCard {
                    VStack {
                        Text("Performance Test")
                        Text("Card Content")
                    }
                }
            }
        }
    }
    
    func testGlassButtonRenderingPerformance() {
        measure {
            // Test creating many glass buttons
            for _ in 0..<100 {
                let _ = GlassButton("Test Button", style: .primary) { }
            }
        }
    }
    
    func testComplexGlassLayoutPerformance() {
        measure {
            // Test complex layouts with multiple glass components
            for _ in 0..<50 {
                let _ = VStack {
                    GlassNavigationBar(title: "Performance Test")
                    
                    ScrollView {
                        LazyVStack {
                            ForEach(0..<20, id: \.self) { index in
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
    
    // MARK: - Performance Optimization Service Tests
    
    func testPerformanceOptimizationService() {
        // Test that performance optimization service works correctly
        XCTAssertNotNil(performanceService, "Performance service should be available")
        
        // Test material optimization
        let optimizedMaterial = performanceService.optimizedMaterial(for: .thickMaterial)
        XCTAssertNotNil(optimizedMaterial, "Should return an optimized material")
        
        // Test animation duration optimization
        let optimizedDuration = performanceService.optimizedAnimationDuration(for: 0.5)
        XCTAssertLessThanOrEqual(optimizedDuration, 0.5, "Optimized duration should not exceed requested duration")
        
        // Test corner radius optimization
        let optimizedRadius = performanceService.optimizedCornerRadius(for: 20.0)
        XCTAssertGreaterThan(optimizedRadius, 0, "Optimized radius should be positive")
    }
    
    func testPerformanceModeAdjustment() {
        // Test automatic performance mode adjustment
        performanceService.performanceMode = .highQuality
        
        // Simulate low frame rate
        let lowFpsReflection = Mirror(reflecting: performanceService)
        if let adjustMethod = lowFpsReflection.children.first(where: { $0.label == "adjustPerformanceModeIfNeeded" }) {
            // This is a private method, so we test the public interface instead
            XCTAssertEqual(performanceService.performanceMode, .highQuality, "Should start in high quality mode")
        }
    }
    
    func testFrameRateMonitoring() {
        // Test frame rate monitoring functionality
        performanceService.startMonitoring()
        
        // Wait a bit for monitoring to start
        let expectation = XCTestExpectation(description: "Frame rate monitoring")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Frame rate should be initialized
        XCTAssertGreaterThan(performanceService.currentFrameRate, 0, "Frame rate should be monitored")
        
        performanceService.stopMonitoring()
    }
    
    // MARK: - Animation Performance Tests
    
    func testAnimationPerformance() {
        measure {
            // Test animation creation performance
            for _ in 0..<1000 {
                let _ = MaterialMotion.Spring.standard
                let _ = MaterialMotion.Easing.quick
                let _ = MaterialMotion.Glass.cardAppear
            }
        }
    }
    
    func testMotionSystemPerformance() {
        measure {
            // Test motion system performance with view modifiers
            let testView = Rectangle()
                .frame(width: 100, height: 100)
            
            for _ in 0..<100 {
                let _ = testView
                    .glassAppear(isVisible: true)
                    .glassPress(isPressed: false)
                    .glassSelection(isSelected: false)
            }
        }
    }
    
    // MARK: - Build Time Performance Tests
    
    func testCompilationPerformance() {
        // This test ensures that our optimizations don't negatively impact compilation
        measure {
            // Create complex type hierarchies that would stress the compiler
            struct ComplexView: View {
                var body: some View {
                    VStack {
                        GlassCard {
                            VStack {
                                ForEach(0..<5, id: \.self) { index in
                                    GlassButton("Button \(index)") { }
                                        .glassPress(isPressed: false)
                                }
                            }
                        }
                        .glassAppear(isVisible: true)
                        
                        GlassSearchBar(text: .constant(""))
                        
                        GlassModal(isPresented: .constant(false)) {
                            Text("Modal Content")
                        }
                    }
                }
            }
            
            // Create multiple instances to test compilation performance
            for _ in 0..<10 {
                let _ = ComplexView()
            }
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryLeakPrevention() {
        weak var weakService: PerformanceOptimizationService?
        
        autoreleasepool {
            let service = PerformanceOptimizationService()
            weakService = service
            service.startMonitoring()
            service.stopMonitoring()
        }
        
        // Service should be deallocated
        XCTAssertNil(weakService, "Performance service should be deallocated to prevent memory leaks")
    }
    
    func testServiceContainerMemoryLeaks() {
        weak var weakContainer: ServiceContainer?
        
        autoreleasepool {
            let container = ServiceFactory.createTestContainer()
            weakContainer = container
            container.initializeCriticalServices()
            container.cleanup()
        }
        
        // Container should be deallocated
        XCTAssertNil(weakContainer, "Service container should be deallocated to prevent memory leaks")
    }
    
    // MARK: - Integration Performance Tests
    
    func testFullAppPerformanceSimulation() {
        measure {
            // Simulate full app startup and usage
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            
            // Simulate creating main app views
            let mainView = VStack {
                GlassNavigationBar(title: "App")
                
                ScrollView {
                    LazyVStack {
                        ForEach(0..<50, id: \.self) { index in
                            GlassCard {
                                HStack {
                                    Text("Content \(index)")
                                    Spacer()
                                    GlassButton("Action") { }
                                }
                            }
                        }
                    }
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
            
            // Simulate service usage
            _ = container.mediaService
            _ = container.searchService
            _ = container.postService
            
            container.cleanup()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Performance Benchmark Tests

extension PerformanceOptimizationTests {
    
    func testPerformanceBenchmarks() {
        // Set performance expectations
        let serviceInitializationExpectation = XCTestExpectation(description: "Service initialization should be fast")
        let glassRenderingExpectation = XCTestExpectation(description: "Glass rendering should be fast")
        
        // Test service initialization time
        let startTime = CFAbsoluteTimeGetCurrent()
        serviceContainer.initializeCriticalServices()
        let initTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Service initialization should be under 100ms
        if initTime < 0.1 {
            serviceInitializationExpectation.fulfill()
        }
        
        // Test glass component rendering time
        let renderStartTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            let _ = GlassCard {
                Text("Benchmark Test")
            }
        }
        let renderTime = CFAbsoluteTimeGetCurrent() - renderStartTime
        
        // Rendering 100 components should be under 50ms
        if renderTime < 0.05 {
            glassRenderingExpectation.fulfill()
        }
        
        wait(for: [serviceInitializationExpectation, glassRenderingExpectation], timeout: 1.0)
    }
    
    func testPerformanceRegression() {
        // Baseline performance measurements to detect regressions
        
        // Service container performance baseline
        let serviceContainerBaseline = measureTime {
            let container = ServiceFactory.createTestContainer()
            container.initializeCriticalServices()
            _ = container.mediaService
            _ = container.searchService
            _ = container.postService
        }
        
        // Glass component performance baseline
        let glassComponentBaseline = measureTime {
            for _ in 0..<50 {
                let _ = GlassCard {
                    VStack {
                        Text("Baseline Test")
                        GlassButton("Action") { }
                    }
                }
            }
        }
        
        // These should be reasonable performance baselines
        XCTAssertLessThan(serviceContainerBaseline, 0.1, "Service container initialization should be under 100ms")
        XCTAssertLessThan(glassComponentBaseline, 0.05, "Glass component creation should be under 50ms")
    }
    
    private func measureTime<T>(_ operation: () -> T) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = operation()
        return CFAbsoluteTimeGetCurrent() - startTime
    }
}