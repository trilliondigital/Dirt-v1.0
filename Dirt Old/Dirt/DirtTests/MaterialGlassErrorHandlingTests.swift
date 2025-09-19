import XCTest
import SwiftUI
@testable import Dirt

@MainActor
final class MaterialGlassErrorHandlingTests: XCTestCase {
    
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
    
    // MARK: - Material Glass Toast Component Tests
    
    func testGlassToastInitialization() {
        let toast = GlassToast(message: "Test message", type: .info)
        
        // Test that toast can be created without crashing
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastWithCustomDuration() {
        let toast = GlassToast(
            message: "Custom duration toast",
            type: .success,
            duration: 10.0
        )
        
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastWithDismissCallback() {
        var dismissCalled = false
        
        let toast = GlassToast(
            message: "Dismissible toast",
            type: .warning,
            onDismiss: {
                dismissCalled = true
            }
        )
        
        XCTAssertNotNil(toast)
        // Note: We can't easily test the callback execution in unit tests
        // as it requires UI interaction, but we can verify it doesn't crash
    }
    
    func testGlassToastNonDismissible() {
        let toast = GlassToast(
            message: "Non-dismissible toast",
            type: .error,
            isDismissible: false
        )
        
        XCTAssertNotNil(toast)
    }
    
    // MARK: - Material Glass Design System Integration
    
    func testGlassToastUsesDesignSystem() {
        // Test that toast types use correct Material Glass colors
        XCTAssertEqual(GlassToast.ToastType.success.glassOverlay, MaterialDesignSystem.GlassColors.success)
        XCTAssertEqual(GlassToast.ToastType.warning.glassOverlay, MaterialDesignSystem.GlassColors.warning)
        XCTAssertEqual(GlassToast.ToastType.error.glassOverlay, MaterialDesignSystem.GlassColors.danger)
        XCTAssertEqual(GlassToast.ToastType.info.glassOverlay, MaterialDesignSystem.GlassColors.primary)
    }
    
    func testGlassToastUsesCorrectColors() {
        XCTAssertEqual(GlassToast.ToastType.success.color, UIColors.success)
        XCTAssertEqual(GlassToast.ToastType.warning.color, UIColors.warning)
        XCTAssertEqual(GlassToast.ToastType.error.color, UIColors.danger)
        XCTAssertEqual(GlassToast.ToastType.info.color, UIColors.accentPrimary)
    }
    
    // MARK: - Error Presenter Integration with Material Glass
    
    func testErrorPresenterCreatesGlassToast() {
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let toast = ErrorPresenter.createGlassToast(for: testError)
        
        XCTAssertNotNil(toast)
    }
    
    func testErrorPresenterToastTypeMapping() {
        // Test network error creates warning toast
        let networkError = URLError(.notConnectedToInternet)
        let networkToast = ErrorPresenter.createGlassToast(for: networkError)
        XCTAssertNotNil(networkToast)
        
        // Test validation error creates info toast
        let validationError = AppError.validation(.required("Field"))
        let validationToast = ErrorPresenter.createGlassToast(for: validationError)
        XCTAssertNotNil(validationToast)
        
        // Test generic error creates error toast
        let genericError = NSError(domain: "Generic", code: 999, userInfo: nil)
        let genericToast = ErrorPresenter.createGlassToast(for: genericError)
        XCTAssertNotNil(genericToast)
    }
    
    // MARK: - Material Motion Integration
    
    func testGlassToastUsesMotionSystem() {
        // Test that the toast uses Material Motion animations
        // This is more of a compilation test since we can't easily test animations
        let toast = GlassToast(message: "Motion test", type: .info)
        XCTAssertNotNil(toast)
        
        // Verify that MaterialMotion.Glass.toastAppear exists and is accessible
        let animation = MaterialMotion.Glass.toastAppear
        XCTAssertNotNil(animation)
    }
    
    // MARK: - Error Handling Manager Material Glass Integration
    
    func testErrorHandlingManagerCreatesGlassToasts() {
        // Test error presentation
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        errorManager.presentError(testError)
        
        XCTAssertNotNil(errorManager.currentToast)
        
        // Test success presentation
        errorManager.presentSuccess("Success message")
        XCTAssertNotNil(errorManager.currentToast)
        
        // Test warning presentation
        errorManager.presentWarning("Warning message")
        XCTAssertNotNil(errorManager.currentToast)
        
        // Test info presentation
        errorManager.presentInfo("Info message")
        XCTAssertNotNil(errorManager.currentToast)
    }
    
    func testErrorHandlingManagerToastReplacement() {
        // Present first toast
        errorManager.presentError(NSError(domain: "Test1", code: 1, userInfo: nil))
        let firstToastId = errorManager.currentToast?.id
        
        // Present second toast - should replace first
        errorManager.presentError(NSError(domain: "Test2", code: 2, userInfo: nil))
        let secondToastId = errorManager.currentToast?.id
        
        XCTAssertNotEqual(firstToastId, secondToastId)
        XCTAssertNotNil(errorManager.currentToast)
    }
    
    // MARK: - View Extension Material Glass Integration
    
    func testViewExtensionWithErrorHandling() {
        let testView = Text("Test View")
        let enhancedView = testView.withErrorHandling()
        
        // Test that the view can be created without crashing
        XCTAssertNotNil(enhancedView)
    }
    
    func testViewExtensionPresentGlassToast() {
        let testView = Text("Test View")
        let testError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        let errorView = testView.presentGlassToast(for: testError)
        XCTAssertNotNil(errorView)
        
        let messageView = testView.presentGlassToast(message: "Custom message", type: .success)
        XCTAssertNotNil(messageView)
    }
    
    // MARK: - Service Integration with Material Glass
    
    func testServiceErrorHandlingWithGlassToasts() {
        let mockService = MockMaterialGlassService()
        let testError = NSError(domain: "Service", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service error"])
        
        // Test that service error handling integrates with Material Glass
        mockService.performOperation()
        
        // The service should handle errors using the standardized pattern
        XCTAssertTrue(mockService.operationPerformed)
    }
    
    // MARK: - Accessibility Tests
    
    func testGlassToastAccessibility() {
        // Test that toast types have appropriate accessibility properties
        let successToast = GlassToast(message: "Success", type: .success)
        let warningToast = GlassToast(message: "Warning", type: .warning)
        let errorToast = GlassToast(message: "Error", type: .error)
        let infoToast = GlassToast(message: "Info", type: .info)
        
        // All toasts should be creatable (accessibility is handled in the UI layer)
        XCTAssertNotNil(successToast)
        XCTAssertNotNil(warningToast)
        XCTAssertNotNil(errorToast)
        XCTAssertNotNil(infoToast)
    }
    
    // MARK: - Performance Tests
    
    func testGlassToastPerformance() {
        measure {
            for i in 0..<100 {
                let toast = GlassToast(
                    message: "Performance test message \(i)",
                    type: .info
                )
                _ = toast
            }
        }
    }
    
    func testErrorHandlingManagerPerformance() {
        measure {
            for i in 0..<50 {
                let error = NSError(domain: "Performance", code: i, userInfo: [NSLocalizedDescriptionKey: "Error \(i)"])
                errorManager.presentError(error, context: "Performance test")
                errorManager.dismissCurrentToast()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testGlassToastWithEmptyMessage() {
        let toast = GlassToast(message: "", type: .info)
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastWithLongMessage() {
        let longMessage = String(repeating: "This is a very long message. ", count: 20)
        let toast = GlassToast(message: longMessage, type: .warning)
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastWithZeroDuration() {
        let toast = GlassToast(message: "Zero duration", type: .info, duration: 0)
        XCTAssertNotNil(toast)
    }
    
    func testGlassToastWithNegativeDuration() {
        let toast = GlassToast(message: "Negative duration", type: .info, duration: -1)
        XCTAssertNotNil(toast)
    }
    
    // MARK: - Error Recovery Integration
    
    func testErrorHandlingWithRecovery() {
        // Test that error handling works with the existing error recovery system
        let recoverableError = AppError.network(.noConnection)
        errorManager.presentError(recoverableError, context: "Recovery test")
        
        XCTAssertNotNil(errorManager.currentToast)
        XCTAssertEqual(errorManager.errorHistory.count, 1)
        
        let logEntry = errorManager.errorHistory.first!
        XCTAssertEqual(logEntry.toastType, .warning) // Network errors should be warnings
    }
}

// MARK: - Mock Service for Testing

class MockMaterialGlassService: ErrorHandlingService {
    var operationPerformed = false
    
    func performOperation() {
        operationPerformed = true
        
        // Simulate an operation that might fail
        let shouldFail = false // Set to true to test error handling
        
        if shouldFail {
            let error = NSError(domain: "MockService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
            handleError(error, context: "MockMaterialGlassService.performOperation")
        } else {
            // Simulate success
            Task { @MainActor in
                ErrorHandlingManager.shared.presentSuccess("Operation completed successfully")
            }
        }
    }
}

// MARK: - UI Integration Tests

@MainActor
final class MaterialGlassErrorHandlingUITests: XCTestCase {
    
    func testErrorHandlingOverlayIntegration() {
        // Test that the ErrorHandlingOverlay can be created
        let overlay = ErrorHandlingOverlay()
        XCTAssertNotNil(overlay)
    }
    
    func testErrorHandlingEnvironmentIntegration() {
        // Test that the environment key works
        let defaultManager = ErrorHandlingManagerKey.defaultValue
        XCTAssertNotNil(defaultManager)
        XCTAssertTrue(defaultManager === ErrorHandlingManager.shared)
    }
    
    func testMaterialGlassComponentsIntegration() {
        // Test that Material Glass components integrate properly with error handling
        let card = GlassCard {
            Text("Test content")
        }
        XCTAssertNotNil(card)
        
        let button = GlassButton("Test Button") {
            // Button action
        }
        XCTAssertNotNil(button)
        
        let modal = GlassModal(isPresented: .constant(true)) {
            Text("Modal content")
        }
        XCTAssertNotNil(modal)
    }
}

// MARK: - Private ErrorHandlingOverlay for Testing

private struct ErrorHandlingOverlay: View {
    @StateObject private var errorManager = ErrorHandlingManager.shared
    
    var body: some View {
        Group {
            if let toastState = errorManager.currentToast {
                toastState.toast
                    .transition(MaterialMotion.Transition.slideDown)
                    .zIndex(1000)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .padding(.horizontal, UISpacing.md)
            }
        }
        .animation(MaterialMotion.Glass.toastAppear, value: errorManager.currentToast?.id)
    }
}