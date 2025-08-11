import Foundation

struct SavedSearch: Identifiable, Codable, Equatable {
    let id: UUID
    let query: String
    let tags: [String]
    let createdAt: Date
}

final class SavedSearchService {
    static let shared = SavedSearchService()
    private init() {}

    func list() async throws -> [String] {
        do {
            let data = try await SupabaseManager.shared.callEdgeFunction(name: "saved-searches-list", json: [:])
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([SavedSearch].self, from: data)
            return items.map { $0.query }
        } catch {
            // Fallback to local defaults
            return ["#ghosting", "#redflag", "near: Austin", "@alex", "green flag"]
        }
    }

    func save(query: String, tags: [String] = []) async throws {
        let payload: [String: Any] = ["query": query, "tags": tags]
        _ = try await SupabaseManager.shared.callEdgeFunction(name: "saved-searches-save", json: payload)
    }

    func delete(query: String) async throws {
        let payload: [String: Any] = ["query": query]
        _ = try await SupabaseManager.shared.callEdgeFunction(name: "saved-searches-delete", json: payload)
    }
}
