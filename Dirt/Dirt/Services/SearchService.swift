import Foundation
import Combine

struct SearchResult: Identifiable, Equatable {
    let id = UUID()
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

    // Simulated backend search with delay and simple matching
    func search(query: String, tags: [String] = [], sort: SearchSort = .recent) async throws -> [SearchResult] {
        try await Task.sleep(nanoseconds: 450_000_000) // 450ms debounce-like delay
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }

        // Mock corpus
        let corpus: [SearchResult] = [
            .init(title: "Ghosting after three dates", snippet: "Be cautious. Ghosted after three amazing dates...", tags: ["red flag", "ghosting"], score: 0.91),
            .init(title: "Great conversation, second date planned", snippet: "Amazing first date, talked for hours...", tags: ["green flag", "great conversation"], score: 0.88),
            .init(title: "Shared interests: booklover", snippet: "Found someone who reads the same books...", tags: ["green flag", "shared interests"], score: 0.84),
            .init(title: "Mixed signals in Austin", snippet: "Confusing communication patterns observed...", tags: ["mixed signals", "Austin"], score: 0.76)
        ]

        var results = corpus.filter { r in
            r.title.lowercased().contains(q) || r.snippet.lowercased().contains(q) || r.tags.contains { $0.lowercased().contains(q) }
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
