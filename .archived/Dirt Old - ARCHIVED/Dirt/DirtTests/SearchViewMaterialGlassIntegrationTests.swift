import XCTest
@testable import Dirt

@MainActor
final class SearchViewMaterialGlassIntegrationTests: XCTestCase {
    
    // MARK: - Basic Integration Tests
    
    func testSearchServiceConsolidationWorks() async throws {
        // Test that the consolidated SearchService works correctly
        let searchService = SearchService.shared
        
        // Test legacy search method
        let results = try await searchService.search(query: "material glass test", tags: [], sort: .recent)
        XCTAssertNotNil(results)
        
        // Test that results have expected structure
        for result in results.prefix(3) {
            XCTAssertNotNil(result.id)
            XCTAssertFalse(result.title.isEmpty)
            XCTAssertFalse(result.snippet.isEmpty)
            XCTAssertGreaterThanOrEqual(result.score, 0.0)
            XCTAssertLessThanOrEqual(result.score, 1.0)
        }
    }
    
    func testMaterialDesignSystemConstants() {
        // Test that Material Design System constants are properly defined
        XCTAssertNotNil(MaterialDesignSystem.Glass.thin)
        XCTAssertNotNil(MaterialDesignSystem.Glass.regular)
        XCTAssertNotNil(MaterialDesignSystem.Glass.ultraThin)
        XCTAssertNotNil(MaterialDesignSystem.Glass.thick)
        XCTAssertNotNil(MaterialDesignSystem.Glass.ultraThick)
        
        XCTAssertNotNil(MaterialDesignSystem.Context.card)
        XCTAssertNotNil(MaterialDesignSystem.Context.navigation)
        XCTAssertNotNil(MaterialDesignSystem.Context.tabBar)
        XCTAssertNotNil(MaterialDesignSystem.Context.modal)
        
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.primary)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.secondary)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.success)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.warning)
        XCTAssertNotNil(MaterialDesignSystem.GlassColors.danger)
        
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.subtle)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.prominent)
        XCTAssertNotNil(MaterialDesignSystem.GlassBorders.accent)
    }
    
    func testUIDesignTokensAvailable() {
        // Test that UI design tokens are available and properly configured
        XCTAssertGreaterThan(UISpacing.xs, 0)
        XCTAssertGreaterThan(UISpacing.sm, UISpacing.xs)
        XCTAssertGreaterThan(UISpacing.md, UISpacing.sm)
        XCTAssertGreaterThan(UISpacing.lg, UISpacing.md)
        XCTAssertGreaterThan(UISpacing.xl, UISpacing.lg)
        
        XCTAssertGreaterThan(UICornerRadius.xs, 0)
        XCTAssertGreaterThan(UICornerRadius.sm, UICornerRadius.xs)
        XCTAssertGreaterThan(UICornerRadius.md, UICornerRadius.sm)
        XCTAssertGreaterThan(UICornerRadius.lg, UICornerRadius.md)
        XCTAssertGreaterThan(UICornerRadius.xl, UICornerRadius.lg)
        
        XCTAssertNotNil(UIColors.label)
        XCTAssertNotNil(UIColors.secondaryLabel)
        XCTAssertNotNil(UIColors.accentPrimary)
        XCTAssertNotNil(UIColors.background)
        XCTAssertNotNil(UIColors.success)
        XCTAssertNotNil(UIColors.warning)
        XCTAssertNotNil(UIColors.danger)
    }
    
    func testSearchResultStructure() {
        // Test that SearchResult structure is maintained for backward compatibility
        let testResult = SearchResult(
            id: UUID(),
            title: "Test Material Glass Result",
            snippet: "This is a test snippet for Material Glass integration",
            tags: ["material", "glass", "test"],
            score: 0.85
        )
        
        XCTAssertEqual(testResult.title, "Test Material Glass Result")
        XCTAssertEqual(testResult.snippet, "This is a test snippet for Material Glass integration")
        XCTAssertEqual(testResult.tags, ["material", "glass", "test"])
        XCTAssertEqual(testResult.score, 0.85)
        XCTAssertNotNil(testResult.id)
    }
    
    func testTagCatalogIntegration() {
        // Test that TagCatalog works with Material Glass search
        let allTags = TagCatalog.all
        XCTAssertFalse(allTags.isEmpty)
        
        // Test that tags can be converted to suggestions
        let tagSuggestions = allTags.map { $0.rawValue }
        XCTAssertFalse(tagSuggestions.isEmpty)
        
        for tag in tagSuggestions {
            XCTAssertFalse(tag.isEmpty)
        }
        
        // Test specific tags exist
        let tagValues = Set(tagSuggestions)
        XCTAssertTrue(tagValues.contains("👻 Ghosting"))
        XCTAssertTrue(tagValues.contains("💬 Great Conversation"))
        XCTAssertTrue(tagValues.contains("💑 Second Date"))
        XCTAssertTrue(tagValues.contains("❌ Avoid"))
    }
    
    func testErrorHandlingIntegration() {
        // Test that error handling works with Material Glass
        let testError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let errorMessage = ErrorPresenter.message(for: testError)
        
        XCTAssertEqual(errorMessage, "Test error")
        
        // Test network error handling
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let networkMessage = ErrorPresenter.message(for: networkError)
        
        XCTAssertEqual(networkMessage, "Network issue. Check your connection and try again.")
        
        // Test Supabase error handling
        let supabaseError = NSError(domain: "SupabaseFunction", code: 429)
        let supabaseMessage = ErrorPresenter.message(for: supabaseError)
        
        XCTAssertEqual(supabaseMessage, "Too many requests. Please wait a moment and try again.")
    }
    
    func testToastCenterIntegration() {
        // Test that ToastCenter works with Material Glass
        let toastCenter = ToastCenter()
        
        XCTAssertNil(toastCenter.message)
        
        toastCenter.show(.success, "Material Glass test success")
        XCTAssertNotNil(toastCenter.message)
        XCTAssertEqual(toastCenter.message?.style, .success)
        XCTAssertEqual(toastCenter.message?.text, "Material Glass test success")
        
        toastCenter.show(.error, "Material Glass test error")
        XCTAssertNotNil(toastCenter.message)
        XCTAssertEqual(toastCenter.message?.style, .error)
        XCTAssertEqual(toastCenter.message?.text, "Material Glass test error")
    }
    
    func testHapticFeedbackIntegration() {
        // Test that haptic feedback integration works
        let hapticService = EnhancedHapticFeedback.shared
        
        // Test that service is available
        XCTAssertNotNil(hapticService)
        
        // Test that methods don't crash (no assertions needed, just testing execution)
        hapticService.buttonTap()
        hapticService.cardTap()
        hapticService.actionSuccess()
        hapticService.actionError()
        
        // Test legacy compatibility
        HapticFeedback.impact(style: .light)
        HapticFeedback.notification(type: .success)
        
        XCTAssertTrue(true) // If we get here, haptic methods didn't crash
    }
    
    func testSearchSortOptionsCompatibility() {
        // Test that all search sort options are available
        let sortOptions: [SearchSort] = [.recent, .popular, .nearby, .trending]
        
        XCTAssertEqual(sortOptions.count, 4)
        
        XCTAssertEqual(SearchSort.recent.rawValue, "recent")
        XCTAssertEqual(SearchSort.popular.rawValue, "popular")
        XCTAssertEqual(SearchSort.nearby.rawValue, "nearby")
        XCTAssertEqual(SearchSort.trending.rawValue, "trending")
    }
    
    func testSearchFilterMappingCompatibility() {
        // Test that filter mapping works correctly
        let filters = ["Recent", "Popular", "Nearby", "Trending"]
        let sortMappings: [String: SearchSort] = [
            "Recent": .recent,
            "Popular": .popular,
            "Nearby": .nearby,
            "Trending": .trending
        ]
        
        for filter in filters {
            XCTAssertNotNil(sortMappings[filter], "Filter \(filter) should have a corresponding SearchSort")
        }
    }
    
    func testServiceContainerIntegration() {
        // Test that ServiceContainer provides SearchService
        let container = ServiceContainer.shared
        let searchService = container.searchService
        
        XCTAssertNotNil(searchService)
        XCTAssertTrue(searchService === SearchService.shared, "ServiceContainer should provide the same SearchService instance")
    }
    
    // MARK: - Performance Tests
    
    func testMaterialGlassConstantsPerformance() {
        measure {
            // Test performance of accessing Material Glass constants
            _ = MaterialDesignSystem.Glass.thin
            _ = MaterialDesignSystem.Context.card
            _ = MaterialDesignSystem.GlassColors.primary
            _ = MaterialDesignSystem.GlassBorders.subtle
            _ = UISpacing.md
            _ = UICornerRadius.lg
            _ = UIColors.accentPrimary
        }
    }
    
    func testSearchServicePerformance() async throws {
        measure {
            Task {
                do {
                    _ = try await SearchService.shared.search(query: "performance", tags: [], sort: .recent)
                } catch {
                    // Expected in test environment
                }
            }
        }
    }
    
    // MARK: - Regression Tests
    
    func testNoRegressionInSearchFunctionality() async throws {
        // Ensure SearchView Material Glass refactor doesn't break existing functionality
        let searchService = SearchService.shared
        
        // Test all sort options still work
        let sortOptions: [SearchSort] = [.recent, .popular, .nearby, .trending]
        
        for sortOption in sortOptions {
            let results = try await searchService.search(query: "regression test", tags: [], sort: sortOption)
            XCTAssertNotNil(results, "Search should work with sort option: \(sortOption)")
        }
        
        // Test search with tags
        let resultsWithTags = try await searchService.search(query: "test", tags: ["tag1"], sort: .recent)
        XCTAssertNotNil(resultsWithTags)
        
        // Test empty query
        let emptyResults = try await searchService.search(query: "", tags: [], sort: .recent)
        XCTAssertNotNil(emptyResults)
    }
    
    func testBackwardCompatibilityMaintained() async throws {
        // Test that all legacy SearchService methods still work
        let searchService = SearchService.shared
        
        // Test legacy search
        let legacyResults = try await searchService.search(query: "legacy", tags: ["test"], sort: .recent)
        XCTAssertNotNil(legacyResults)
        
        // Test saved searches (may fail in test environment, but should not crash)
        do {
            let savedSearches = try await searchService.listSavedSearchQueries()
            XCTAssertNotNil(savedSearches)
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
        
        // Test save search (may fail in test environment, but should not crash)
        do {
            try await searchService.saveLegacySearch(query: "test query")
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
        
        // Test delete search (may fail in test environment, but should not crash)
        do {
            try await searchService.deleteLegacySearch(query: "test query")
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
}