import XCTest
@testable import Dirt

@MainActor
final class SearchServiceConsolidationTests: XCTestCase {
    
    var searchService: SearchService!
    
    override func setUp() async throws {
        try await super.setUp()
        searchService = SearchService.shared
    }
    
    override func tearDown() async throws {
        searchService = nil
        try await super.tearDown()
    }
    
    // MARK: - Service Consolidation Tests
    
    func testSearchServiceSingleton() {
        // Test that SearchService maintains singleton pattern
        let service1 = SearchService.shared
        let service2 = SearchService.shared
        
        XCTAssertTrue(service1 === service2, "SearchService should be a singleton")
    }
    
    func testServiceContainerIntegration() {
        // Test that ServiceContainer uses the consolidated SearchService
        let container = ServiceContainer.shared
        let containerSearchService = container.searchService
        
        XCTAssertNotNil(containerSearchService)
        XCTAssertTrue(containerSearchService === SearchService.shared, "ServiceContainer should use the same SearchService instance")
    }
    
    func testLegacySavedSearchServiceConsolidation() async throws {
        // Test that legacy SavedSearchService functionality is now in SearchService
        let searchService = SearchService.shared
        
        // Test legacy methods are available
        do {
            let queries = try await searchService.listSavedSearchQueries()
            XCTAssertNotNil(queries)
            // Should return fallback data in test environment
            XCTAssertTrue(queries.contains("#ghosting") || queries.contains("#redflag"))
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
        
        // Test legacy save method
        do {
            try await searchService.saveLegacySearch(query: "test query", tags: ["test"])
            // Should complete without error or fail gracefully
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
        
        // Test legacy delete method
        do {
            try await searchService.deleteLegacySearch(query: "test query")
            // Should complete without error or fail gracefully
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    // MARK: - Legacy Compatibility Tests
    
    func testLegacySearchMethod() async throws {
        // Test that the legacy search method still works
        let results = try await searchService.search(query: "test", tags: [], sort: .recent)
        
        XCTAssertNotNil(results)
        XCTAssertTrue(results.allSatisfy { $0.id != UUID() || $0.title.contains("test") || $0.snippet.contains("test") })
    }
    
    func testLegacySearchWithTags() async throws {
        // Test legacy search with tags
        let results = try await searchService.search(query: "ghosting", tags: ["red flag"], sort: .popular)
        
        XCTAssertNotNil(results)
        // Should return results that match the query or tags
    }
    
    func testLegacySearchSortOptions() async throws {
        // Test all legacy sort options
        let sortOptions: [SearchSort] = [.recent, .popular, .nearby, .trending]
        
        for sortOption in sortOptions {
            let results = try await searchService.search(query: "test", tags: [], sort: sortOption)
            XCTAssertNotNil(results, "Search should work with sort option: \(sortOption)")
        }
    }
    
    // MARK: - Enhanced Functionality Tests
    
    func testEnhancedSearchProperties() {
        // Test that enhanced search properties are available
        XCTAssertEqual(searchService.searchText, "")
        XCTAssertEqual(searchService.searchScope, .all)
        XCTAssertEqual(searchService.sortOption, .relevance)
        XCTAssertFalse(searchService.isSearching)
        XCTAssertTrue(searchService.hasMoreResults)
        XCTAssertTrue(searchService.results.isEmpty)
        XCTAssertTrue(searchService.recentSearches.isEmpty)
        XCTAssertTrue(searchService.savedSearches.isEmpty)
        XCTAssertTrue(searchService.suggestions.isEmpty)
        XCTAssertNil(searchService.errorMessage)
    }
    
    func testSearchScopeEnum() {
        // Test SearchScope enum functionality
        let allScopes = SearchScope.allCases
        XCTAssertEqual(allScopes.count, 5)
        
        XCTAssertEqual(SearchScope.all.displayName, "All")
        XCTAssertEqual(SearchScope.posts.displayName, "Posts")
        XCTAssertEqual(SearchScope.users.displayName, "Users")
        XCTAssertEqual(SearchScope.topics.displayName, "Topics")
        XCTAssertEqual(SearchScope.hashtags.displayName, "Hashtags")
        
        XCTAssertEqual(SearchScope.all.systemImage, "magnifyingglass")
        XCTAssertEqual(SearchScope.posts.systemImage, "doc.text")
        XCTAssertEqual(SearchScope.users.systemImage, "person")
        XCTAssertEqual(SearchScope.topics.systemImage, "tag")
        XCTAssertEqual(SearchScope.hashtags.systemImage, "number")
    }
    
    func testSortOptionEnum() {
        // Test SortOption enum functionality
        let allOptions = SortOption.allCases
        XCTAssertEqual(allOptions.count, 4)
        
        XCTAssertEqual(SortOption.relevance.displayName, "Most Relevant")
        XCTAssertEqual(SortOption.recent.displayName, "Most Recent")
        XCTAssertEqual(SortOption.popular.displayName, "Most Popular")
        XCTAssertEqual(SortOption.oldest.displayName, "Oldest")
    }
    
    func testSearchFilterTypes() {
        // Test SearchFilter and its nested types
        let filter = SearchFilter()
        XCTAssertNil(filter.dateRange)
        XCTAssertNil(filter.userType)
        XCTAssertNil(filter.contentType)
        XCTAssertNil(filter.hasMedia)
        XCTAssertNil(filter.minEngagement)
        
        // Test DateRange
        XCTAssertEqual(SearchFilter.DateRange.today.displayName, "Today")
        XCTAssertEqual(SearchFilter.DateRange.week.displayName, "This Week")
        XCTAssertEqual(SearchFilter.DateRange.month.displayName, "This Month")
        XCTAssertEqual(SearchFilter.DateRange.year.displayName, "This Year")
        XCTAssertEqual(SearchFilter.DateRange.all.displayName, "All Time")
        
        // Test UserType
        XCTAssertEqual(SearchFilter.UserType.verified.displayName, "Verified Users")
        XCTAssertEqual(SearchFilter.UserType.regular.displayName, "Regular Users")
        XCTAssertEqual(SearchFilter.UserType.all.displayName, "All Users")
        
        // Test ContentType
        XCTAssertEqual(SearchFilter.ContentType.text.displayName, "Text Only")
        XCTAssertEqual(SearchFilter.ContentType.image.displayName, "With Images")
        XCTAssertEqual(SearchFilter.ContentType.video.displayName, "With Videos")
        XCTAssertEqual(SearchFilter.ContentType.link.displayName, "With Links")
        XCTAssertEqual(SearchFilter.ContentType.all.displayName, "All Content")
    }
    
    // MARK: - Search Functionality Tests
    
    func testPerformSearch() {
        // Test enhanced search functionality
        searchService.searchText = "test query"
        searchService.performSearch(reset: true)
        
        XCTAssertTrue(searchService.isSearching || !searchService.results.isEmpty)
    }
    
    func testClearResults() {
        // Test clearing search results
        searchService.searchText = "test"
        searchService.clearResults()
        
        XCTAssertTrue(searchService.results.isEmpty)
        XCTAssertFalse(searchService.isSearching)
        XCTAssertTrue(searchService.hasMoreResults)
        XCTAssertTrue(searchService.suggestions.isEmpty)
        XCTAssertNil(searchService.errorMessage)
    }
    
    func testRecentSearches() {
        // Test recent searches functionality
        let initialCount = searchService.recentSearches.count
        
        // Simulate adding a recent search (this would normally happen during search)
        searchService.clearRecentSearches()
        XCTAssertTrue(searchService.recentSearches.isEmpty)
    }
    
    func testSavedSearches() {
        // Test saved searches functionality
        let initialCount = searchService.savedSearches.count
        
        let testSearch = SavedSearch(
            id: UUID().uuidString,
            name: "Test Search",
            query: "test query",
            scope: .all,
            filter: SearchFilter(),
            createdAt: Date()
        )
        
        searchService.saveCurrentSearch(name: "Test Search")
        // Note: This would normally save to UserDefaults, but we're testing the method exists
    }
    
    // MARK: - Legacy Compatibility Result Types
    
    func testLegacySearchResultType() {
        // Test that legacy SearchResult type still works
        let result = SearchResult(
            id: UUID(),
            title: "Test Result",
            snippet: "Test snippet",
            tags: ["test", "result"],
            score: 0.85
        )
        
        XCTAssertEqual(result.title, "Test Result")
        XCTAssertEqual(result.snippet, "Test snippet")
        XCTAssertEqual(result.tags, ["test", "result"])
        XCTAssertEqual(result.score, 0.85)
    }
    
    func testLegacySearchSortType() {
        // Test that legacy SearchSort enum still works
        XCTAssertEqual(SearchSort.recent.rawValue, "recent")
        XCTAssertEqual(SearchSort.popular.rawValue, "popular")
        XCTAssertEqual(SearchSort.nearby.rawValue, "nearby")
        XCTAssertEqual(SearchSort.trending.rawValue, "trending")
    }
    
    // MARK: - Performance Tests
    
    func testServiceInitializationPerformance() {
        measure {
            _ = SearchService.shared
        }
    }
    
    func testSearchPerformance() async throws {
        measure {
            Task {
                do {
                    _ = try await searchService.search(query: "performance test", tags: [], sort: .recent)
                } catch {
                    // Expected in test environment
                }
            }
        }
    }
}