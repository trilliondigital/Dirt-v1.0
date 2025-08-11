import Foundation
import Combine

struct SearchResult: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let snippet: String
    let tags: [String]
    let score: Double
}

enum SearchSort: String {
    case recent
    case popular
    case nearby
    case trending
}

final class SearchService {
    static let shared = SearchService()
    private init() {}

    // Backend search via Edge Function with fallback to mock
    func search(query: String, tags: [String] = [], sort: SearchSort = .recent) async throws -> [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        // Attempt backend call
        do {
            let payload: [String: Any] = [
                "query": q,
                "tags": tags,
                "sort": sort.rawValue
            ]
            let data = try await SupabaseManager.shared.callEdgeFunction(name: "search-global", json: payload)
            let decoder = JSONDecoder()
            return try decoder.decode([SearchResult].self, from: data)
        } catch {
            // Fallback to mock data if backend not available
            let corpus: [SearchResult] = [
                .init(id: UUID(), title: "Ghosting after three dates", snippet: "Be cautious. Ghosted after three amazing dates...", tags: ["red flag", "ghosting"], score: 0.91),
                .init(id: UUID(), title: "Great conversation, second date planned", snippet: "Amazing first date, talked for hours...", tags: ["green flag", "great conversation"], score: 0.88),
                .init(id: UUID(), title: "Shared interests: booklover", snippet: "Found someone who reads the same books...", tags: ["green flag", "shared interests"], score: 0.84),
                .init(id: UUID(), title: "Mixed signals in Austin", snippet: "Confusing communication patterns observed...", tags: ["mixed signals", "Austin"], score: 0.76)
            ]
            var results = corpus.filter { r in
                r.title.localizedCaseInsensitiveContains(q) || r.snippet.localizedCaseInsensitiveContains(q) || r.tags.contains { $0.localizedCaseInsensitiveContains(q) }
            }
            if !tags.isEmpty {
                let tset = Set(tags.map { $0.lowercased() })
                results = results.filter { r in !tset.isDisjoint(with: r.tags.map { $0.lowercased() }) }
            }
            switch sort {
            case .recent:
                results = results.shuffled()
            case .popular, .trending:
                results = results.sorted { $0.score > $1.score }
            case .nearby:
                results = results.shuffled()
            }
            return results
        }
    }
}
