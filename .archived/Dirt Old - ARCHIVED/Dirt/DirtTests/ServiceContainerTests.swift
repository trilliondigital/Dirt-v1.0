import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class ServiceContainerTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceFactory.createTestContainer()
    }
    
    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }
    
    // MARK: - Service Container Initialization Tests
    
    func testServiceContainerSingleton() {
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        
        XCTAssertTrue(container1 === container2, "ServiceContainer should be a singleton")
    }
    
    func testServiceContainerInitialization() {
        XCTAssertNotNil(serviceContainer, "ServiceContainer should initialize successfully")
    }
    
    func testCriticalServicesInitialization() {
        // Test that critical services can be initialized without throwing
        XCTAssertNoThrow(serviceContainer.initializeCriticalServices())
        
        // Verify critical services are accessible
        XCTAssertNotNil(serviceContainer.supabaseManager)
        XCTAssertNotNil(serviceContainer.errorPresenter)
        XCTAssertNotNil(serviceContainer.performanceService)
        XCTAssertNotNil(serviceContainer.analyticsService)
    }
    
    // MARK: - Service Access Tests
    
    func testCoreServicesAccess() {
        // Test that all core services are accessible
        XCTAssertNotNil(serviceContainer.supabaseManager)
        XCTAssertNotNil(serviceContainer.errorPresenter)
        XCTAssertNotNil(serviceContainer.performanceService)
        XCTAssertNotNil(serviceContainer.analyticsService)
    }
    
    func testMediaServicesAccess() {
        // Test media services
        XCTAssertNotNil(serviceContainer.mediaService)
        XCTAssertTrue(serviceContainer.mediaService === MediaService.shared, 
                     "MediaService should reference the shared instance")
    }
    
    func testSearchServicesAccess() {
        // Test search services
        XCTAssertNotNil(serviceContainer.searchService)
        XCTAssertTrue(serviceContainer.searchService === SearchService.shared,
                     "SearchService should reference the shared instance")
    }
    
    func testContentServicesAccess() {
        // Test content services
        XCTAssertNotNil(serviceContainer.postService)
        XCTAssertNotNil(serviceContainer.postSubmissionService)
        XCTAssertNotNil(serviceContainer.moderationService)
    }
    
    func testUserServicesAccess() {
        // Test user services
        XCTAssertNotNil(serviceContainer.interestsService)
        XCTAssertNotNil(serviceContainer.mentionsService)
        XCTAssertNotNil(serviceContainer.biometricAuthService)
    }
    
    func testUIServicesAccess() {
        // Test UI services
        XCTAssertNotNil(serviceContainer.themeService)
        XCTAssertNotNil(serviceContainer.alertsService)
        XCTAssertNotNil(serviceContainer.tutorialService)
    }
    
    func testUtilityServicesAccess() {
        // Test utility services
        XCTAssertNotNil(serviceContainer.deepLinkService)
        XCTAssertNotNil(serviceContainer.confirmationCodeService)
        XCTAssertNotNil(serviceContainer.errorRecoveryService)
        XCTAssertNotNil(serviceContainer.networkMonitor)
    }
    
    // MARK: - Service Registration Tests
    
    func testServiceRegistration() {
        // Create a mock service
        let mockAnalyticsService = AnalyticsService()
        
        // Register the mock service
        serviceContainer.register(mockAnalyticsService, for: \.analyticsService)
        
        // Verify the service was registered
        XCTAssertTrue(serviceContainer.analyticsService === mockAnalyticsService,
                     "Registered service should be accessible")
    }
    
    func testServiceByTypeRetrieval() {
        // Test retrieving service by type
        let analyticsService: AnalyticsService? = serviceContainer.service(of: AnalyticsService.self)
        XCTAssertNotNil(analyticsService, "Should be able to retrieve service by type")
        
        let mediaService: MediaService? = serviceContainer.service(of: MediaService.self)
        XCTAssertNotNil(mediaService, "Should be able to retrieve MediaService by type")
        
        // Test retrieving non-existent service type
        let nonExistentService: String? = serviceContainer.service(of: String.self)
        XCTAssertNil(nonExistentService, "Should return nil for non-existent service type")
    }
    
    // MARK: - Environment Integration Tests
    
    func testEnvironmentKeyIntegration() {
        // Test that the environment key works correctly
        let defaultContainer = ServiceContainerKey.defaultValue
        XCTAssertTrue(defaultContainer === ServiceContainer.shared,
                     "Environment key should return shared instance by default")
    }
    
    func testViewExtensionIntegration() {
        // Test that the view extension works
        let testView = Text("Test")
        let viewWithContainer = testView.serviceContainer(serviceContainer)
        
        // This test verifies the extension compiles and returns a view
        XCTAssertNotNil(viewWithContainer, "View extension should return a view")
    }
    
    // MARK: - Service Factory Tests
    
    func testServiceFactoryCreateContainer() {
        let container = ServiceFactory.createContainer()
        XCTAssertNotNil(container, "ServiceFactory should create a container")
        
        // Test with configuration
        var configurationCalled = false
        let configuredContainer = ServiceFactory.createContainer { _ in
            configurationCalled = true
        }
        
        XCTAssertTrue(configurationCalled, "Configuration closure should be called")
        XCTAssertNotNil(configuredContainer, "ServiceFactory should create configured container")
    }
    
    func testServiceFactoryCreateTestContainer() {
        let testContainer = ServiceFactory.createTestContainer()
        XCTAssertNotNil(testContainer, "ServiceFactory should create test container")
    }
    
    // MARK: - Lazy Loading Tests
    
    func testLazyServiceLoading() {
        // Create a fresh container to test lazy loading
        let freshContainer = ServiceContainer()
        
        // Access a service to trigger lazy loading
        let mediaService = freshContainer.mediaService
        XCTAssertNotNil(mediaService, "Lazy-loaded service should be accessible")
        
        // Verify the same instance is returned on subsequent access
        let mediaService2 = freshContainer.mediaService
        XCTAssertTrue(mediaService === mediaService2, "Lazy-loaded service should return same instance")
    }
    
    // MARK: - Cleanup Tests
    
    func testServiceCleanup() {
        // Test that cleanup doesn't throw
        XCTAssertNoThrow(serviceContainer.cleanup(), "Cleanup should not throw")
    }
    
    // MARK: - Integration with SwiftUI Environment Tests
    
    func testSwiftUIEnvironmentIntegration() {
        // Create a test view that uses the services environment
        struct TestView: View {
            @Environment(\.services) var services
            
            var body: some View {
                Text("Test")
            }
            
            func getServices() -> ServiceContainer {
                return services
            }
        }
        
        // This test verifies that the environment integration compiles correctly
        let testView = TestView()
        XCTAssertNotNil(testView, "Test view should be created successfully")
    }
    
    // MARK: - Performance Tests
    
    func testServiceAccessPerformance() {
        measure {
            // Test performance of accessing services multiple times
            for _ in 0..<1000 {
                _ = serviceContainer.mediaService
                _ = serviceContainer.searchService
                _ = serviceContainer.postService
                _ = serviceContainer.analyticsService
            }
        }
    }
    
    func testServiceRegistrationPerformance() {
        measure {
            // Test performance of service registration
            for _ in 0..<100 {
                let mockService = AnalyticsService()
                serviceContainer.register(mockService, for: \.analyticsService)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceContainerErrorHandling() {
        // Test that accessing services doesn't crash even if some services fail to initialize
        XCTAssertNoThrow({
            _ = serviceContainer.supabaseManager
            _ = serviceContainer.errorPresenter
            _ = serviceContainer.mediaService
            _ = serviceContainer.searchService
        }(), "Service access should not throw even if some services fail")
    }
    
    // MARK: - Thread Safety Tests
    
    func testServiceContainerThreadSafety() {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // Test accessing services from multiple threads
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                // Access services from background thread
                _ = self.serviceContainer.mediaService
                _ = self.serviceContainer.searchService
                _ = self.serviceContainer.postService
                
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Services for Testing

extension ServiceContainerTests {
    
    class MockAnalyticsService: AnalyticsService {
        var loggedEvents: [(String, [String: String])] = []
        
        override func log(_ event: String, _ parameters: [String: String] = [:]) {
            loggedEvents.append((event, parameters))
        }
    }
    
    func testMockServiceIntegration() {
        let mockAnalytics = MockAnalyticsService()
        serviceContainer.register(mockAnalytics, for: \.analyticsService)
        
        // Test that the mock service works
        serviceContainer.analyticsService.log("test_event", ["key": "value"])
        
        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1, "Mock service should record logged events")
        XCTAssertEqual(mockAnalytics.loggedEvents.first?.0, "test_event", "Event name should match")
        XCTAssertEqual(mockAnalytics.loggedEvents.first?.1["key"], "value", "Event parameters should match")
    }
}

// MARK: - Managed Service Tests

extension ServiceContainerTests {
    
    class MockManagedService: ManagedService {
        var isInitialized = false
        var isCleanedUp = false
        var initializationError: Error?
        
        func initialize() async throws {
            if let error = initializationError {
                throw error
            }
            isInitialized = true
        }
        
        func cleanup() async {
            isCleanedUp = true
        }
    }
    
    func testManagedServiceLifecycle() async {
        let mockService = MockManagedService()
        
        // Test initialization
        try? await mockService.initialize()
        XCTAssertTrue(mockService.isInitialized, "Service should be initialized")
        
        // Test cleanup
        await mockService.cleanup()
        XCTAssertTrue(mockService.isCleanedUp, "Service should be cleaned up")
    }
    
    func testManagedServiceErrorHandling() async {
        let mockService = MockManagedService()
        mockService.initializationError = NSError(domain: "test", code: 1, userInfo: nil)
        
        // Test that initialization error is handled
        do {
            try await mockService.initialize()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error, "Should catch initialization error")
        }
    }
}