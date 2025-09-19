import Foundation

final class MentionsService {
    static let shared = MentionsService()
    private init() {}

    struct MentionsResponse: Codable { let processed: Bool }

    // Extract @mentions from content and notify backend; safe to call fire-and-forget
    @discardableResult
    func processMentions(postId: UUID, content: String) async -> Bool {
        let mentions = extractMentions(from: content)
        guard !mentions.isEmpty, ModerationService.shared.backendEnabled else { return true }

        let payload: [String: Any] = [
            "post_id": postId.uuidString,
            "mentions": mentions,
            "content": String(content.prefix(280))
        ]

        func isTransient(_ error: Error) -> Bool {
            if error is URLError { return true }
            let ns = error as NSError
            if ns.domain == "SupabaseFunction" { return ns.code >= 500 || ns.code == 429 }
            return false
        }

        do {
            let data = try await Retry.withExponentialBackoff(
                .init(maxAttempts: 3, initialDelay: 0.5, multiplier: 2.0, jitter: 0.2),
                shouldRetry: { isTransient($0) }
            ) {
                try await SupabaseManager.shared.callEdgeFunction(name: "mentions-process", json: payload)
            }
            _ = try? JSONDecoder().decode(MentionsResponse.self, from: data)
            return true
        } catch {
            #if DEBUG
            print("[MentionsService] process failed:", error.localizedDescription)
            #endif
            return false
        }
    }

    // Basic regex: @username (alnum, underscore, dot), 2-30 chars
    func extractMentions(from text: String) -> [String] {
        let pattern = #"@([A-Za-z0-9_.]{2,30})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap {
            guard let r = Range($0.range(at: 1), in: text) else { return nil }
            return String(text[r]).lowercased()
        }
    }
}
