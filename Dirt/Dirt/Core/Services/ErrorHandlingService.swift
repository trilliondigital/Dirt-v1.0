import Foundation
import SwiftUI
import Combine

// MARK: - Error Types

enum AppError: LocalizedError, Equatable {
    case network(NetworkError)
    case authentication(AuthError)
    case validation(ValidationError)
    case storage(StorageError)
    case media(MediaError)
    case generic(String)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.errorDescription
        case .authentication(let error):
            return error.errorDescription
        case .validation(let error):
            return error.errorDescription
        case .storage(let error):
            return error.errorDescription
        case .media(let error):
            return error.errorDescription
        case .generic(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network(let error):
            return error.recoverySuggestion
        case .authentication(let error):
            return error.recoverySuggestion
        case .validation(let error):
            return error.recoverySuggestion
        case .storage(let error):
            return error.recoverySuggestion
        case .media(let error):
            return error.recoverySuggestion
        case .generic:
            return "Please try again later"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .network(let error):
            return error.isRetryable
        case .authentication(let error):
            return error.isRetryable
        case .validation:
            return false
        case .storage(let error):
            return error.isRetryable
        case .media(let error):
            return error.isRetryable
        case .generic:
            return true
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case rateLimited
    case unauthorized
    case forbidden
    case notFound
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid server response"
        case .rateLimited:
            return "Too many requests"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again"
        case .timeout:
            return "Check your connection and try again"
        case .serverError:
            return "Please try again later"
        case .invalidResponse:
            return "Please try again"
        case .rateLimited:
            return "Please wait a moment before trying again"
        case .unauthorized:
            return "Please sign in again"
        case .forbidden:
            return "You don't have permission to perform this action"
        case .notFound:
            return "The requested content could not be found"
        case .unknown:
            return "Please try again"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .rateLimited, .unknown:
            return true
        case .invalidResponse, .unauthorized, .forbidden, .notFound:
            return false
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case accountLocked
    case sessionExpired
    case biometricNotAvailable
    case biometricFailed
    case twoFactorRequired
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountLocked:
            return "Account temporarily locked"
        case .sessionExpired:
            return "Session expired"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .twoFactorRequired:
            return "Two-factor authentication required"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your credentials and try again"
        case .accountLocked:
            return "Please try again later or contact support"
        case .sessionExpired:
            return "Please sign in again"
        case .biometricNotAvailable:
            return "Use password authentication instead"
        case .biometricFailed:
            return "Try again or use password authentication"
        case .twoFactorRequired:
            return "Please complete two-factor authentication"
        case .unknown:
            return "Please try signing in again"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .invalidCredentials, .accountLocked:
            return false
        case .sessionExpired, .biometricNotAvailable, .biometricFailed, .twoFactorRequired, .unknown:
            return true
        }
    }
}

enum ValidationError: LocalizedError {
    case required(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .required(let field):
            return "\(field) is required"
        case .invalidFormat(let field):
            return "\(field) format is invalid"
        case .tooShort(let field, let min):
            return "\(field) must be at least \(min) characters"
        case .tooLong(let field, let max):
            return "\(field) must be no more than \(max) characters"
        case .custom(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        return "Please correct the highlighted fields"
    }
}

enum StorageError: LocalizedError {
    case diskFull
    case permissionDenied
    case corruptedData
    case notFound
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .diskFull:
            return "Not enough storage space"
        case .permissionDenied:
            return "Storage permission denied"
        case .corruptedData:
            return "Data corrupted"
        case .notFound:
            return "File not found"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .diskFull:
            return "Free up some storage space and try again"
        case .permissionDenied:
            return "Grant storage permission in Settings"
        case .corruptedData:
            return "Please try again or contact support"
        case .notFound:
            return "The file may have been moved or deleted"
        case .unknown:
            return "Please try again"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .diskFull, .permissionDenied:
            return false
        case .corruptedData, .notFound, .unknown:
            return true
        }
    }
}

// MediaError is defined in Services/MediaService.swift

// MARK: - Error Boundary

@MainActor
class ErrorBoundary: ObservableObject {
    @Published var hasError = false
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxHistorySize = 100
    
    func handle(_ error: Error, context: String = "") {
        let appError = mapToAppError(error)
        currentError = appError
        hasError = true
        
        logError(appError, context: context)
        
        // Send to analytics
        AnalyticsService.shared.trackError(appError, context: context)
        
        // Trigger haptic feedback
        EnhancedHapticFeedback.shared.trigger(.error)
    }
    
    func clearError() {
        hasError = false
        currentError = nil
    }
    
