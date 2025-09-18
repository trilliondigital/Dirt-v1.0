import Foundation
import SwiftUI
import Combine

/// Central service container for dependency injection throughout the app
/// Provides lazy-loaded service instances and manages service lifecycle
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // Track service initialization for performance monitoring
    private var serviceInitializationTimes: [String: TimeInterval] = [:]
    private var initializedServices: Set<String> = []
    
    private init() {}
    
    // MARK: - Core Services
    
    /// Supabase database and authentication manager
    lazy var supabaseManager: SupabaseManager = {
        trackServiceInitialization("SupabaseManager")
        return SupabaseManager.shared
    }()
    
    /// Error handling and presentation service
    lazy var errorPresenter: ErrorPresenter.Type = {
        trackServiceInitialization("ErrorPresenter")
        return ErrorPresenter.self
    }()
    
    /// Performance monitoring and caching
    lazy var performanceService: PerformanceCacheService = {
        trackServiceInitialization("PerformanceCacheService")
        return PerformanceCacheService.shared
    }()
    
    /// Performance optimization for Material Glass components
    lazy var performanceOptimizationService: PerformanceOptimizationService = {
        trackServiceInitialization("PerformanceOptimizationService")
        return PerformanceOptimizationService.shared
    }()
    
    /// Analytics and user behavior tracking
    lazy var analyticsService: AnalyticsService = {
        trackServiceInitialization("AnalyticsService")
        return AnalyticsService()
    }()
    
    // MARK: - Media Services
    
    /// Media upload and processing service (consolidated from EnhancedMediaService)
    lazy var mediaService: MediaService = {
        trackServiceInitialization("MediaService")
        return MediaService.shared
    }()
    
    // MARK: - Search Services
    
    /// Search functionality with filtering and caching (consolidated from EnhancedSearchService)
    lazy var searchService: SearchService = {
        trackServiceInitialization("SearchService")
        return SearchService.shared
    }()
    
    // MARK: - Content Services
    
    /// Post creation, editing, and management
    lazy var postService = PostService.shared
    
    /// Post submission and validation
    lazy var postSubmissionService = PostSubmissionService.shared
    
    /// Content moderation and safety
    lazy var moderationService = ModerationService.shared
    
    // MARK: - User Services
    
    /// User interests and preferences
    lazy var interestsService = InterestsService.shared
    
    /// User mentions and notifications
    lazy var mentionsService = MentionsService.shared
    
    /// Biometric authentication
    lazy var biometricAuthService = BiometricAuthService.shared
    
    // MARK: - UI Services
    
    /// Theme and appearance management
    lazy var themeService = ThemeService.shared
    
    /// Alert and notification presentation
    lazy var alertsService = AlertsService.shared
    
    /// Tutorial and onboarding flows
    lazy var tutorialService = TutorialService.shared
    
    // MARK: - Utility Services
    
    /// Deep link handling and navigation
    lazy var deepLinkService = DeepLinkService.shared
    
    /// Confirmation code generation and validation
    lazy var confirmationCodeService = ConfirmationCodeService()
    
    /// Error recovery service
    lazy var errorRecoveryService = ErrorRecoveryService.shared
    
    /// Network monitoring
    lazy var networkMonitor = NetworkMonitor.shared
    
    // MARK: - Service Registration
    
    /// Register a custom service instance
    /// - Parameters:
    ///   - service: The service instance to register
    ///   - keyPath: The key path to the service property
    func register<T>(_ service: T, for keyPath: WritableKeyPath<ServiceContainer, T>) {
        self[keyPath: keyPath] = service
    }
    
    /// Get a service instance by type
    /// - Parameter type: The service type to retrieve
    /// - Returns: The service instance if available
    func service<T>(of type: T.Type) -> T? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let service = child.value as? T {
                return service
            }
        }
        return nil
    }
    
    // MARK: - Lifecycle Management
    
    /// Initialize all critical services
    func initializeCriticalServices() {
        // Initialize services that need early setup
        _ = supabaseManager
        _ = errorPresenter
        _ = performanceService
        _ = performanceOptimizationService
        _ = analyticsService
    }
    
    /// Cleanup resources when app terminates
    func cleanup() {
        // Perform any necessary cleanup
        // Services should handle their own cleanup in deinit
    }
    
    // MARK: - Performance Tracking
    
    /// Track service initialization time for performance monitoring
    private func trackServiceInitialization(_ serviceName: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Mark as initialized
        initializedServices.insert(serviceName)
        
        // Record initialization time (this will be updated when service is actually created)
        DispatchQueue.main.async {
            let endTime = CFAbsoluteTimeGetCurrent()
            self.serviceInitializationTimes[serviceName] = endTime - startTime
        }
    }
    
    /// Get service initialization metrics
    func getServiceInitializationMetrics() -> [String: TimeInterval] {
        return serviceInitializationTimes
    }
    
    /// Get list of initialized services
    func getInitializedServices() -> Set<String> {
        return initializedServices
    }
    
    /// Get total initialization time for all services
    func getTotalInitializationTime() -> TimeInterval {
        return serviceInitializationTimes.values.reduce(0, +)
    }
}

// MARK: - Environment Key

/// Environment key for injecting the service container
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    /// Access the service container from the environment
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inject the service container into the environment
    /// - Parameter container: The service container to inject
    /// - Returns: A view with the service container in its environment
    func serviceContainer(_ container: ServiceContainer = .shared) -> some View {
        environment(\.services, container)
    }
}

// MARK: - Service Protocol

/// Protocol for services that need lifecycle management
protocol ManagedService {
    /// Initialize the service
    func initialize() async throws
    
    /// Cleanup service resources
    func cleanup() async
}

// MARK: - Service Container Extensions

extension ServiceContainer {
    /// Initialize all managed services
    func initializeManagedServices() async {
        let managedServices = getAllManagedServices()
        
        await withTaskGroup(of: Void.self) { group in
            for service in managedServices {
                group.addTask {
                    do {
                        try await service.initialize()
                    } catch {
                        print("Failed to initialize service: \(error)")
                    }
                }
            }
        }
    }
    
    /// Cleanup all managed services
    func cleanupManagedServices() async {
        let managedServices = getAllManagedServices()
        
        await withTaskGroup(of: Void.self) { group in
            for service in managedServices {
                group.addTask {
                    await service.cleanup()
                }
            }
        }
    }
    
    private func getAllManagedServices() -> [ManagedService] {
        let mirror = Mirror(reflecting: self)
        var services: [ManagedService] = []
        
        for child in mirror.children {
            if let service = child.value as? ManagedService {
                services.append(service)
            }
        }
        
        return services
    }
}

// MARK: - Service Factory

/// Factory for creating service instances with proper configuration
struct ServiceFactory {
    /// Create a configured service container
    /// - Parameter configuration: Optional configuration closure
    /// - Returns: Configured service container
    static func createContainer(
        configuration: ((ServiceContainer) -> Void)? = nil
    ) -> ServiceContainer {
        let container = ServiceContainer()
        configuration?(container)
        return container
    }
    
    /// Create a test service container with mock services
    /// - Returns: Service container configured for testing
    static func createTestContainer() -> ServiceContainer {
        let container = ServiceContainer()
        // Configure with test/mock services as needed
        return container
    }
}