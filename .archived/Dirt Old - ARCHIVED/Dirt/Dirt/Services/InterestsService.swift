import Foundation

final class InterestsService {
    static let shared = InterestsService()
    private init() {}

    func save(interests: [String]) async throws {
        let payload: [String: Any] = ["interests": interests]
        _ = try await SupabaseManager.shared.callEdgeFunction(name: "interests-save", json: payload)
    }
}
