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
            throw NSError(domain: "Post", code: 400, userInfo: [NSLocalizedDescriptionKey: "Message must be 1–500 characters."])
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
        let data = try await SupabaseManager.shared.callEdgeFunction(name: "posts-create", json: payload)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        _ = try decoder.decode(CreatePostResponse.self, from: data)
    }
}
