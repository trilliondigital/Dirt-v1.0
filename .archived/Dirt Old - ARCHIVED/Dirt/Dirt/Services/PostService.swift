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

final class PostService: ErrorHandlingService {
    static let shared = PostService()
    private init() {}

    func fetchPost(by id: UUID) async throws -> PostDetailData {
        do {
            // Simulate latency
            try await Task.sleep(nanoseconds: 250_000_000)
            
            // Simulate potential network errors
            if Bool.random() && id.uuidString.hasPrefix("error") {
                throw URLError(.notConnectedToInternet)
            }
            
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
        } catch {
            handleError(error, context: "PostService.fetchPost(id: \(id))")
            throw error
        }
    }
    
    func createPost(content: String, tags: [String]) async throws {
        do {
            // Simulate latency
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Simulate validation error
            if content.isEmpty {
                throw AppError.validation(.required("Content"))
            }
            
            if content.count > 280 {
                throw AppError.validation(.tooLong("Content", 280))
            }
            
            // Simulate success
            await MainActor.run {
                ErrorHandlingManager.shared.presentSuccess("Post created successfully!")
            }
            
        } catch {
            handleError(error, context: "PostService.createPost")
            throw error
        }
    }
    
    func deletePost(id: UUID) async throws {
        do {
            // Simulate latency
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // Simulate success
            await MainActor.run {
                ErrorHandlingManager.shared.presentSuccess("Post deleted successfully")
            }
            
        } catch {
            handleError(error, context: "PostService.deletePost(id: \(id))")
            throw error
        }
    }
}
