# Feature Development Guide

This guide provides step-by-step instructions for adding new features to the Dirt iOS app while maintaining architectural consistency and following established patterns.

## Table of Contents

- [Overview](#overview)
- [Development Workflow](#development-workflow)
- [Architecture Patterns](#architecture-patterns)
- [Implementation Guidelines](#implementation-guidelines)
- [Testing Requirements](#testing-requirements)
- [Code Review Process](#code-review-process)
- [Common Patterns](#common-patterns)

## Overview

### Architectural Principles

The Dirt iOS app follows these core architectural principles:

1. **Service-Oriented Architecture**: Business logic lives in services, accessed through dependency injection
2. **Material Glass Design System**: All UI components use the established Material Glass patterns
3. **Feature Module Boundaries**: Features are self-contained with minimal cross-dependencies
4. **Testability First**: All components are designed for comprehensive testing
5. **Accessibility by Default**: All features must meet accessibility standards

### Required Reading

Before starting feature development, review:
- [Architecture Decision Records](architecture/README.md)
- [Coding Standards](CODING_STANDARDS.md)
- [Development Roadmap](DEVELOPMENT_ROADMAP.md)
- [Material Glass Design System](../Dirt/Dirt/Core/Design/README.md)

## Development Workflow

### 1. Feature Planning

#### Create Feature Specification
```markdown
# Feature: [Feature Name]

## Overview
Brief description of the feature and its purpose.

## Requirements
- Functional requirements
- Non-functional requirements (performance, accessibility, etc.)
- Integration requirements

## User Stories
- As a [user type], I want [functionality] so that [benefit]

## Technical Design
- Service layer design
- Data model design
- UI component structure
- Integration points

## Testing Strategy
- Unit test coverage
- Integration test scenarios
- UI test requirements
- Accessibility test plan

## Success Criteria
- Measurable success metrics
- Performance benchmarks
- User experience goals
```

#### Architecture Review
- Present feature specification to architecture team
- Review service interfaces and dependencies
- Validate Material Glass component usage
- Confirm testing strategy

### 2. Service Layer Implementation

#### Define Service Protocol
```swift
// Location: Features/[FeatureName]/Services/[FeatureName]ServiceProtocol.swift
import Foundation

protocol NewFeatureServiceProtocol {
    /// Primary feature operation
    /// - Parameter input: The input data for the operation
    /// - Returns: The result of the operation
    /// - Throws: FeatureError if operation fails
    func performPrimaryOperation(_ input: FeatureInput) async throws -> FeatureResult
    
    /// Secondary feature operation
    func performSecondaryOperation() async throws -> SecondaryResult
}
```

#### Implement Service
```swift
// Location: Features/[FeatureName]/Services/[FeatureName]Service.swift
import Foundation
import Core

class NewFeatureService: NewFeatureServiceProtocol {
    
    // MARK: - Dependencies
    private let networkService: NetworkService
    private let cacheService: CacheService
    private let analyticsService: AnalyticsService
    
    // MARK: - Initialization
    init(
        networkService: NetworkService,
        cacheService: CacheService,
        analyticsService: AnalyticsService
    ) {
        self.networkService = networkService
        self.cacheService = cacheService
        self.analyticsService = analyticsService
    }
    
    // MARK: - Protocol Implementation
    func performPrimaryOperation(_ input: FeatureInput) async throws -> FeatureResult {
        // Track analytics
        analyticsService.track(.featureOperationStarted)
        
        do {
            // Validate input
            try input.validate()
            
            // Check cache first
            if let cached = await cacheService.get(key: input.cacheKey) {
                return cached
            }
            
            // Perform network operation
            let result = try await networkService.performOperation(input)
            
            // Cache result
            await cacheService.set(key: input.cacheKey, value: result)
            
            // Track success
            analyticsService.track(.featureOperationCompleted)
            
            return result
            
        } catch {
            // Track error
            analyticsService.track(.featureOperationFailed, error: error)
            throw FeatureError.operationFailed(error)
        }
    }
}
```

#### Register Service in Container
```swift
// Location: Dirt/Dirt/Core/Services/ServiceContainer.swift
extension ServiceContainer {
    var newFeatureService: NewFeatureService {
        service(\.newFeatureService) {
            NewFeatureService(
                networkService: networkService,
                cacheService: cacheService,
                analyticsService: analyticsService
            )
        }
    }
}

// Add to ServiceContainerKey
extension ServiceContainerKey {
    static let newFeatureService = ServiceKey<NewFeatureService>()
}
```

### 3. Data Model Implementation

#### Define Models
```swift
// Location: Features/[FeatureName]/Models/[FeatureName]Models.swift
import Foundation

// MARK: - Input Models
struct FeatureInput: Codable {
    let id: String
    let parameters: [String: String]
    
    var cacheKey: String {
        "feature_\(id)_\(parameters.hashValue)"
    }
    
    func validate() throws {
        guard !id.isEmpty else {
            throw FeatureError.invalidInput("ID cannot be empty")
        }
        
        // Additional validation logic
    }
}

// MARK: - Result Models
struct FeatureResult: Codable, Identifiable {
    let id: String
    let data: FeatureData
    let timestamp: Date
    
    init(id: String, data: FeatureData) {
        self.id = id
        self.data = data
        self.timestamp = Date()
    }
}

struct FeatureData: Codable {
    let title: String
    let content: String
    let metadata: [String: String]
}

// MARK: - Error Types
enum FeatureError: LocalizedError {
    case invalidInput(String)
    case operationFailed(Error)
    case networkError
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .operationFailed(let error):
            return "Operation failed: \(error.localizedDescription)"
        case .networkError:
            return "Network operation failed"
        case .cacheError:
            return "Cache operation failed"
        }
    }
}
```

### 4. View Model Implementation

#### Create View Model
```swift
// Location: Features/[FeatureName]/ViewModels/[FeatureName]ViewModel.swift
import SwiftUI
import Combine
import Core

@MainActor
class NewFeatureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var results: [FeatureResult] = []
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    
    // MARK: - Dependencies
    private let service: NewFeatureServiceProtocol
    private let errorPresenter: ErrorPresenter
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        service: NewFeatureServiceProtocol,
        errorPresenter: ErrorPresenter = .shared
    ) {
        self.service = service
        self.errorPresenter = errorPresenter
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        Task {
            await performOperation()
        }
    }
    
    func refresh() {
        Task {
            await performOperation()
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Debounce search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.performSearch()
            }
            .store(in: &cancellables)
    }
    
    private func performOperation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let input = FeatureInput(
                id: UUID().uuidString,
                parameters: ["query": searchQuery]
            )
            
            let result = try await service.performPrimaryOperation(input)
            results = [result]
            
        } catch {
            errorMessage = errorPresenter.message(for: error)
        }
        
        isLoading = false
    }
}
```

### 5. UI Implementation

#### Create Main View
```swift
// Location: Features/[FeatureName]/Views/[FeatureName]View.swift
import SwiftUI
import Core

struct NewFeatureView: View {
    
    // MARK: - Environment
    @Environment(\.services) var services
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @StateObject private var viewModel: NewFeatureViewModel
    @State private var showingDetail = false
    @State private var selectedResult: FeatureResult?
    
    // MARK: - Initialization
    init() {
        // Initialize with environment services in body
        self._viewModel = StateObject(wrappedValue: NewFeatureViewModel(
            service: ServiceContainer.shared.newFeatureService
        ))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            GlassCard {
                VStack(spacing: 16) {
                    SearchSection()
                    ResultsSection()
                }
                .padding()
            }
            .navigationTitle("New Feature")
            .navigationBarTitleDisplayMode(.large)
            .materialGlassBackground()
            .searchable(text: $viewModel.searchQuery)
            .refreshable {
                viewModel.refresh()
            }
            .sheet(isPresented: $showingDetail) {
                if let result = selectedResult {
                    FeatureDetailView(result: result)
                }
            }
        }
        .onAppear {
            // Update view model with environment services
            viewModel.updateServices(services)
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private func SearchSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search")
                .font(.materialHeadline)
                .foregroundColor(.primary)
            
            GlassTextField(
                "Enter search query",
                text: $viewModel.searchQuery
            )
            .onSubmit {
                viewModel.performSearch()
            }
        }
    }
    
    @ViewBuilder
    private func ResultsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Results")
                .font(.materialHeadline)
                .foregroundColor(.primary)
            
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.results.isEmpty {
                EmptyStateView()
            } else {
                ResultsList()
            }
        }
    }
    
    @ViewBuilder
    private func ResultsList() -> some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.results) { result in
                FeatureResultCard(result: result) {
                    selectedResult = result
                    showingDetail = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func LoadingView() -> some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No results found")
                .font(.materialTitle2)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search query")
                .font(.materialBody)
                .foregroundColor(.tertiary)
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct FeatureResultCard: View {
    let result: FeatureResult
    let onTap: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(result.data.title)
                    .font(.materialHeadline)
                    .foregroundColor(.primary)
                
                Text(result.data.content)
                    .font(.materialBody)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Spacer()
                    Text(result.timestamp.formatted(.relative(presentation: .named)))
                        .font(.materialCaption)
                        .foregroundColor(.tertiary)
                }
            }
            .padding()
        }
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(result.data.title). \(result.data.content)")
    }
}
```

#### Create Detail View
```swift
// Location: Features/[FeatureName]/Views/FeatureDetailView.swift
import SwiftUI
import Core

struct FeatureDetailView: View {
    let result: FeatureResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HeaderSection()
                        ContentSection()
                        MetadataSection()
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .materialGlassBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    GlassButton("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func HeaderSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.data.title)
                .font(.materialLargeTitle)
                .foregroundColor(.primary)
            
            Text(result.timestamp.formatted(.dateTime))
                .font(.materialCaption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func ContentSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.materialHeadline)
                .foregroundColor(.primary)
            
            Text(result.data.content)
                .font(.materialBody)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func MetadataSection() -> some View {
        if !result.data.metadata.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Metadata")
                    .font(.materialHeadline)
                    .foregroundColor(.primary)
                
                ForEach(Array(result.data.metadata.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.materialCaption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(result.data.metadata[key] ?? "")
                            .font(.materialCaption)
                            .foregroundColor(.tertiary)
                    }
                }
            }
        }
    }
}
```

### 6. Testing Implementation

#### Service Tests
```swift
// Location: Features/[FeatureName]/Tests/[FeatureName]ServiceTests.swift
import XCTest
@testable import Dirt

class NewFeatureServiceTests: XCTestCase {
    
    var sut: NewFeatureService!
    var mockNetworkService: MockNetworkService!
    var mockCacheService: MockCacheService!
    var mockAnalyticsService: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockCacheService = MockCacheService()
        mockAnalyticsService = MockAnalyticsService()
        
        sut = NewFeatureService(
            networkService: mockNetworkService,
            cacheService: mockCacheService,
            analyticsService: mockAnalyticsService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockCacheService = nil
        mockAnalyticsService = nil
        super.tearDown()
    }
    
    func testPerformPrimaryOperation_WhenValidInput_ReturnsExpectedResult() async throws {
        // Given
        let input = FeatureInput(id: "test", parameters: ["key": "value"])
        let expectedResult = FeatureResult(
            id: "test",
            data: FeatureData(title: "Test", content: "Content", metadata: [:])
        )
        mockNetworkService.mockResult = expectedResult
        
        // When
        let result = try await sut.performPrimaryOperation(input)
        
        // Then
        XCTAssertEqual(result.id, expectedResult.id)
        XCTAssertEqual(result.data.title, expectedResult.data.title)
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains(.featureOperationStarted))
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains(.featureOperationCompleted))
    }
    
    func testPerformPrimaryOperation_WhenNetworkError_ThrowsFeatureError() async {
        // Given
        let input = FeatureInput(id: "test", parameters: [:])
        mockNetworkService.shouldThrowError = true
        
        // When/Then
        do {
            _ = try await sut.performPrimaryOperation(input)
            XCTFail("Expected error to be thrown")
        } catch let error as FeatureError {
            XCTAssertEqual(error, .operationFailed(MockNetworkService.TestError.networkError))
            XCTAssertTrue(mockAnalyticsService.trackedEvents.contains(.featureOperationFailed))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testPerformPrimaryOperation_WhenCachedDataExists_ReturnsCachedResult() async throws {
        // Given
        let input = FeatureInput(id: "test", parameters: [:])
        let cachedResult = FeatureResult(
            id: "cached",
            data: FeatureData(title: "Cached", content: "Content", metadata: [:])
        )
        mockCacheService.mockCachedResult = cachedResult
        
        // When
        let result = try await sut.performPrimaryOperation(input)
        
        // Then
        XCTAssertEqual(result.id, cachedResult.id)
        XCTAssertFalse(mockNetworkService.performOperationCalled)
    }
}

// MARK: - Mock Services
class MockNetworkService: NetworkService {
    var mockResult: FeatureResult?
    var shouldThrowError = false
    var performOperationCalled = false
    
    enum TestError: Error {
        case networkError
    }
    
    func performOperation(_ input: FeatureInput) async throws -> FeatureResult {
        performOperationCalled = true
        
        if shouldThrowError {
            throw TestError.networkError
        }
        
        return mockResult ?? FeatureResult(
            id: "default",
            data: FeatureData(title: "Default", content: "Content", metadata: [:])
        )
    }
}

class MockCacheService: CacheService {
    var mockCachedResult: FeatureResult?
    
    func get(key: String) async -> FeatureResult? {
        return mockCachedResult
    }
    
    func set(key: String, value: FeatureResult) async {
        // Mock implementation
    }
}

class MockAnalyticsService: AnalyticsService {
    var trackedEvents: [AnalyticsEvent] = []
    
    func track(_ event: AnalyticsEvent, error: Error? = nil) {
        trackedEvents.append(event)
    }
}
```

#### View Model Tests
```swift
// Location: Features/[FeatureName]/Tests/[FeatureName]ViewModelTests.swift
import XCTest
@testable import Dirt

@MainActor
class NewFeatureViewModelTests: XCTestCase {
    
    var sut: NewFeatureViewModel!
    var mockService: MockNewFeatureService!
    var mockErrorPresenter: MockErrorPresenter!
    
    override func setUp() {
        super.setUp()
        mockService = MockNewFeatureService()
        mockErrorPresenter = MockErrorPresenter()
        
        sut = NewFeatureViewModel(
            service: mockService,
            errorPresenter: mockErrorPresenter
        )
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        mockErrorPresenter = nil
        super.tearDown()
    }
    
    func testPerformSearch_WhenValidQuery_UpdatesResults() async {
        // Given
        sut.searchQuery = "test query"
        let expectedResult = FeatureResult(
            id: "test",
            data: FeatureData(title: "Test", content: "Content", metadata: [:])
        )
        mockService.mockResult = expectedResult
        
        // When
        sut.performSearch()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(sut.results.count, 1)
        XCTAssertEqual(sut.results.first?.id, expectedResult.id)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testPerformSearch_WhenServiceThrowsError_UpdatesErrorMessage() async {
        // Given
        sut.searchQuery = "test query"
        mockService.shouldThrowError = true
        mockErrorPresenter.mockMessage = "Test error message"
        
        // When
        sut.performSearch()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(sut.results.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Test error message")
    }
    
    func testSearchQuery_WhenChanged_TriggersSearch() async {
        // Given
        let expectedResult = FeatureResult(
            id: "test",
            data: FeatureData(title: "Test", content: "Content", metadata: [:])
        )
        mockService.mockResult = expectedResult
        
        // When
        sut.searchQuery = "new query"
        
        // Wait for debounce and async operation
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        // Then
        XCTAssertTrue(mockService.performPrimaryOperationCalled)
        XCTAssertEqual(sut.results.count, 1)
    }
}

// MARK: - Mock Services
class MockNewFeatureService: NewFeatureServiceProtocol {
    var mockResult: FeatureResult?
    var shouldThrowError = false
    var performPrimaryOperationCalled = false
    
    func performPrimaryOperation(_ input: FeatureInput) async throws -> FeatureResult {
        performPrimaryOperationCalled = true
        
        if shouldThrowError {
            throw FeatureError.networkError
        }
        
        return mockResult ?? FeatureResult(
            id: "default",
            data: FeatureData(title: "Default", content: "Content", metadata: [:])
        )
    }
    
    func performSecondaryOperation() async throws -> SecondaryResult {
        return SecondaryResult()
    }
}

class MockErrorPresenter: ErrorPresenter {
    var mockMessage = "Default error message"
    
    override func message(for error: Error) -> String {
        return mockMessage
    }
}
```

#### UI Tests
```swift
// Location: Features/[FeatureName]/Tests/[FeatureName]UITests.swift
import XCTest
@testable import Dirt

class NewFeatureUITests: XCTestCase {
    
    func testNewFeatureView_WhenRendered_DisplaysCorrectElements() {
        // Given
        let view = NewFeatureView()
        
        // When
        let hostingController = UIHostingController(rootView: view)
        
        // Then
        XCTAssertNotNil(hostingController.view)
        // Additional UI testing logic
    }
    
    func testFeatureResultCard_WhenTapped_CallsOnTapHandler() {
        // Given
        var tapCalled = false
        let result = FeatureResult(
            id: "test",
            data: FeatureData(title: "Test", content: "Content", metadata: [:])
        )
        let card = FeatureResultCard(result: result) {
            tapCalled = true
        }
        
        // When
        // Simulate tap gesture
        
        // Then
        XCTAssertTrue(tapCalled)
    }
}
```

## Architecture Patterns

### Service Layer Patterns

#### Dependency Injection
```swift
// Always use protocol-based dependency injection
protocol FeatureServiceProtocol {
    func performOperation() async throws -> Result
}

class FeatureService: FeatureServiceProtocol {
    private let dependency: DependencyProtocol
    
    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }
}
```

#### Error Handling
```swift
// Use consistent error handling patterns
enum FeatureError: LocalizedError {
    case invalidInput(String)
    case operationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .operationFailed(let error):
            return "Operation failed: \(error.localizedDescription)"
        }
    }
}
```

#### Async/Await Usage
```swift
// Use async/await for asynchronous operations
func performAsyncOperation() async throws -> Result {
    // Use async/await instead of completion handlers
    let data = try await networkService.fetchData()
    return processData(data)
}
```

### UI Patterns

#### Material Glass Components
```swift
// Always use Material Glass components for UI
struct FeatureView: View {
    var body: some View {
        GlassCard {
            // Content
        }
        .materialGlassBackground()
    }
}
```

#### State Management
```swift
// Use appropriate state management patterns
@StateObject private var viewModel = FeatureViewModel()
@State private var isPresented = false
@Environment(\.services) var services
```

#### Navigation
```swift
// Use centralized navigation patterns
@EnvironmentObject var coordinator: NavigationCoordinator

Button("Navigate") {
    coordinator.navigate(to: .featureDetail(id: "123"))
}
```

## Implementation Guidelines

### File Organization

```
Features/[FeatureName]/
├── Views/
│   ├── [FeatureName]View.swift
│   ├── [FeatureName]DetailView.swift
│   └── Components/
│       ├── [FeatureName]Card.swift
│       └── [FeatureName]List.swift
├── ViewModels/
│   └── [FeatureName]ViewModel.swift
├── Services/
│   ├── [FeatureName]ServiceProtocol.swift
│   └── [FeatureName]Service.swift
├── Models/
│   └── [FeatureName]Models.swift
└── Tests/
    ├── [FeatureName]ServiceTests.swift
    ├── [FeatureName]ViewModelTests.swift
    └── [FeatureName]UITests.swift
```

### Naming Conventions

#### Files
- Views: `[FeatureName]View.swift`
- ViewModels: `[FeatureName]ViewModel.swift`
- Services: `[FeatureName]Service.swift`
- Models: `[FeatureName]Models.swift`
- Tests: `[FeatureName][ComponentType]Tests.swift`

#### Classes and Structs
- Use descriptive names that indicate purpose
- Follow Swift naming conventions (PascalCase for types)
- Include feature name in type names for clarity

#### Methods and Properties
- Use camelCase for methods and properties
- Use descriptive names that indicate functionality
- Avoid abbreviations unless they're well-known

### Code Quality Standards

#### Documentation
```swift
/// Service for managing feature operations
///
/// This service handles all business logic related to the feature,
/// including data validation, network operations, and caching.
class FeatureService {
    
    /// Performs the primary feature operation
    /// - Parameter input: The input data for the operation
    /// - Returns: The result of the operation
    /// - Throws: FeatureError if the operation fails
    func performOperation(_ input: FeatureInput) async throws -> FeatureResult {
        // Implementation
    }
}
```

#### Error Handling
```swift
// Always handle errors appropriately
do {
    let result = try await service.performOperation(input)
    // Handle success
} catch let error as FeatureError {
    // Handle specific feature errors
    errorPresenter.present(error)
} catch {
    // Handle unexpected errors
    errorPresenter.present(FeatureError.unexpectedError(error))
}
```

#### Performance Considerations
```swift
// Use lazy loading for expensive operations
lazy var expensiveResource: ExpensiveResource = {
    return ExpensiveResource()
}()

// Use proper memory management
private var cancellables = Set<AnyCancellable>()

deinit {
    cancellables.removeAll()
}
```

## Testing Requirements

### Test Coverage Requirements

- **Service Layer**: 90%+ code coverage
- **View Models**: 85%+ code coverage
- **UI Components**: Key user interactions tested
- **Integration**: Critical user flows tested end-to-end

### Test Types

#### Unit Tests
- Test individual components in isolation
- Mock all dependencies
- Test both success and failure scenarios
- Test edge cases and boundary conditions

#### Integration Tests
- Test component interactions
- Test service integrations
- Test data flow between layers
- Test error propagation

#### UI Tests
- Test user interactions
- Test accessibility compliance
- Test Material Glass component rendering
- Test navigation flows

### Test Organization

```swift
class FeatureServiceTests: XCTestCase {
    // MARK: - Properties
    var sut: FeatureService!
    var mockDependency: MockDependency!
    
    // MARK: - Setup/Teardown
    override func setUp() {
        super.setUp()
        // Setup test objects
    }
    
    override func tearDown() {
        // Cleanup test objects
        super.tearDown()
    }
    
    // MARK: - Success Tests
    func testOperation_WhenValidInput_ReturnsExpectedResult() {
        // Test implementation
    }
    
    // MARK: - Error Tests
    func testOperation_WhenInvalidInput_ThrowsExpectedError() {
        // Test implementation
    }
    
    // MARK: - Edge Case Tests
    func testOperation_WhenEdgeCase_HandlesCorrectly() {
        // Test implementation
    }
}
```

## Code Review Process

### Review Checklist

#### Architecture Compliance
- [ ] Follows established service patterns
- [ ] Uses Material Glass design system
- [ ] Respects feature module boundaries
- [ ] Implements proper dependency injection
- [ ] Uses centralized navigation

#### Code Quality
- [ ] Follows coding standards
- [ ] Has comprehensive documentation
- [ ] Includes appropriate tests
- [ ] Handles errors properly
- [ ] Optimizes performance

#### User Experience
- [ ] Meets accessibility requirements
- [ ] Supports Dark Mode
- [ ] Follows Apple HIG guidelines
- [ ] Provides good user feedback
- [ ] Handles loading states

#### Security
- [ ] Validates input properly
- [ ] Handles sensitive data securely
- [ ] Follows security best practices
- [ ] No security vulnerabilities

### Review Process

1. **Self Review**: Developer reviews their own code
2. **Peer Review**: Another developer reviews the code
3. **Architecture Review**: Architecture team reviews for compliance
4. **Testing Review**: QA team reviews test coverage
5. **Final Approval**: Lead developer approves for merge

## Common Patterns

### Service Integration Pattern

```swift
// Standard service integration pattern
struct FeatureView: View {
    @Environment(\.services) var services
    @StateObject private var viewModel: FeatureViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: FeatureViewModel())
    }
    
    var body: some View {
        // View implementation
        .onAppear {
            viewModel.configure(with: services.featureService)
        }
    }
}
```

### Error Presentation Pattern

```swift
// Standard error presentation pattern
class FeatureViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    private let errorPresenter: ErrorPresenter
    
    private func handleError(_ error: Error) {
        errorMessage = errorPresenter.message(for: error)
    }
}
```

### Loading State Pattern

```swift
// Standard loading state pattern
class FeatureViewModel: ObservableObject {
    @Published var isLoading = false
    
    func performOperation() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Perform operation
        } catch {
            // Handle error
        }
    }
}
```

### Material Glass Usage Pattern

```swift
// Standard Material Glass usage pattern
struct FeatureCard: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Card content
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
    }
}
```

---

*This guide should be updated as new patterns emerge and the architecture evolves.*