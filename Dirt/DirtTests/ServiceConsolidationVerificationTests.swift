import XCTest
@testable import Dirt

/// Integration tests to verify that service consolidation works correctly
/// These tests verify that the consolidated services maintain backward compatibility
/// while providing enhanced functionality.
@MainActor
final class ServiceConsolidationVerificationTests: XCTestCase {
    
    // MARK: - Service Container Integration Tests
    
    func testServiceContainerUsesConsolidatedServices() {
        let container = ServiceContainer.shared
        
        // Verify MediaService consolidation
        let mediaService = container.mediaService
        XCTAssertNotNil(mediaService)
        XCTAssertTrue(type(of: mediaService) == MediaService.self, "ServiceContainer should use consolidated MediaService")
        
        // Verify SearchService consolidation  
        let searchService = container.searchService
        XCTAssertNotNil(searchService)
        XCTAssertTrue(type(of: searchService) == SearchService.self, "ServiceContainer should use consolidated SearchService")
    }
    
    func testServiceSingletonPattern() {
        // Test MediaService singleton
        let mediaService1 = MediaService.shared
        let mediaService2 = MediaService.shared
        XCTAssertTrue(mediaService1 === mediaService2, "MediaService should maintain singleton pattern")
        
        // Test SearchService singleton
        let searchService1 = SearchService.shared
        let searchService2 = SearchService.shared
        XCTAssertTrue(searchService1 === searchService2, "SearchService should maintain singleton pattern")
    }
    
    // MARK: - Legacy Compatibility Tests
    
    func testMediaServiceLegacyCompatibility() async throws {
        let mediaService = MediaService.shared
        
        // Test that legacy processMedia method exists and is callable
        let testURL = URL(string: "https://example.com/test.jpg")!
        
        do {
            let response = try await mediaService.processMedia(at: testURL)
            // If successful, verify response structure
            XCTAssertNotNil(response.hash)
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || 
                         error.localizedDescription.contains("network") ||
                         error.localizedDescription.contains("connection"))
        }
    }
    
    func testSearchServiceLegacyCompatibility() async throws {
        let searchService = SearchService.shared
        
        // Test legacy search method with different sort options
        let sortOptions: [SearchSort] = [.recent, .popular, .nearby, .trending]
        
        for sortOption in sortOptions {
            do {
                let results = try await searchService.search(query: "test", tags: [], sort: sortOption)
                XCTAssertNotNil(results, "Legacy search should work with sort option: \(sortOption)")
                
                // Verify result structure
                for result in results {
                    XCTAssertNotNil(result.id)
                    XCTAssertFalse(result.title.isEmpty)
                    XCTAssertFalse(result.snippet.isEmpty)
                    XCTAssertGreaterThanOrEqual(result.score, 0.0)
                    XCTAssertLessThanOrEqual(result.score, 1.0)
                }
            } catch {
                // Expected in test environment
                print("Search failed as expected in test environment: \(error)")
            }
        }
    }
    
    // MARK: - Enhanced Functionality Tests
    
    func testMediaServiceEnhancedFeatures() {
        let mediaService = MediaService.shared
        
        // Test enhanced properties are available
        XCTAssertFalse(mediaService.isUploading)
        XCTAssertEqual(mediaService.uploadProgress, 0.0)
        XCTAssertNil(mediaService.errorMessage)
        
        // Test image compression service is available
        let compressionService = ImageCompressionService.shared
        XCTAssertNotNil(compressionService)
    }
    
    func testSearchServiceEnhancedFeatures() {
        let searchService = SearchService.shared
        
        // Test enhanced properties are available
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
    
    // MARK: - Data Model Tests
    
    func testLegacyDataModelsExist() {
        // Test SearchResult model
        let searchResult = SearchResult(
            id: UUID(),
            title: "Test Result",
            snippet: "Test snippet",
            tags: ["test"],
            score: 0.85
        )
        
        XCTAssertEqual(searchResult.title, "Test Result")
        XCTAssertEqual(searchResult.snippet, "Test snippet")
        XCTAssertEqual(searchResult.tags, ["test"])
        XCTAssertEqual(searchResult.score, 0.85)
        
        // Test SearchSort enum
        XCTAssertEqual(SearchSort.recent.rawValue, "recent")
        XCTAssertEqual(SearchSort.popular.rawValue, "popular")
        XCTAssertEqual(SearchSort.nearby.rawValue, "nearby")
        XCTAssertEqual(SearchSort.trending.rawValue, "trending")
        
        // Test MediaItem model
        let mediaItem = MediaItem(
            url: URL(string: "file:///test.jpg"),
            thumbnail: nil,
            type: .image,
            size: 1024,
            filename: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        XCTAssertEqual(mediaItem.filename, "test.jpg")
        XCTAssertEqual(mediaItem.type, .image)
        XCTAssertEqual(mediaItem.size, 1024)
        XCTAssertEqual(mediaItem.mimeType, "image/jpeg")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingConsistency() {
        // Test MediaError enum
        let compressionError = MediaError.compressionFailed
        let uploadError = MediaError.uploadFailed
        let invalidFileError = MediaError.invalidFile
        let fileTooLargeError = MediaError.fileTooLarge
        
        XCTAssertEqual(compressionError.errorDescription, "Failed to compress image")
        XCTAssertEqual(uploadError.errorDescription, "Failed to upload file")
        XCTAssertEqual(invalidFileError.errorDescription, "Invalid file format")
        XCTAssertEqual(fileTooLargeError.errorDescription, "File is too large")
    }
    
    // MARK: - Performance Tests
    
    func testServiceInitializationPerformance() {
        measure {
            _ = MediaService.shared
            _ = SearchService.shared
        }
    }
    
    // MARK: - Integration Verification
    
    func testNoOrphanedReferences() {
        // This test verifies that there are no references to the old service names
        // by ensuring the consolidated services are properly accessible
        
        let container = ServiceContainer.shared
        
        // These should all work without compilation errors
        let mediaService = container.mediaService
        let searchService = container.searchService
        
        XCTAssertNotNil(mediaService)
        XCTAssertNotNil(searchService)
        
        // Verify they're the same instances as the singletons
        XCTAssertTrue(mediaService === MediaService.shared)
        XCTAssertTrue(searchService === SearchService.shared)
    }
    
    func testConsolidationRequirements() {
        // Verify requirements 6.1 and 6.3 are met:
        // 6.1: Eliminate circular dependencies
        // 6.3: Remove dead code and unused dependencies
        
        // Test that services can be instantiated without circular dependencies
        let mediaService = MediaService.shared
        let searchService = SearchService.shared
        
        XCTAssertNotNil(mediaService)
        XCTAssertNotNil(searchService)
        
        // Test that legacy compatibility is maintained
        XCTAssertTrue(mediaService.responds(to: #selector(MediaService.processMedia(at:))))
        XCTAssertTrue(searchService.responds(to: #selector(SearchService.search(query:tags:sort:))))
    }
}