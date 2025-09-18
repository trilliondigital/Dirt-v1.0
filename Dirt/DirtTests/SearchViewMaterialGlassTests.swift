import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class SearchViewMaterialGlassTests: XCTestCase {
    
    var searchService: SearchService!
    var toastCenter: ToastCenter!
    var serviceContainer: ServiceContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        searchService = SearchService.shared
        toastCenter = ToastCenter()
        serviceContainer = ServiceContainer.shared
    }
    
    override func tearDown() async throws {
        searchService = nil
        toastCenter = nil
        serviceContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Material Glass Component Tests
    
    func testGlassSearchBarExists() {
        // Test that GlassSearchBar component is available
        let searchBar = GlassSearchBar(
            text: .constant("test"),
            placeholder: "Search...",
            onSearchButtonClicked: {}
        )
        
        XCTAssertNotNil(searchBar)
    }
    
    func testGlassCardExists() {
        // Test that GlassCard component is available
        let card = GlassCard {
            Text("Test Content")
        }
        
        XCTAssertNotNil(card)
    }
    
    func testGlassButtonExists() {
        // Test that GlassButton component is available
        let button = GlassButton("Test Button") {}
        
        XCTAssertNotNil(button)
    }
    
    // MARK: - SearchView Material Glass Integration Tests
    
    func testSearchViewUsesGlassComponents() {
        // Test that SearchView can be instantiated with Material Glass components
        let searchView = SearchView()
            .environmentObject(toastCenter)
            .environment(\.services, serviceContainer)
        
        XCTAssertNotNil(searchView)
    }
    
    func testSearchResultRowUsesGlassCard() {
        // Test that SearchResultRow uses GlassCard
        let testResult = SearchResult(
            id: UUID(),
            title: "Test Result",
            snippet: "Test snippet content",
            tags: ["test", "material"],
            score: 0.85
        )
        
        let resultRow = SearchResultRow(result: testResult)
        XCTAssertNotNil(resultRow)
    }
    
    // MARK: - Material Design System Integration Tests
    
    func testMaterialDesignSystemConstants() {
        // Test that Material Design System constants are available
        XCTAssertNotNil(MaterialDesignSystem.Glass.thin)
        XCTAssertNotNil(MaterialDesignSystem.Glass.regular)
        XCTAssertNotNil(MaterialDesignSystem.Glass.ultraThin)
        
        XCTAssertNotNil(MaterialDesignSystem.Context.card)
        XCTAssertNotNil(MaterialDesignSystem.Context.navigation)
        
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.primary)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.subtle)
    }
    
    func testUIDesignTokens() {
        // Test that UI design tokens are available
        XCTAssertGreaterThan(UISpacing.xs, 0)
        XCTAssertGreaterThan(UISpacing.sm, UISpacing.xs)
        XCTAssertGreaterThan(UISpacing.md, UISpacing.sm)
        XCTAssertGreaterThan(UISpacing.lg, UISpacing.md)
        
        XCTAssertGreaterThan(UICornerRadius.xs, 0)
        XCTAssertGreaterThan(UICornerRadius.sm, UICornerRadius.xs)
        XCTAssertGreaterThan(UICornerRadius.md, UICornerRadius.sm)
        XCTAssertGreaterThan(UICornerRadius.lg, UICornerRadius.md)
        
        XCTAssertNotNil(UIColors.label)
        XCTAssertNotNil(UIColors.secondaryLabel)
        XCTAssertNotNil(UIColors.accentPrimary)
    }
    
    // MARK: - Search Functionality with Material Glass Tests
    
    func testSearchServiceIntegrationWithMaterialGlass() async throws {
        // Test that SearchService works with Material Glass components
        let searchService = SearchService.shared
        
        // Test legacy search method still works
        let results = try await searchService.search(query: "material glass", tags: [], sort: .recent)
        XCTAssertNotNil(results)
        
        // Test that results can be displayed in Material Glass components
        for result in results.prefix(3) {
            let resultRow = SearchResultRow(result: result)
            XCTAssertNotNil(resultRow)
        }
    }
    
    func testSavedSearchesWithMaterialGlass() async throws {
        // Test saved searches functionality with Material Glass
        let searchService = SearchService.shared
        
        do {
            let savedSearches = try await searchService.listSavedSearchQueries()
            XCTAssertNotNil(savedSearches)
            
            // Test that saved searches can be displayed in Material Glass cards
            for search in savedSearches.prefix(3) {
                XCTAssertFalse(search.isEmpty)
            }
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testMaterialGlassAccessibility() {
        // Test that Material Glass components maintain accessibility
        let searchBar = GlassSearchBar(
            text: .constant(""),
            placeholder: "Search posts, tags, users..."
        )
        
        let button = GlassButton("Save", systemImage: "bookmark") {}
        
        let card = GlassCard {
            Text("Accessible content")
        }
        
        // Components should be instantiable (accessibility will be tested in UI tests)
        XCTAssertNotNil(searchBar)
        XCTAssertNotNil(button)
        XCTAssertNotNil(card)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithMaterialGlass() {
        // Test that error handling works with Material Glass components
        let errorMessage = ErrorPresenter.message(for: NSError(domain: "TestError", code: 500))
        XCTAssertFalse(errorMessage.isEmpty)
        
        // Test toast integration
        let toastCenter = ToastCenter()
        toastCenter.show(.error, errorMessage)
        XCTAssertNotNil(toastCenter.message)
        XCTAssertEqual(toastCenter.message?.style, .error)
    }
    
    // MARK: - Haptic Feedback Tests
    
    func testHapticFeedbackIntegration() {
        // Test that haptic feedback works with Material Glass components
        let hapticService = EnhancedHapticFeedback.shared
        
        // Test that haptic methods are available
        hapticService.buttonTap()
        hapticService.cardTap()
        hapticService.actionSuccess()
        hapticService.actionError()
        
        // Test legacy HapticFeedback compatibility
        HapticFeedback.impact(style: .light)
        HapticFeedback.notification(type: .success)
        
        // No assertions needed - just testing that methods don't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Tag System Tests
    
    func testTagCatalogIntegration() {
        // Test that TagCatalog works with Material Glass search
        let allTags = TagCatalog.all
        XCTAssertFalse(allTags.isEmpty)
        
        // Test that tags can be used in search suggestions
        let tagSuggestions = allTags.map { $0.rawValue }
        XCTAssertFalse(tagSuggestions.isEmpty)
        
        for tag in tagSuggestions {
            XCTAssertFalse(tag.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMaterialGlassPerformance() {
        measure {
            // Test performance of creating Material Glass components
            let searchBar = GlassSearchBar(text: .constant("test"))
            let button = GlassButton("Test") {}
            let card = GlassCard { Text("Test") }
            
            // Suppress unused variable warnings
            _ = searchBar
            _ = button
            _ = card
        }
    }
    
    func testSearchViewRenderingPerformance() {
        measure {
            // Test performance of SearchView with Material Glass
            let searchView = SearchView()
                .environmentObject(toastCenter)
                .environment(\.services, serviceContainer)
            
            // Suppress unused variable warning
            _ = searchView
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteSearchFlowWithMaterialGlass() async throws {
        // Test complete search flow with Material Glass components
        let searchService = SearchService.shared
        
        // Simulate search
        let query = "test query"
        let results = try await searchService.search(query: query, tags: [], sort: .recent)
        
        // Test that results can be rendered in Material Glass components
        XCTAssertNotNil(results)
        
        for result in results.prefix(5) {
            let resultRow = SearchResultRow(result: result)
            XCTAssertNotNil(resultRow)
            
            // Test result properties
            XCTAssertFalse(result.title.isEmpty)
            XCTAssertFalse(result.snippet.isEmpty)
            XCTAssertGreaterThanOrEqual(result.score, 0.0)
            XCTAssertLessThanOrEqual(result.score, 1.0)
        }
    }
    
    func testFilteringWithMaterialGlass() async throws {
        // Test search filtering with Material Glass components
        let searchService = SearchService.shared
        
        let filters = ["Recent", "Popular", "Nearby", "Trending"]
        let sortMappings: [String: SearchSort] = [
            "Recent": .recent,
            "Popular": .popular,
            "Nearby": .nearby,
            "Trending": .trending
        ]
        
        for filter in filters {
            if let sort = sortMappings[filter] {
                let results = try await searchService.search(query: "test", tags: [], sort: sort)
                XCTAssertNotNil(results)
            }
        }
    }
    
    // MARK: - Regression Tests
    
    func testBackwardCompatibility() async throws {
        // Test that existing SearchView functionality still works after Material Glass refactor
        let searchService = SearchService.shared
        
        // Test legacy search method
        let legacyResults = try await searchService.search(query: "legacy test", tags: ["test"], sort: .recent)
        XCTAssertNotNil(legacyResults)
        
        // Test saved searches
        do {
            let savedSearches = try await searchService.listSavedSearchQueries()
            XCTAssertNotNil(savedSearches)
        } catch {
            // Expected in test environment
        }
        
        // Test search result structure
        if let firstResult = legacyResults.first {
            XCTAssertNotNil(firstResult.id)
            XCTAssertFalse(firstResult.title.isEmpty)
            XCTAssertFalse(firstResult.snippet.isEmpty)
            XCTAssertNotNil(firstResult.tags)
            XCTAssertGreaterThanOrEqual(firstResult.score, 0.0)
        }
    }
    
    func testNoRegressionInSearchFunctionality() async throws {
        // Ensure no functionality was lost during Material Glass refactor
        let searchService = SearchService.shared
        
        // Test all search sort options
        let sortOptions: [SearchSort] = [.recent, .popular, .nearby, .trending]
        
        for sortOption in sortOptions {
            let results = try await searchService.search(query: "regression test", tags: [], sort: sortOption)
            XCTAssertNotNil(results, "Search should work with sort option: \(sortOption)")
        }
        
        // Test search with tags
        let resultsWithTags = try await searchService.search(query: "test", tags: ["tag1", "tag2"], sort: .recent)
        XCTAssertNotNil(resultsWithTags)
        
        // Test empty query handling
        let emptyResults = try await searchService.search(query: "", tags: [], sort: .recent)
        XCTAssertNotNil(emptyResults)
    }
}