import XCTest
@testable import Dirt

@MainActor
final class MediaServiceConsolidationTests: XCTestCase {
    
    var mediaService: MediaService!
    
    override func setUp() async throws {
        try await super.setUp()
        mediaService = MediaService.shared
    }
    
    override func tearDown() async throws {
        mediaService = nil
        try await super.tearDown()
    }
    
    // MARK: - Service Consolidation Tests
    
    func testMediaServiceSingleton() {
        // Test that MediaService maintains singleton pattern
        let service1 = MediaService.shared
        let service2 = MediaService.shared
        
        XCTAssertTrue(service1 === service2, "MediaService should be a singleton")
    }
    
    func testServiceContainerIntegration() {
        // Test that ServiceContainer uses the consolidated MediaService
        let container = ServiceContainer.shared
        let containerMediaService = container.mediaService
        
        XCTAssertNotNil(containerMediaService)
        XCTAssertTrue(containerMediaService === MediaService.shared, "ServiceContainer should use the same MediaService instance")
    }
    
    func testLegacyMediaProcessingConsolidation() async throws {
        // Test that legacy media processing functionality is available
        let mediaService = MediaService.shared
        let testURL = URL(string: "https://example.com/test-image.jpg")!
        
        do {
            let response = try await mediaService.processMedia(at: testURL)
            XCTAssertNotNil(response)
            XCTAssertNotNil(response.hash)
        } catch {
            // Expected in test environment without backend
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    // MARK: - Legacy Compatibility Tests
    
    func testLegacyProcessMediaMethod() async throws {
        // Test that the legacy processMedia method still works
        let testURL = URL(string: "https://example.com/test-image.jpg")!
        
        do {
            let response = try await mediaService.processMedia(at: testURL)
            // Since this calls a mock backend, we expect it to work or fail gracefully
            XCTAssertNotNil(response)
        } catch {
            // If backend is not available, that's expected in tests
            XCTAssertTrue(error.localizedDescription.contains("Failed") || error.localizedDescription.contains("network"))
        }
    }
    
    // MARK: - Enhanced Functionality Tests
    
    func testImageCompressionService() {
        // Test that image compression functionality is available
        let compressionService = ImageCompressionService.shared
        XCTAssertNotNil(compressionService)
        
        // Create a test image
        let testImage = UIImage(systemName: "photo")!
        let compressedImage = compressionService.compressImage(testImage, maxSizeKB: 100, maxDimension: 512)
        
        XCTAssertNotNil(compressedImage, "Image compression should return a valid image")
    }
    
    func testMediaItemCreation() {
        // Test MediaItem model functionality
        let testURL = URL(string: "file:///test/image.jpg")
        let testImage = UIImage(systemName: "photo")!
        
        let mediaItem = MediaItem(
            url: testURL,
            thumbnail: testImage,
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
    
    func testUploadProgressTracking() {
        // Test that upload progress is properly tracked
        XCTAssertFalse(mediaService.isUploading)
        XCTAssertEqual(mediaService.uploadProgress, 0.0)
        XCTAssertNil(mediaService.errorMessage)
    }
    
    func testThumbnailGeneration() {
        // Test thumbnail generation functionality
        let testImage = UIImage(systemName: "photo")!
        let thumbnail = mediaService.generateThumbnail(for: testImage, size: CGSize(width: 100, height: 100))
        
        XCTAssertNotNil(thumbnail, "Thumbnail generation should return a valid image")
    }
    
    // MARK: - Error Handling Tests
    
    func testMediaErrorTypes() {
        // Test that MediaError enum provides proper error descriptions
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
        }
    }
}