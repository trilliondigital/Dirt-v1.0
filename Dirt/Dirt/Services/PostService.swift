import Foundation
import SwiftUI

public struct PostDetailData {
    public let postId: UUID
    public let username: String
    public let userInitial: String
    public let userColor: Color
    public let timestamp: String
    public let content: String
    public let imageName: String?
    public let isVerified: Bool
    public let tags: [String]
    public let upvotes: Int
    public let comments: Int
    public let shares: Int
}

final class PostService {
    static let shared = PostService()
    private init() {}

    func fetchPost(by id: UUID) async throws -> PostDetailData {
        // Simulate latency
        try await Task.sleep(nanoseconds: 250_000_000)
        // Mocked data; replace with backend call
        return PostDetailData(
            postId: id,
            username: "User\(String(id.uuidString.prefix(4)))",
            userInitial: "U",
            userColor: .blue,
            timestamp: "2h ago",
            content: "Sample content for post \(id.uuidString.prefix(8)).",
            imageName: nil,
            isVerified: Bool.random(),
            tags: ["red flag", "ghosting"].shuffled(),
            upvotes: Int.random(in: 10...500),
            comments: Int.random(in: 0...100),
            shares: Int.random(in: 0...50)
        )
    }
}
