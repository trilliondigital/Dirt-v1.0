import XCTest
@testable import Dirt

final class SearchServiceTests: XCTestCase {
    func testCacheStoresAndReturns() async throws {
        // Warm the cache with a mock fallback result by querying nonsense
        let q = "abcxyz123"
        let first = try await SearchService.shared.search(query: q)
        let second = try await SearchService.shared.search(query: q)
        XCTAssertEqual(first, second)
    }
}
