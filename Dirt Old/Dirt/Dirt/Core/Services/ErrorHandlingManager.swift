import Foundation
import SwiftUI
import Combine

// MARK: - Standardized Error Handling Manager

/// Centralized error handling manager that provides consistent error presentation across the app
@MainActor
class ErrorHandlingManager: ObservableObject {
    static let shared = ErrorHandlingManager()
    
    @Published var currentToast: ToastState?
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxHistorySize = 50
    private var toastDismissTimer: Timer?
    
    struct ToastState: Identifiable {
        let id = UUID()
        let toast: GlassToast
        let timestamp: Date
        
        init(toast: GlassToast) {
            self.toast = toast
            self.timestamp = Date()
        }
    }
    
    struct ErrorLogEntry: Identifiable {
        let id = UUID()
        let error: Error
        let context: String
        let timestamp: Date
        let userMessage: String
        let toastType: GlassToast.ToastType
    }
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Present an error using Material Glass toast
    func presentError(
        _ error: Error,
        context: String = "",
        customMessage: String? = nil,
        duration: TimeInterval? = nil
    ) {
        let message = customMessage ?? ErrorPresenter.message(for: error)
        let type = ErrorPresenter.toastType(for: error)
        
        // Log the error
        logError(error, context: context, userMessage: message, toastType: type)
        
        // Create and present toast
        let toast = GlassToast(
            message: message,
            type: type,
            duration: duration,
            onDismiss: { [weak self] in
                self?.dismissCurrentToast()
            }
        )
        
        presentToast(toast)
    }
    
    /// Present a success message
    func presentSuccess(
        _ message: String,
        duration: TimeInterval? = nil
    ) {
        let toast = GlassToast(
            message: message,
            type: .success,
            duration: duration,
            onDismiss: { [weak self] in
                self?.dismissCurrentToast()
            }
        )
        
        presentToast(toast)
    }
    
    /// Present a warning message
    func presentWarning(
        _ message: String,
        duration: TimeInterval? = nil
    ) {
        let toast = GlassToast(
            message: message,
            type: .warning,
            duration: duration,
            onDismiss: { [weak self] in
                self?.dismissCurrentToast()
            }
        )
        
        presentToast(toast)
    }
    
    /// Present an info message
    func presentInfo(
        _ message: String,
        duration: TimeInterval? = nil
    ) {
        let toast = GlassToast(
            message: message,
            type: .info,
            duration: duration,
            onDismiss: { [weak self] in
                self?.dismissCurrentToast()
            }
        )
        
        presentToast(toast)
    }
    
    /// Dismiss the current toast
    func dismissCurrentToast() {
        toastDismissTimer?.invalidate()
        currentToast = nil
    }
    
    /// Clear error history
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func presentToast(_ toast: GlassToast) {
        // Dismiss any existing toast
        dismissCurrentToast()
        
        // Present new toast
        currentToast = ToastState(toast: toast)
    }
    
    private func logError(
        _ error: Error,
        context: String,
        userMessage: String,
        toastType: GlassToast.ToastType
    ) {
        let entry = ErrorLogEntry(
            error: error,
            context: context,
            timestamp: Date(),
            userMessage: userMessage,
            toastType: toastType
        )
        
        errorHistory.insert(entry, at: 0)
        
        // Maintain history size limit
        if errorHistory.count > maxHistorySize {
            errorHistory.removeLast()
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("🚨 ERROR: \(userMessage)")
        if !context.isEmpty {
            print("📍 CONTEXT: \(context)")
        }
        print("🔍 DETAILS: \(error.localizedDescription)")
        #endif
        
        // Send to analytics (if available)
        AnalyticsService.shared.trackError(error, context: context)
    }
}

// MARK: - View Extension for Error Handling Manager

extension View {
    /// Apply the error handling manager overlay to present toasts
    func withErrorHandling() -> some View {
        self.overlay(
            ErrorHandlingOverlay()
        )
        .environmentObject(ErrorHandlingManager.shared)
    }
}

// MARK: - Error Handling Overlay

private struct ErrorHandlingOverlay: View {
    @StateObject private var errorManager = ErrorHandlingManager.shared
    
    var body: some View {
        Group {
            if let toastState = errorManager.currentToast {
                toastState.toast
                    .transition(MaterialMotion.Transition.slideDown)
                    .zIndex(1000)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60) // Account for safe area and navigation
                    .padding(.horizontal, UISpacing.md)
            }
        }
        .animation(MaterialMotion.Glass.toastAppear, value: errorManager.currentToast?.id)
    }
}

// MARK: - Service Protocol for Standardized Error Handling

/// Protocol that services should adopt for consistent error handling
protocol ErrorHandlingService {
    /// Handle an error with optional context
    func handleError(_ error: Error, context: String)
    
    /// Handle an error with custom message
    func handleError(_ error: Error, context: String, customMessage: String)
}

extension ErrorHandlingService {
    func handleError(_ error: Error, context: String = "") {
        Task { @MainActor in
            ErrorHandlingManager.shared.presentError(error, context: context)
        }
    }
    
    func handleError(_ error: Error, context: String = "", customMessage: String) {
        Task { @MainActor in
            ErrorHandlingManager.shared.presentError(error, context: context, customMessage: customMessage)
        }
    }
}

// MARK: - Error Handling Environment Key

struct ErrorHandlingManagerKey: EnvironmentKey {
    static let defaultValue = ErrorHandlingManager.shared
}

extension EnvironmentValues {
    var errorHandlingManager: ErrorHandlingManager {
        get { self[ErrorHandlingManagerKey.self] }
        set { self[ErrorHandlingManagerKey.self] = newValue }
    }
}