import Foundation

final class PostSubmissionService {
    static let shared = PostSubmissionService()
    private init() {}

    struct CreatePostResponse: Codable {
        let id: UUID
        let createdAt: Date
    }

    func createPost(content: String, flag: String, tags: [String], anonymous: Bool) async throws {
        // Client-side validation mirrors server-side
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 500 else {
            throw NSError(domain: "Post", code: 422, userInfo: [NSLocalizedDescriptionKey: "Post must be 1-500 characters."])
        }
        guard !tags.isEmpty else {
            throw NSError(domain: "Post", code: 422, userInfo: [NSLocalizedDescriptionKey: "At least one tag is required."])
        }
        guard flag == "red" || flag == "green" else {
            throw NSError(domain: "Post", code: 422, userInfo: [NSLocalizedDescriptionKey: "Flag must be red or green."])
        }
        let payload: [String: Any] = [
            "content": trimmed,
            "flag": flag,
            "tags": tags,
            "anonymous": anonymous
        ]
        // Retry on transient failures (network, 5xx)
        func isTransient(_ error: Error) -> Bool {
            if error is URLError { return true }
            let ns = error as NSError
            if ns.domain == "SupabaseFunction" {
                // Retry server errors and rate limit
                return ns.code >= 500 || ns.code == 429
            }
            return false
        }

        let data = try await Retry.withExponentialBackoff(
            .init(maxAttempts: 3, initialDelay: 0.6, multiplier: 2.0, jitter: 0.25),
            shouldRetry: { isTransient($0) }
        ) {
            try await SupabaseManager.shared.callEdgeFunction(name: "posts-create", json: payload)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(CreatePostResponse.self, from: data)
        // Fire-and-forget mentions processing
        Task.detached {
            await MentionsService.shared.processMentions(postId: response.id, content: trimmed)
        }

        // Analytics: post_created and time_to_first_post
        AnalyticsService.shared.log("post_created", [
            "anonymous": anonymous ? "true" : "false",
            "flag": flag
        ])
        let defaults = UserDefaults.standard
        let firstLaunchKey = "firstLaunchAt"
        let firstPostLoggedKey = "firstPostLogged"
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        }
        if defaults.bool(forKey: firstPostLoggedKey) == false {
            if let firstLaunchTs = defaults.object(forKey: firstLaunchKey) as? Double {
                let ms = Int((Date().timeIntervalSince1970 - firstLaunchTs) * 1000)
                AnalyticsService.shared.log("time_to_first_post_ms", ["value": "\(ms)"])
                defaults.set(true, forKey: firstPostLoggedKey)
            }
        }
    }
}
