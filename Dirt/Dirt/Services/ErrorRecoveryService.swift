import Foundation
import Combine

/// Error recovery and resilience service
/// Provides automatic error recovery, retry logic, and fallback mechanisms
@MainActor
class ErrorRecoveryService: ObservableObject {
    static let shared = ErrorRecoveryService()
    
    @Published var isRecovering = false
    @Published var recoveryAttempts: [RecoveryAttempt] = []
    
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0
    
    private init() {}
    
    // MARK: - Error Recovery
    
    /// Attempt to recover from an error with automatic retry
    func recover<T>(
        from error: Error,
        operation: @escaping () async throws -> T,
        fallback: (() async -> T)? = nil
    ) async -> Result<T, Error> {
        let attempt = RecoveryAttempt(
            id: UUID(),
            error: error,
            timestamp: Date(),
            attempts: 0
        )
        
        recoveryAttempts.append(attempt)
        isRecovering = true
        
        defer {
            isRecovering = false
        }
        
        // Try the operation with retries
        for attemptNumber in 1...maxRetryAttempts {
            do {
                let result = try await operation()
                attempt.success = true
                attempt.attempts = attemptNumber
                return .success(result)
            } catch {
                attempt.attempts = attemptNumber
                
                if attemptNumber < maxRetryAttempts {
                    // Wait before retrying
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attemptNumber) * 1_000_000_000))
                } else {
                    // Final attempt failed, try fallback
                    if let fallback = fallback {
                        let fallbackResult = await fallback()
                        attempt.usedFallback = true
                        return .success(fallbackResult)
                    }
                    
                    attempt.finalError = error
                    return .failure(error)
                }
            }
        }
        
        return .failure(attempt.error)
    }
    
    /// Check if a specific error type should trigger recovery
    func shouldRecover(from error: Error) -> Bool {
        // Network errors should trigger recovery
        if let urlError = error as? URLError {
            switch urlError.code {
            case .networkConnectionLost, .notConnectedToInternet, .timedOut:
                return true
            default:
                return false
            }
        }
        
        // Custom recoverable errors
        if error is RecoverableError {
            return true
        }
        
        return false
    }
    
    /// Clear old recovery attempts
    func clearOldAttempts() {
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour ago
        recoveryAttempts.removeAll { $0.timestamp < cutoffDate }
    }
}

// MARK: - Recovery Attempt Model

class RecoveryAttempt: ObservableObject, Identifiable {
    let id: UUID
    let error: Error
    let timestamp: Date
    
    @Published var attempts: Int = 0
    @Published var success: Bool = false
    @Published var usedFallback: Bool = false
    @Published var finalError: Error?
    
    init(id: UUID, error: Error, timestamp: Date, attempts: Int) {
        self.id = id
        self.error = error
        self.timestamp = timestamp
        self.attempts = attempts
    }
}

// MARK: - Recoverable Error Protocol

protocol RecoverableError: Error {
    var canRecover: Bool { get }
    var suggestedRetryDelay: TimeInterval { get }
}

// MARK: - ManagedService Conformance

extension ErrorRecoveryService: ManagedService {
    func initialize() async throws {
        // Initialize error recovery monitoring
    }
    
    func cleanup() async {
        recoveryAttempts.removeAll()
    }
}