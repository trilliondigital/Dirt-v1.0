import XCTest
@testable import Dirt

@MainActor
final class ServiceConsolidationVerificationTests: XCTestCase {
    
    // MARK: - Service Consolidation Verification Tests
    
    func testSearchServiceConsolidation() {
        // Test that SearchService is properly consolidated
        let searchService = SearchService.shared
        XCTAssertNotNil(searchService)
        
        // Test that enhanced functionality is available
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
    
    func testSearchServiceLegacyCompatibility() async throws {
        // Test that legacy SavedSearchService methods are available in SearchService
        let searchService = SearchService.shared
        
        // Test legacy methods exist and can be called
        do {
            let queries = try await searchService.listSavedSearchQueries()
            XCTAssertNotNil(queries)
            // Should return fallback data in test environment
            XCTAssertTrue(queries.contains("#ghosting") || queries.contains("#redflag"))
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
        
        // Test legacy search method
        do {
            let results = try await searchService.search(query: "test", tags: [], sort: .recent)
            XCTAssertNotNil(results)
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    func testMediaServiceConsolidation() {
        // Test that MediaService is properly consolidated
        let mediaService = MediaService.shared
        XCTAssertNotNil(mediaService)
        
        // Test that enhanced functionality is available
        XCTAssertFalse(mediaService.isUploading)
        XCTAssertEqual(mediaService.uploadProgress, 0.0)
        XCTAssertNil(mediaService.errorMessage)
        
        // Test that image compression service is available
        let compressionService = ImageCompressionService.shared
        XCTAssertNotNil(compressionService)
    }
    
    func testMediaServiceLegacyCompatibility() async throws {
        // Test that legacy processMedia method is available
        let mediaService = MediaService.shared
        let testURL = URL(string: "https://example.com/test-image.jpg")!
        
        do {
            let response = try await mediaService.processMedia(at: testURL)
            XCTAssertNotNil(response)
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    func testServiceContainerConsolidation() {
        // Test that ServiceContainer uses consolidated services
        let container = ServiceContainer.shared
        
        // Test SearchService integration
        let containerSearchService = container.searchService
        XCTAssertNotNil(containerSearchService)
        XCTAssertTrue(containerSearchService === SearchService.shared)
        
        // Test MediaService integration
        let containerMediaService = container.mediaService
        XCTAssertNotNil(containerMediaService)
        XCTAssertTrue(containerMediaService === MediaService.shared)
        
        // Test that new services are available
        XCTAssertNotNil(container.performanceService)
        XCTAssertNotNil(container.errorRecoveryService)
        XCTAssertNotNil(container.networkMonitor)
    }
    
    func testNewServicesCreated() {
        // Test that new services are properly created and functional
        let performanceService = PerformanceCacheService.shared
        XCTAssertNotNil(performanceService)
        XCTAssertFalse(performanceService.isMonitoring)
        
        let errorRecoveryService = ErrorRecoveryService.shared
        XCTAssertNotNil(errorRecoveryService)
        XCTAssertFalse(errorRecoveryService.isRecovering)
        XCTAssertTrue(errorRecoveryService.recoveryAttempts.isEmpty)
        
        let networkMonitor = NetworkMonitor.shared
        XCTAssertNotNil(networkMonitor)
        // Network monitor should be connected in test environment
        XCTAssertTrue(networkMonitor.isConnected)
    }
    
    func testSavedSearchServiceRemoved() {
        // Test that SavedSearchService is no longer available as a separate service
        // This test verifies that the consolidation removed the duplicate service
        
        // The ServiceContainer should not have a savedSearchService property anymore
        let container = ServiceContainer.shared
        let mirror = Mirror(reflecting: container)
        
        let hasSavedSearchService = mirror.children.contains { child in
            child.label == "savedSearchService"
        }
        
        XCTAssertFalse(hasSavedSearchService, "SavedSearchService should be removed from ServiceContainer")
    }
    
    func testLegacySearchResultTypes() {
        // Test that legacy types are still available for backward compatibility
        let legacyResult = SearchResult(
            id: UUID(),
            title: "Test Result",
            snippet: "Test snippet",
            tags: ["test", "result"],
            score: 0.85
        )
        
        XCTAssertEqual(legacyResult.title, "Test Result")
        XCTAssertEqual(legacyResult.snippet, "Test snippet")
        XCTAssertEqual(legacyResult.tags, ["test", "result"])
        XCTAssertEqual(legacyResult.score, 0.85)
        
        // Test legacy SavedSearch type
        let legacySavedSearch = LegacySavedSearch(
            id: UUID(),
            query: "test query",
            tags: ["test"],
            createdAt: Date()
        )
        
        XCTAssertEqual(legacySavedSearch.query, "test query")
        XCTAssertEqual(legacySavedSearch.tags, ["test"])
    }
    
    func testEnhancedSearchResultTypes() {
        // Test that enhanced types are available
        let enhancedResult = EnhancedSearchResult(
            id: "test-id",
            type: .posts,
            title: "Enhanced Result",
            subtitle: "Enhanced subtitle",
            content: "Enhanced content",
            imageURL: "https://example.com/image.jpg",
            timestamp: Date(),
            relevanceScore: 0.95,
            metadata: ["author": "Test Author"]
        )
        
        XCTAssertEqual(enhancedResult.title, "Enhanced Result")
        XCTAssertEqual(enhancedResult.type, .posts)
        XCTAssertEqual(enhancedResult.relevanceScore, 0.95)
        XCTAssertEqual(enhancedResult.metadata["author"], "Test Author")
    }
    
    func testMediaItemTypes() {
        // Test that MediaItem and related types are available
        let mediaItem = MediaItem(
            url: URL(string: "file:///test/image.jpg"),
            thumbnail: nil,
            type: .image,
            size: 1024,
            filename: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        XCTAssertEqual(mediaItem.filename, "test.jpg")
        XCTAssertEqual(mediaItem.type, .image)
        XCTAssertEqual(mediaItem.size, 1024)
        XCTAssertEqual(mediaItem.formattedSize, "1 KB")
    }
}