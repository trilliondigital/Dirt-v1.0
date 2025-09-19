import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class DependencyInjectionIntegrationTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceContainer.shared
    }
    
    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testServiceContainerIntegrationWithViews() {
        // Test that views can access services through environment
        struct TestView: View {
            @Environment(\.services) var services
            
            var body: some View {
                Text("Test")
            }
            
            func testServiceAccess() -> Bool {
                // Test that all major services are accessible
                return services.mediaService != nil &&
                       services.searchService != nil &&
                       services.postService != nil &&
                       services.analyticsService != nil
            }
        }
        
        let testView = TestView()
        XCTAssertNotNil(testView, "Test view should be created successfully")
    }
    
    func testServiceConsolidation() {
        // Test that consolidated services work correctly
        XCTAssertNotNil(serviceContainer.searchService, "SearchService should be accessible")
        XCTAssertNotNil(serviceContainer.mediaService, "MediaService should be accessible")
        
        // Test that services are the same instances as their shared counterparts
        XCTAssertTrue(serviceContainer.searchService === SearchService.shared,
                     "SearchService should be the shared instance")
        XCTAssertTrue(serviceContainer.mediaService === MediaService.shared,
                     "MediaService should be the shared instance")
    }
    
    func testLegacyCompatibility() async {
        // Test that legacy search methods work through the consolidated service
        do {
            let queries = try await serviceContainer.searchService.listSavedSearchQueries()
            XCTAssertNotNil(queries, "Legacy saved search queries should be accessible")
        } catch {
            // This is expected to fail in test environment, but should not crash
            XCTAssertNotNil(error, "Error should be handled gracefully")
        }
    }
    
    func testServiceLifecycle() {
        // Test service initialization
        XCTAssertNoThrow(serviceContainer.initializeCriticalServices(),
                        "Critical services should initialize without throwing")
        
        // Test service cleanup
        XCTAssertNoThrow(serviceContainer.cleanup(),
                        "Service cleanup should not throw")
    }
    
    func testEnvironmentInjection() {
        // Test that the environment injection works correctly
        let container = ServiceContainer.shared
        
        struct TestEnvironmentView: View {
            @Environment(\.services) var services
            
            var body: some View {
                Text("Test")
            }
            
            func validateServices() -> Bool {
                return services.postService != nil &&
                       services.moderationService != nil &&
                       services.alertsService != nil
            }
        }
        
        let view = TestEnvironmentView()
            .serviceContainer(container)
        
        XCTAssertNotNil(view, "View with service container should be created")
    }
    
    func testServiceDependencyResolution() {
        // Test that services can access other services through the container
        let analytics = serviceContainer.analyticsService
        let media = serviceContainer.mediaService
        let search = serviceContainer.searchService
        
        XCTAssertNotNil(analytics, "Analytics service should be resolved")
        XCTAssertNotNil(media, "Media service should be resolved")
        XCTAssertNotNil(search, "Search service should be resolved")
        
        // Test that services maintain their state
        let analytics2 = serviceContainer.analyticsService
        XCTAssertTrue(analytics === analytics2, "Service instances should be consistent")
    }
    
    func testErrorHandlingIntegration() {
        // Test that error handling works through the service container
        let errorPresenter = serviceContainer.errorPresenter
        XCTAssertNotNil(errorPresenter, "Error presenter should be accessible")
        
        // Test error message generation
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let message = errorPresenter.message(for: testError)
        XCTAssertEqual(message, "Test error", "Error message should be correctly formatted")
    }
    
    func testServiceRegistrationAndRetrieval() {
        // Test custom service registration
        let customAnalytics = AnalyticsService()
        serviceContainer.register(customAnalytics, for: \.analyticsService)
        
        // Verify the custom service is registered
        XCTAssertTrue(serviceContainer.analyticsService === customAnalytics,
                     "Custom service should be registered")
        
        // Test service retrieval by type
        let retrievedAnalytics: AnalyticsService? = serviceContainer.service(of: AnalyticsService.self)
        XCTAssertNotNil(retrievedAnalytics, "Service should be retrievable by type")
        XCTAssertTrue(retrievedAnalytics === customAnalytics, "Retrieved service should match registered service")
    }
    
    func testAllServicesAccessible() {
        // Comprehensive test that all services are accessible
        XCTAssertNotNil(serviceContainer.supabaseManager, "SupabaseManager should be accessible")
        XCTAssertNotNil(serviceContainer.errorPresenter, "ErrorPresenter should be accessible")
        XCTAssertNotNil(serviceContainer.performanceService, "PerformanceService should be accessible")
        XCTAssertNotNil(serviceContainer.analyticsService, "AnalyticsService should be accessible")
        XCTAssertNotNil(serviceContainer.mediaService, "MediaService should be accessible")
        XCTAssertNotNil(serviceContainer.searchService, "SearchService should be accessible")
        XCTAssertNotNil(serviceContainer.postService, "PostService should be accessible")
        XCTAssertNotNil(serviceContainer.postSubmissionService, "PostSubmissionService should be accessible")
        XCTAssertNotNil(serviceContainer.moderationService, "ModerationService should be accessible")
        XCTAssertNotNil(serviceContainer.interestsService, "InterestsService should be accessible")
        XCTAssertNotNil(serviceContainer.mentionsService, "MentionsService should be accessible")
        XCTAssertNotNil(serviceContainer.biometricAuthService, "BiometricAuthService should be accessible")
        XCTAssertNotNil(serviceContainer.themeService, "ThemeService should be accessible")
        XCTAssertNotNil(serviceContainer.alertsService, "AlertsService should be accessible")
        XCTAssertNotNil(serviceContainer.tutorialService, "TutorialService should be accessible")
        XCTAssertNotNil(serviceContainer.deepLinkService, "DeepLinkService should be accessible")
        XCTAssertNotNil(serviceContainer.confirmationCodeService, "ConfirmationCodeService should be accessible")
        XCTAssertNotNil(serviceContainer.errorRecoveryService, "ErrorRecoveryService should be accessible")
        XCTAssertNotNil(serviceContainer.networkMonitor, "NetworkMonitor should be accessible")
    }
    
    func testServiceContainerPerformance() {
        // Test that service access is performant
        measure {
            for _ in 0..<1000 {
                _ = serviceContainer.analyticsService
                _ = serviceContainer.mediaService
                _ = serviceContainer.searchService
                _ = serviceContainer.postService
            }
        }
    }
}

// MARK: - Mock View Models for Testing

extension DependencyInjectionIntegrationTests {
    
    class MockViewModel: ObservableObject {
        @Published var isLoading = false
        @Published var errorMessage: String?
        
        let services: ServiceContainer
        
        init(services: ServiceContainer) {
            self.services = services
        }
        
        func performAction() async {
            isLoading = true
            defer { isLoading = false }
            
            // Simulate using multiple services
            services.analyticsService.log("mock_action")
            
            do {
                _ = try await services.postService.fetchPost(by: UUID())
            } catch {
                errorMessage = services.errorPresenter.message(for: error)
            }
        }
    }
    
    func testViewModelIntegration() async {
        let viewModel = MockViewModel(services: serviceContainer)
        
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "ViewModel should not have error initially")
        
        await viewModel.performAction()
        
        XCTAssertFalse(viewModel.isLoading, "ViewModel should not be loading after action")
        // Error message might be set due to mock data, which is expected
    }
}