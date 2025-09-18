# Coding Standards and Guidelines

This document outlines the coding standards and guidelines for the Dirt iOS app to ensure consistency, maintainability, and quality across the codebase.

## Table of Contents

- [General Principles](#general-principles)
- [Swift Style Guide](#swift-style-guide)
- [SwiftUI Guidelines](#swiftui-guidelines)
- [Architecture Patterns](#architecture-patterns)
- [Material Glass Design System](#material-glass-design-system)
- [Testing Standards](#testing-standards)
- [Performance Guidelines](#performance-guidelines)
- [Accessibility Requirements](#accessibility-requirements)
- [Security Practices](#security-practices)
- [Documentation Standards](#documentation-standards)

## General Principles

### Code Quality
- **Readability First**: Code should be self-documenting and easy to understand
- **Consistency**: Follow established patterns throughout the codebase
- **Simplicity**: Prefer simple solutions over complex ones
- **Performance**: Write efficient code that respects device resources
- **Security**: Always consider security implications of code changes

### Development Workflow
- **Small Commits**: Make small, focused commits with clear messages
- **Code Review**: All code must be reviewed before merging
- **Testing**: Write tests for new functionality and bug fixes
- **Documentation**: Update documentation when making architectural changes

## Swift Style Guide

### Naming Conventions

#### Variables and Functions
```swift
// Use camelCase for variables and functions
let userName = "john_doe"
let isUserLoggedIn = true

func calculateTotalPrice() -> Double {
    // Implementation
}

// Use descriptive names
let searchResults = performSearch(query: "example")
// Not: let results = search("example")
```

#### Types and Protocols
```swift
// Use PascalCase for types and protocols
struct UserProfile {
    let id: String
    let displayName: String
}

protocol NetworkServiceProtocol {
    func fetchData() async throws -> Data
}

// Use descriptive protocol names
protocol PostServiceProtocol {
    // Not: PostProtocol or ServiceProtocol
}
```

#### Constants
```swift
// Use camelCase for constants
private let maxRetryAttempts = 3
static let defaultTimeout: TimeInterval = 30.0

// Use descriptive names for magic numbers
private let minimumPasswordLength = 8
// Not: private let minLength = 8
```

### Code Organization

#### File Structure
```swift
// 1. Imports
import SwiftUI
import Combine

// 2. Type definitions
struct ContentView: View {
    // 3. Properties (in order of access level)
    @StateObject private var viewModel = ContentViewModel()
    @Environment(\.services) var services
    
    // 4. Computed properties
    var body: some View {
        // Implementation
    }
    
    // 5. Methods (in order of access level)
    private func handleAction() {
        // Implementation
    }
}

// 6. Extensions
extension ContentView {
    // Related functionality
}
```

#### Property Organization
```swift
struct MyView: View {
    // 1. @StateObject and @ObservedObject
    @StateObject private var viewModel = MyViewModel()
    
    // 2. @State properties
    @State private var isLoading = false
    @State private var selectedItem: Item?
    
    // 3. @Environment properties
    @Environment(\.services) var services
    @Environment(\.dismiss) var dismiss
    
    // 4. Regular properties
    let title: String
    let onComplete: () -> Void
    
    // 5. Computed properties
    var body: some View {
        // Implementation
    }
}
```

### Error Handling

#### Use Result Type for Operations
```swift
func performNetworkOperation() async -> Result<Data, NetworkError> {
    do {
        let data = try await networkService.fetchData()
        return .success(data)
    } catch {
        return .failure(NetworkError.from(error))
    }
}
```

#### Proper Error Propagation
```swift
// Use throws for operations that can fail
func validateUserInput(_ input: String) throws -> ValidatedInput {
    guard !input.isEmpty else {
        throw ValidationError.emptyInput
    }
    
    guard input.count >= minimumLength else {
        throw ValidationError.tooShort
    }
    
    return ValidatedInput(input)
}
```

## SwiftUI Guidelines

### View Structure

#### Keep Views Small and Focused
```swift
// Good: Focused view with single responsibility
struct PostCard: View {
    let post: Post
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                PostHeader(post: post)
                PostContent(post: post)
                PostActions(post: post)
            }
        }
    }
}

// Avoid: Large views with multiple responsibilities
```

#### Extract Subviews for Clarity
```swift
struct ComplexView: View {
    var body: some View {
        VStack {
            HeaderSection()
            ContentSection()
            FooterSection()
        }
    }
    
    // Extract complex sections into separate views
    @ViewBuilder
    private func HeaderSection() -> some View {
        // Header implementation
    }
}
```

### State Management

#### Use Appropriate Property Wrappers
```swift
struct MyView: View {
    // Use @StateObject for view-owned objects
    @StateObject private var viewModel = MyViewModel()
    
    // Use @ObservedObject for passed objects
    @ObservedObject var sharedData: SharedDataModel
    
    // Use @State for simple view state
    @State private var isExpanded = false
    
    // Use @Environment for dependency injection
    @Environment(\.services) var services
}
```

#### Minimize State Duplication
```swift
// Good: Single source of truth
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        SearchResults(results: viewModel.results)
            .searchable(text: $viewModel.query)
    }
}

// Avoid: Duplicating state between view and view model
```

### Performance Optimization

#### Use @ViewBuilder Efficiently
```swift
struct ConditionalView: View {
    let showContent: Bool
    
    var body: some View {
        VStack {
            if showContent {
                ExpensiveContentView()
            } else {
                PlaceholderView()
            }
        }
    }
}
```

#### Optimize List Performance
```swift
struct PostList: View {
    let posts: [Post]
    
    var body: some View {
        LazyVStack {
            ForEach(posts) { post in
                PostCard(post: post)
                    .id(post.id) // Stable IDs for performance
            }
        }
    }
}
```

## Architecture Patterns

### Service Usage

#### Access Services Through Container
```swift
struct FeatureView: View {
    @Environment(\.services) var services
    
    var body: some View {
        Text("Content")
            .onAppear {
                services.analyticsService.track(.viewAppeared)
            }
    }
}
```

#### Create Feature-Specific Services When Needed
```swift
class CreatePostService: ObservableObject {
    private let mediaService: MediaService
    private let postService: PostService
    
    init(services: ServiceContainer) {
        self.mediaService = services.mediaService
        self.postService = services.postService
    }
    
    @MainActor
    func createPost(_ content: PostContent) async throws {
        // Feature-specific logic
    }
}
```

### Navigation Patterns

#### Use Centralized Navigation
```swift
struct FeatureView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        Button("Navigate") {
            coordinator.navigate(to: .postDetail(id: "123"))
        }
    }
}
```

### Feature Boundaries

#### Respect Module Boundaries
```swift
// Good: Use shared services
import Core

struct FeatureView: View {
    @Environment(\.services) var services
    // Use services.searchService
}

// Avoid: Direct feature imports
// import OtherFeature // Don't do this
```

## Material Glass Design System

### Component Usage

#### Use Design System Components
```swift
struct MyView: View {
    var body: some View {
        GlassCard {
            VStack {
                Text("Title")
                    .font(.materialTitle)
                
                GlassButton("Action") {
                    // Handle action
                }
            }
        }
    }
}
```

#### Follow Material Glass Hierarchy
```swift
// Use appropriate Material thickness
VStack {
    // Ultra thin for subtle overlays
    Text("Overlay")
        .background(.ultraThinMaterial)
    
    // Regular material for primary surfaces
    GlassCard { // Uses .regularMaterial
        Text("Content")
    }
    
    // Thick material for modals
    Modal { // Uses .thickMaterial
        Text("Modal content")
    }
}
```

### Animation Standards

#### Use Consistent Motion
```swift
struct AnimatedView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            // Use design system animations
            if isExpanded {
                DetailView()
                    .transition(.materialSlide)
            }
        }
        .animation(.materialStandard, value: isExpanded)
    }
}
```

## Testing Standards

### Unit Testing

#### Test Structure
```swift
class MyServiceTests: XCTestCase {
    var sut: MyService!
    var mockDependency: MockDependency!
    
    override func setUp() {
        super.setUp()
        mockDependency = MockDependency()
        sut = MyService(dependency: mockDependency)
    }
    
    override func tearDown() {
        sut = nil
        mockDependency = nil
        super.tearDown()
    }
    
    func testServiceOperation_WhenValidInput_ReturnsExpectedResult() {
        // Given
        let input = "valid input"
        let expectedResult = "expected result"
        mockDependency.setupMockResponse(expectedResult)
        
        // When
        let result = sut.performOperation(input)
        
        // Then
        XCTAssertEqual(result, expectedResult)
    }
}
```

#### Test Naming Convention
```swift
// Pattern: test[MethodName]_When[Condition]_[ExpectedBehavior]
func testValidateEmail_WhenValidEmail_ReturnsTrue() { }
func testValidateEmail_WhenInvalidEmail_ReturnsFalse() { }
func testFetchData_WhenNetworkError_ThrowsNetworkError() { }
```

### UI Testing

#### Material Glass Component Testing
```swift
class MaterialGlassComponentsTests: XCTestCase {
    func testGlassCard_WhenRendered_HasCorrectAccessibility() {
        // Test accessibility compliance
        let card = GlassCard { Text("Content") }
        
        // Verify accessibility properties
        XCTAssertTrue(card.isAccessibilityElement)
        XCTAssertEqual(card.accessibilityLabel, "Content")
    }
}
```

## Performance Guidelines

### Memory Management

#### Use Weak References Appropriately
```swift
class MyService {
    weak var delegate: MyServiceDelegate?
    
    private var cancellables = Set<AnyCancellable>()
    
    func setupObserver() {
        NotificationCenter.default
            .publisher(for: .dataUpdated)
            .sink { [weak self] _ in
                self?.handleUpdate()
            }
            .store(in: &cancellables)
    }
}
```

#### Proper Resource Cleanup
```swift
class ResourceManager {
    private var resources: [Resource] = []
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        resources.forEach { $0.release() }
        resources.removeAll()
    }
}
```

### Network Optimization

#### Use Efficient Data Loading
```swift
class DataService {
    private let cache = NSCache<NSString, CachedData>()
    
    func fetchData(for id: String) async throws -> Data {
        // Check cache first
        if let cached = cache.object(forKey: id as NSString) {
            return cached.data
        }
        
        // Fetch from network
        let data = try await networkService.fetch(id: id)
        cache.setObject(CachedData(data), forKey: id as NSString)
        return data
    }
}
```

## Accessibility Requirements

### VoiceOver Support

#### Provide Descriptive Labels
```swift
struct AccessibleView: View {
    var body: some View {
        Button(action: sharePost) {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share post")
        .accessibilityHint("Shares this post with others")
    }
}
```

#### Group Related Elements
```swift
struct PostCard: View {
    let post: Post
    
    var body: some View {
        VStack {
            Text(post.title)
            Text(post.content)
            PostActions(post: post)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.title). \(post.content)")
    }
}
```

### Dynamic Type Support

#### Use Scalable Fonts
```swift
struct ScalableText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.materialBody) // Uses scalable font
            .lineLimit(nil) // Allow text to wrap
    }
}
```

## Security Practices

### Data Protection

#### Secure Sensitive Data
```swift
class SecureStorage {
    private let keychain = Keychain(service: "com.dirt.app")
    
    func store(token: String) throws {
        try keychain.set(token, key: "auth_token")
    }
    
    func retrieve() throws -> String? {
        return try keychain.get("auth_token")
    }
}
```

#### Validate Input
```swift
func validateUserInput(_ input: String) throws -> String {
    // Sanitize input
    let sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Validate length
    guard sanitized.count <= maxInputLength else {
        throw ValidationError.inputTooLong
    }
    
    // Check for malicious content
    guard !containsMaliciousContent(sanitized) else {
        throw ValidationError.maliciousContent
    }
    
    return sanitized
}
```

## Documentation Standards

### Code Documentation

#### Document Public APIs
```swift
/// Service for managing user authentication and session state.
///
/// This service handles user login, logout, and session management
/// with automatic token refresh and secure storage.
public class AuthService {
    
    /// Authenticates a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Returns: The authenticated user profile
    /// - Throws: `AuthError` if authentication fails
    public func signIn(email: String, password: String) async throws -> UserProfile {
        // Implementation
    }
}
```

#### Use Clear Comments for Complex Logic
```swift
func calculateOptimalCacheSize() -> Int {
    // Calculate cache size based on available memory
    // Use 10% of available memory, with min 10MB and max 100MB
    let availableMemory = ProcessInfo.processInfo.physicalMemory
    let targetSize = Int(Double(availableMemory) * 0.1)
    
    return max(10_000_000, min(targetSize, 100_000_000))
}
```

### README Documentation

#### Include Usage Examples
```markdown
## Usage

### Basic Authentication

```swift
let authService = services.authService

do {
    let user = try await authService.signIn(
        email: "user@example.com",
        password: "securePassword"
    )
    print("Signed in as: \(user.displayName)")
} catch {
    print("Authentication failed: \(error)")
}
```
```

## Code Review Guidelines

### Review Checklist

#### Functionality
- [ ] Code works as intended
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] Performance is acceptable

#### Code Quality
- [ ] Follows coding standards
- [ ] Is well-documented
- [ ] Has appropriate tests
- [ ] Follows architecture patterns

#### Security
- [ ] Input is validated
- [ ] Sensitive data is protected
- [ ] No security vulnerabilities introduced

#### Accessibility
- [ ] VoiceOver support included
- [ ] Dynamic Type supported
- [ ] Proper contrast ratios maintained

## Enforcement

### Automated Checks
- SwiftLint for style consistency
- Unit test coverage requirements
- Accessibility audit in CI
- Performance regression tests

### Manual Review
- Architecture compliance review
- Security review for sensitive changes
- Accessibility review for UI changes
- Documentation review for public APIs

## Continuous Improvement

This document should be updated regularly based on:
- Team feedback and experience
- New Swift/SwiftUI features
- Evolving best practices
- Performance insights
- User feedback

Last updated: [Current Date]
Review schedule: Quarterly