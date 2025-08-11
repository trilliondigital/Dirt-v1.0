import Foundation

final class MediaService {
    static let shared = MediaService()
    private init() {}

    struct MediaProcessResponse: Codable { let hash: String; let stripped: Bool }

    func processMedia(at url: URL) async throws -> MediaProcessResponse {
        let payload: [String: Any] = ["url": url.absoluteString]
        let data = try await SupabaseManager.shared.callEdgeFunction(name: "media-process", json: payload)
        return try JSONDecoder().decode(MediaProcessResponse.self, from: data)
    }
}
