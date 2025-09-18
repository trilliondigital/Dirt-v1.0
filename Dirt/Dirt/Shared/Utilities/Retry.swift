import Foundation

// MARK: - Retry Utility
// Provides an async retry helper with exponential backoff and optional jitter.
public enum Retry {
    public struct Options {
        public let maxAttempts: Int
        public let initialDelay: TimeInterval
        public let multiplier: Double
        public let jitter: Double // 0.0 ... 1.0 proportion of delay

        public init(maxAttempts: Int = 3,
                    initialDelay: TimeInterval = 0.5,
                    multiplier: Double = 2.0,
                    jitter: Double = 0.2) {
            self.maxAttempts = max(1, maxAttempts)
            self.initialDelay = max(0, initialDelay)
            self.multiplier = max(1.0, multiplier)
            self.jitter = max(0.0, min(1.0, jitter))
        }
    }

    @discardableResult
    public static func withExponentialBackoff<T>(
        _ options: Options = Options(),
        shouldRetry: ((Error) -> Bool)? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delay = options.initialDelay
        var lastError: Error?

        while attempt < options.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                // Decide whether to retry
                if attempt >= options.maxAttempts || (shouldRetry?(error) == false) {
                    break
                }
                // Apply jitter to delay
                let jitterAmount = delay * options.jitter
                let minDelay = max(0, delay - jitterAmount)
                let maxDelay = delay + jitterAmount
                let randomized = Double.random(in: minDelay...maxDelay)
                // Sleep
                let nanos = UInt64(randomized * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                delay *= options.multiplier
            }
        }
        throw lastError ?? NSError(domain: "Retry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]) 
    }
}