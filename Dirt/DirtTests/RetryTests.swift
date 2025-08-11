import XCTest
@testable import Dirt

final class RetryTests: XCTestCase {
    func testRetrySucceedsAfterFailures() async throws {
        var attempts = 0
        let config = Retry.Config(maxAttempts: 3, initialDelay: 0.01, multiplier: 1.0, jitter: 0)
        let result: Int = try await Retry.withExponentialBackoff(config, shouldRetry: { _ in true }) {
            attempts += 1
            if attempts < 3 { throw URLError(.timedOut) }
            return 42
        }
        XCTAssertEqual(result, 42)
        XCTAssertEqual(attempts, 3)
    }

    func testRetryStopsOnNonTransient() async {
        var attempts = 0
        let config = Retry.Config(maxAttempts: 3, initialDelay: 0.0, multiplier: 1.0, jitter: 0)
        do {
            _ = try await Retry.withExponentialBackoff(config, shouldRetry: { _ in false }) {
                attempts += 1
                throw URLError(.badURL)
            } as Int
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(attempts, 1)
        }
    }
}
