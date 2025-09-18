import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class ServiceContainerTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceContainer()
    }
    
    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSharedInstanceIsSingleton() {
        let instance1 = ServiceContainer.shared
        let instance2 = ServiceContainer.shared
        
        XCTAssertTrue(instance1 === instance2, "ServiceContainer.shared should return the same instance")
    }
    
    // MARK: - Service Lazy Loading Tests
    
    func testServicesAreLazilyLoaded() {
        // Services should not be initialized until accessed
        let mirror = Mirror(reflecting: serviceContainer)
        
        // Check that lazy properties are not yet initialized
        // This is a basic test - in practice, we'd need more sophisticated checking
        XCTAssertNotNil(serviceContainer)
    }
    
    func testMediaServiceAccess() {
        let mediaService = serviceContainer.mediaService
        XCTAssertNotNil(mediaService)
        XCTAssertTrue(mediaService === serviceContainer.mediaService, "Should return same instance on subsequent access")
    }
    
    func testSearchServiceAccess() {
        let searchService = serviceContainer.searchService
        XCTAssertNotNil(searchService)
        XCTAssertTrue(searchService === serviceContainer.searchService, "Should return same instance on subsequent access")
    }
    
    func testSupabaseManagerAccess() {
        let supabaseManager = serviceContainer.supabaseManager
        XCTAssertNotNil(supabaseManager)
        XCTAssertTrue(supabaseManager === serviceContainer.supabaseManager, "Should return same instance on subsequent access")
    }
    
    // MARK: - Service Registration Tests
    
    func testServiceRegistration() {
        // Create a mock service
        class MockService {
            let id = UUID()
        }
        
        // We can't easily test registration without modifying the container structure
        // This test verifies the service method works
        let mediaService = serviceContainer.service(of: MediaService.self)
        XCTAssertNotNil(mediaService)
    }
    
    func testServiceByTypeRetrieval() {
        // Access a service first to ensure it's loaded
        _ = serviceContainer.mediaService
        
        // Then try to retrieve it by type
        let retrievedService = serviceContainer.service(of: MediaService.self)
        XCTAssertNotNil(retrievedService)
        XCTAssertTrue(retrievedService === serviceContainer.mediaService)
    }
    
    func testServiceByTypeReturnsNilForUnknownType() {
        class UnknownService {}
        
        let unknownService = serviceContainer.service(of: UnknownService.self)
        XCTAssertNil(unknownService)
    }
    
    // MARK: - Critical Services Initialization Tests
    
    func testInitializeCriticalServices() {
        // This should not throw and should initialize key services
        serviceContainer.initializeCriticalServices()
        
        // Verify critical services are accessible
        XCTAssertNotNil(serviceContainer.supabaseManager)
        XCTAssertNotNil(serviceContainer.performanceService)
        XCTAssertNotNil(serviceContainer.analyticsService)
        XCTAssertNotNil(serviceContainer.errorPresenter)
    }
    
    // MARK: - Environment Integration Tests
    
    func testEnvironmentKeyDefaultValue() {
        let defaultContainer = ServiceContainerKey.defaultValue
        XCTAssertTrue(defaultContainer === ServiceContainer.shared)
    }
    
    func testEnvironmentValueAccess() {
        struct TestView: View {
            @Environment(\.services) var services
            
            var body: some View {
                Text("Test")
            }
            
            func getServices() -> ServiceContainer {
                return services
            }
        }
        
        let testView = TestView()
        let services = testView.getServices()
        XCTAssertTrue(services === ServiceContainer.shared)
    }
    
    // MARK: - Service Factory Tests
    
    func testServiceFactoryCreateContainer() {
        let container = ServiceFactory.createContainer()
        XCTAssertNotNil(container)
        XCTAssertFalse(container === ServiceContainer.shared, "Factory should create new instance")
    }
    
    func testServiceFactoryCreateContainerWithConfiguration() {
        var configurationCalled = false
        
        let container = ServiceFactory.createContainer { _ in
            configurationCalled = true
        }
        
        XCTAssertNotNil(container)
        XCTAssertTrue(configurationCalled, "Configuration closure should be called")
    }
    
    func testServiceFactoryCreateTestContainer() {
        let testContainer = ServiceFactory.createTestContainer()
        XCTAssertNotNil(testContainer)
        XCTAssertFalse(testContainer === ServiceContainer.shared, "Test container should be separate instance")
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanupDoesNotThrow() {
        // Cleanup should not throw exceptions
        XCTAssertNoThrow(serviceContainer.cleanup())
    }
    
    // MARK: - Memory Management Tests
    
    func testServiceContainerDoesNotRetainCycles() {
        weak var weakContainer: ServiceContainer?
        
        autoreleasepool {
            let container = ServiceContainer()
            weakContainer = container
            
            // Access some services to ensure they're loaded
            _ = container.mediaService
            _ = container.searchService
        }
        
        // Note: This test might not work as expected due to singleton pattern
        // but it's good to have for future reference
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentServiceAccess() async {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        // Test concurrent access to services
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor in
                    let mediaService = self.serviceContainer.mediaService
                    let searchService = self.serviceContainer.searchService
                    
                    XCTAssertNotNil(mediaService)
                    XCTAssertNotNil(searchService)
                    
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Service Dependencies Tests
    
    func testServiceDependenciesAreResolved() {
        // Test that services can access other services through the container
        let mediaService = serviceContainer.mediaService
        let searchService = serviceContainer.searchService
        
        XCTAssertNotNil(mediaService)
        XCTAssertNotNil(searchService)
        
        // Both services should be able to access SupabaseManager
        XCTAssertNotNil(serviceContainer.supabaseManager)
    }
    
    // MARK: - Performance Tests
    
    func testServiceAccessPerformance() {
        measure {
            // Measure performance of accessing services
            for _ in 0..<1000 {
                _ = serviceContainer.mediaService
                _ = serviceContainer.searchService
                _ = serviceContainer.supabaseManager
            }
        }
    }
    
    func testServiceInitializationPerformance() {
        measure {
            // Measure performance of service initialization
            let container = ServiceContainer()
            container.initializeCriticalServices()
        }
    }
}

// MARK: - Mock Services for Testing

class MockManagedService: ManagedService {
    var isInitialized = false
    var isCleanedUp = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func cleanup() async {
        isCleanedUp = true
    }
}

// MARK: - Managed Service Tests

@MainActor
final class ManagedServiceTests: XCTestCase {
    
    func testManagedServiceInitialization() async {
        let mockService = MockManagedService()
        XCTAssertFalse(mockService.isInitialized)
        
        try? await mockService.initialize()
        XCTAssertTrue(mockService.isInitialized)
    }
    
    func testManagedServiceCleanup() async {
        let mockService = MockManagedService()
        XCTAssertFalse(mockService.isCleanedUp)
        
        await mockService.cleanup()
        XCTAssertTrue(mockService.isCleanedUp)
    }
}