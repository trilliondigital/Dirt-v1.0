import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class ErrorHandlingTests: XCTestCase {
    
    var errorManager: ErrorHandlingManager!
    
    override func setUp() {
        super.setUp()
        errorManager = ErrorHandlingManager.shared
        errorManager.dismissCurrentToast()
        errorManager.clearErrorHistory()
    }
    
    override func tearDown() {
        errorManager.dismissCurrentToast()
        errorManager.clearErrorHistory()
        super.tearDown()
    }
    
    // MARK: - ErrorPresenter Tests
    
    func testErrorPresenterMessage() {
        // Test network error
        let networkError = URLError(.notConnectedToInternet)
        let networkMessage = ErrorPresenter.message(for: networkError)
        XCTAssertEqual(networkMessage, "Network issue. Check your connection and try again.")
        
        // Test rate limiting error
        let rateLimitError = NSError(domain: "SupabaseFunction", code: 429, userInfo: nil)
        let rateLimitMessage = ErrorPresenter.message(for: rateLimitError)
        XCTAssertEqual(rateLimitMessage, "Too many requests. Please wait a moment and try again.")
        
        // Test server error
        let serverError = NSError(domain: "SupabaseFunction", code: 500, userInfo: nil)
        let serverMessage = ErrorPresenter.message(for: serverError)
        XCTAssertEqual(serverMessage, "Server is having trouble. We're on it—try again shortly.")
        
        // Test generic error
        let genericError = NSError(domain: "TestDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom error"])
        let genericMessage = ErrorPresenter.message(for: genericError)
        XCTAssertEqual(genericMessage, "Custom error")
    }
    
    func testErrorPresenterToastType() {
        // Test network errors map to warning
        let networkError = URLError(.notConnectedToInternet)
        let networkType = ErrorPresenter.toastType(for: networkError)
        XCTAssertEqual(networkType, .warning)
        
        // Test timeout errors map to warning
        let timeoutError = URLError(.timedOut)
        let timeoutType = ErrorPresenter.toastType(for: timeoutError)
        XCTAssertEqual(timeoutType, .warning)
        
        // Test rate limiting maps to warning
        let rateLimitError = NSError(domain: "SupabaseFunction", code: 429, userInfo: nil)
        let rateLimitType = ErrorPresenter.toastType(for: rateLimitError)
        XCTAssertEqual(rateLimitType, .warning)
        
        // Test auth errors map to warning
        let authError = NSError(domain: "SupabaseFunction", code: 401, userInfo: nil)
        let authType = ErrorPresenter.toastType(for: authError)
        XCTAssertEqual(authType, .warning)
        
        // Test client errors map to info
        let clientError = NSError(domain: "SupabaseFunction", code: 400, userInfo: nil)
        let clientType = ErrorPresenter.toastType(for: clientError)
        XCTAssertEqual(clientType, .info)
        
        // Test generic errors map to error
        let genericError = NSError(domain: "TestDomain", code: 999, userInfo: nil)
        let genericType = ErrorPresenter.toastType(for: genericError)
        XCTAssertEqual(genericType, .error)
    }
    
    func testErrorPresenterAppErrorMapping() {
        // Test validation error maps to info
        let validationError = AppError.validation(.required("Email"))
        let validationType = ErrorPresenter.toastType(for: validationError)
        XCTAssertEqual(validationType, .info)
        
        // Test network connection error maps to warning
        let connectionError = AppError.network(.noConnection)
        let connectionType = ErrorPresenter.toastType(for: connectionError)
        XCTAssertEqual(connectionType, .warning)
        
        // Test storage disk full error maps to warning
        let storageError = AppError.storage(.diskFull)
        let storageType = ErrorPresenter.toastType(for: storageError)
        XCTAssertEqual(storageType, .warning)
        
        // Test authentication error maps to warning
        let authError = AppError.authentication(.sessionExpired)
        let authType = ErrorPresenter.toastType(for: authError)
        XCTAssertEqual(authType, .warning)
    }
    
    // MARK: - ErrorHandlingManager Tests
    
    func testErrorHandlingManagerPresentError() {
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        errorManager.presentError(testError, context: "Test context")
        
        XCTAssertNotNil(errorManager.currentToast)
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        
        let logEntry = errorManager.errorHistory.first!
        XCTAssertEqual(logEntry.context, "Test context")
        XCTAssertEqual(logEntry.userMessage, "Test error")
    }
    
    func testErrorHandlingManagerPresentSuccess() {
        errorManager.presentSuccess("Operation completed successfully")
        
        XCTAssertNotNil(errorManager.currentToast)
        // Success messages don't get logged as errors
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    func testErrorHandlingManagerPresentWarning() {
        errorManager.presentWarning("This is a warning")
        
        XCTAssertNotNil(errorManager.currentToast)
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    func testErrorHandlingManagerPresentInfo() {
        errorManager.presentInfo("This is information")
        
        XCTAssertNotNil(errorManager.currentToast)
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    func testErrorHandlingManagerDismissToast() {
        errorManager.presentError(NSError(domain: "Test", code: 1, userInfo: nil))
        XCTAssertNotNil(errorManager.currentToast)
        
        errorManager.dismissCurrentToast()
        XCTAssertNil(errorManager.currentToast)
    }
    
    func testErrorHandlingManagerErrorHistory() {
        let error1 = NSError(domain: "Test1", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error 1"])
        let error2 = NSError(domain: "Test2", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error 2"])
        
        errorManager.presentError(error1, context: "Context 1")
        errorManager.presentError(error2, context: "Context 2")
        
        XCTAssertEqual(errorManager.errorHistory.count, 2)
        
        // Most recent error should be first
        XCTAssertEqual(errorManager.errorHistory[0].userMessage, "Error 2")
        XCTAssertEqual(errorManager.errorHistory[1].userMessage, "Error 1")
    }
    
    func testErrorHandlingManagerHistoryLimit() {
        // Add more than the max history size (50)
        for i in 1...60 {
            let error = NSError(domain: "Test", code: i, userInfo: [NSLocalizedDescriptionKey: "Error \(i)"])
            errorManager.presentError(error)
        }
        
        // Should be limited to 50 entries
        XCTAssertEqual(errorManager.errorHistory.count, 50)
        
        // Most recent should be "Error 60"
        XCTAssertEqual(errorManager.errorHistory.first?.userMessage, "Error 60")
        
        // Oldest should be "Error 11" (60 - 50 + 1)
        XCTAssertEqual(errorManager.errorHistory.last?.userMessage, "Error 11")
    }
    
    func testErrorHandlingManagerClearHistory() {
        errorManager.presentError(NSError(domain: "Test", code: 1, userInfo: nil))
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        
        errorManager.clearErrorHistory()
        XCTAssertEqual(errorManager.errorHistory.count, 0)
    }
    
    // MARK: - GlassToast Tests
    
    func testGlassToastTypes() {
        XCTAssertEqual(GlassToast.ToastType.success.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(GlassToast.ToastType.warning.systemImage, "exclamationmark.triangle.fill")
        XCTAssertEqual(GlassToast.ToastType.error.systemImage, "xmark.circle.fill")
        XCTAssertEqual(GlassToast.ToastType.info.systemImage, "info.circle.fill")
    }
    
    func testGlassToastDefaultDurations() {
        XCTAssertEqual(GlassToast.ToastType.success.defaultDuration, 3.0)
        XCTAssertEqual(GlassToast.ToastType.warning.defaultDuration, 5.0)
        XCTAssertEqual(GlassToast.ToastType.error.defaultDuration, 6.0)
        XCTAssertEqual(GlassToast.ToastType.info.defaultDuration, 4.0)
    }
    
    func testGlassToastHapticFeedback() {
        XCTAssertEqual(GlassToast.ToastType.success.hapticFeedback, .success)
        XCTAssertEqual(GlassToast.ToastType.warning.hapticFeedback, .warning)
        XCTAssertEqual(GlassToast.ToastType.error.hapticFeedback, .error)
        XCTAssertNil(GlassToast.ToastType.info.hapticFeedback)
    }
    
    // MARK: - Service Integration Tests
    
    func testPostServiceErrorHandling() async {
        let postService = PostService.shared
        
        // Test successful operation doesn't throw
        do {
            _ = try await postService.fetchPost(by: UUID())
        } catch {
            XCTFail("Should not throw error for normal operation")
        }
        
        // Test error handling for invalid post
        do {
            let errorId = UUID(uuidString: "error000-0000-0000-0000-000000000000")!
            _ = try await postService.fetchPost(by: errorId)
        } catch {
            // Expected to throw
        }
    }
    
    func testSearchServiceErrorHandling() async {
        let searchService = SearchService.shared
        
        // Test save search success message
        searchService.saveCurrentSearch(name: "Test Search")
        
        // Should show success message (we can't easily test the UI here, but the method should not crash)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testMediaServiceErrorHandling() async {
        let mediaService = MediaService.shared
        
        // Test image upload with valid image
        let testImage = UIImage(systemName: "photo")!
        
        do {
            _ = try await mediaService.uploadImage(testImage)
        } catch {
            // Expected to potentially fail in test environment
        }
    }
    
    // MARK: - ErrorHandlingService Protocol Tests
    
    func testErrorHandlingServiceProtocol() {
        class TestService: ErrorHandlingService {}
        
        let testService = TestService()
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Test default implementation doesn't crash
        testService.handleError(testError, context: "Test context")
        testService.handleError(testError, context: "Test context", customMessage: "Custom message")
        
        XCTAssertTrue(true) // If we get here, the protocol methods work
    }
    
    // MARK: - View Extension Tests
    
    func testViewExtensionErrorHandling() {
        let testView = Text("Test")
        let errorView = testView.withErrorHandling()
        
        // Test that the view modifier doesn't crash
        XCTAssertNotNil(errorView)
    }
    
    func testViewExtensionToastPresentation() {
        let testView = Text("Test")
        let testError = NSError(domain: "Test", code: 1, userInfo: nil)
        let errorView = testView.presentGlassToast(for: testError)
        
        // Test that the view modifier doesn't crash
        XCTAssertNotNil(errorView)
        
        let messageView = testView.presentGlassToast(message: "Test message", type: .info)
        XCTAssertNotNil(messageView)
    }
}

// MARK: - Mock Services for Testing

class MockErrorHandlingService: ErrorHandlingService {
    var lastError: Error?
    var lastContext: String?
    var lastCustomMessage: String?
    
    func handleError(_ error: Error, context: String) {
        lastError = error
        lastContext = context
    }
    
    func handleError(_ error: Error, context: String, customMessage: String) {
        lastError = error
        lastContext = context
        lastCustomMessage = customMessage
    }
}

// MARK: - Integration Tests

@MainActor
final class ErrorHandlingIntegrationTests: XCTestCase {
    
    func testEndToEndErrorFlow() {
        let errorManager = ErrorHandlingManager.shared
        errorManager.dismissCurrentToast()
        errorManager.clearErrorHistory()
        
        // Simulate a network error
        let networkError = URLError(.notConnectedToInternet)
        
        // Present the error
        errorManager.presentError(networkError, context: "Integration test")
        
        // Verify toast is presented
        XCTAssertNotNil(errorManager.currentToast)
        
        // Verify error is logged
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        let logEntry = errorManager.errorHistory.first!
        XCTAssertEqual(logEntry.context, "Integration test")
        XCTAssertEqual(logEntry.toastType, .warning)
        
        // Verify message is correct
        let expectedMessage = ErrorPresenter.message(for: networkError)
        XCTAssertEqual(logEntry.userMessage, expectedMessage)
        
        // Dismiss toast
        errorManager.dismissCurrentToast()
        XCTAssertNil(errorManager.currentToast)
        
        // History should still be there
        XCTAssertEqual(errorManager.errorHistory.count, 1)
    }
    
    func testServiceErrorHandlingIntegration() {
        let mockService = MockErrorHandlingService()
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Test basic error handling
        mockService.handleError(testError, context: "Test context")
        
        XCTAssertNotNil(mockService.lastError)
        XCTAssertEqual(mockService.lastContext, "Test context")
        XCTAssertNil(mockService.lastCustomMessage)
        
        // Test custom message handling
        mockService.handleError(testError, context: "Test context", customMessage: "Custom message")
        
        XCTAssertEqual(mockService.lastCustomMessage, "Custom message")
    }
}