    func retry(action: @escaping () async throws -> Void) async {
        guard let error = currentError, error.isRetryable else { return }
        
        clearError()
        
        do {
            try await action()
        } catch {
            handle(error)
        }
    }
    
    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .network(.noConnection)
            case .timedOut:
                return .network(.timeout)
            case .userAuthenticationRequired:
                return .network(.unauthorized)
            default:
                return .network(.unknown(error))
            }
        }
        
        return .generic(error.localizedDescription)
    }
    
    private func logError(_ error: AppError, context: String) {
        let entry = ErrorLogEntry(
            error: error,
            context: context,
            timestamp: Date(),
            stackTrace: Thread.callStackSymbols.joined(separator: "\n")
        )
        
        errorHistory.insert(entry, at: 0)
        
        if errorHistory.count > maxHistorySize {
            errorHistory.removeLast()
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("ERROR: \(error.errorDescription ?? "Unknown error")")
        print("CONTEXT: \(context)")
        print("STACK TRACE: \(entry.stackTrace)")
        #endif
    }
}

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String
    let timestamp: Date
    let stackTrace: String
}

// MARK: - Retry Mechanism

@MainActor
class RetryManager: ObservableObject {
    @Published var isRetrying = false
    @Published var retryCount = 0
    
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        onError: ((AppError) -> Void)? = nil
    ) async throws -> T {
        isRetrying = false
        retryCount = 0
        
        for attempt in 0..<maxRetries {
            do {
                let result = try await operation()
                retryCount = 0
                isRetrying = false
                return result
            } catch {
                let appError = mapToAppError(error)
                
                if attempt == maxRetries - 1 || !appError.isRetryable {
                    isRetrying = false
                    onError?(appError)
                    throw appError
                }
                
                retryCount = attempt + 1
                isRetrying = true
                
                // Exponential backoff
                let delay = baseDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw AppError.generic("Max retries exceeded")
    }
    
    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .generic(error.localizedDescription)
    }
}

// MARK: - Error Recovery Strategies

struct ErrorRecoveryStrategy {
    let canRecover: (AppError) -> Bool
    let recover: (AppError) async -> Bool
    let description: String
}

// ErrorRecoveryService is defined in Services/ErrorRecoveryService.swift

// MARK: - Network Monitor
// NetworkMonitor is defined in Core/Services/NetworkMonitor.swift

// MARK: - Error UI Components

struct ErrorBoundaryView<Content: View>: View {
    @StateObject private var errorBoundary = ErrorBoundary()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .environmentObject(errorBoundary)
            
            if errorBoundary.hasError {
                ErrorOverlay(
                    error: errorBoundary.currentError!,
                    onDismiss: { errorBoundary.clearError() },
                    onRetry: {
                        // Implement retry logic based on context
                        errorBoundary.clearError()
                    }
                )
            }
        }
    }
}

struct ErrorOverlay: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: () -> Void
    
    @StateObject private var recoveryService = ErrorRecoveryService.shared
    @State private var isAttemptingRecovery = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 20) {
                Image(systemName: errorIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("Oops! Something went wrong")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error.errorDescription ?? "Unknown error")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                HStack(spacing: 16) {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    if error.isRetryable {
                        Button("Retry") {
                            if isAttemptingRecovery {
                                return
                            }
                            
                            Task {
                                isAttemptingRecovery = true
                                let recovered = await recoveryService.attemptRecovery(for: error)
                                isAttemptingRecovery = false
                                
                                if recovered {
                                    onDismiss()
                                } else {
                                    onRetry()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isAttemptingRecovery)
                    }
                }
                
                if isAttemptingRecovery {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text(recoveryService.getRecoveryDescription(for: error) ?? "Attempting recovery...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
    }
    
    private var errorIcon: String {
        switch error {
        case .network:
            return "wifi.slash"
        case .authentication:
            return "person.crop.circle.badge.xmark"
        case .validation:
            return "exclamationmark.triangle"
        case .storage:
            return "externaldrive.badge.xmark"
        case .media:
            return "photo.badge.exclamationmark"
        case .generic:
            return "exclamationmark.circle"
        }
    }
}

struct ErrorToast: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(error.errorDescription ?? "Unknown error")
                    .font(.caption2)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - Error Logging View

struct ErrorLogView: View {
    @StateObject private var errorBoundary = ErrorBoundary()
    
    var body: some View {
        List {
            if errorBoundary.errorHistory.isEmpty {
                Text("No errors logged")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(errorBoundary.errorHistory) { entry in
                    ErrorLogRow(entry: entry)
                }
            }
        }
        .navigationTitle("Error Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    errorBoundary.errorHistory.removeAll()
                }
                .disabled(errorBoundary.errorHistory.isEmpty)
            }
        }
    }
}

struct ErrorLogRow: View {
    let entry: ErrorLogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.error.errorDescription ?? "Unknown error")
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(entry.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !entry.context.isEmpty {
                        Text("Context: \(entry.context)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let suggestion = entry.error.recoverySuggestion {
                        Text("Suggestion: \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Stack Trace:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(entry.stackTrace)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading)
                }
            }
        }
        .padding(.vertical, 4)
    }
}