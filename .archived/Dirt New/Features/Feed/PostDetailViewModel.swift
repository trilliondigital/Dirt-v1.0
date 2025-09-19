import SwiftUI
import Combine

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoadingComments = false
    @Published var error: PostDetailError?
    
    private let supabaseManager = SupabaseManager.shared
    
    func loadComments(for post: Post) async {
        isLoadingComments = true
        error = nil
        
        // Simulate loading comments
        await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock comments data
        comments = generateMockComments(for: post)
        isLoadingComments = false
    }
    
    func addComment(to post: Post, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newComment = Comment(
            postId: post.id,
            authorId: UUID(),
            content: text.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        comments.insert(newComment, at: 0)
        
        // TODO: Save to Supabase
        Task {
            // Simulate API call
            await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    func savePost(_ post: Post) {
        // TODO: Implement save functionality
        print("Saving post: \(post.title)")
    }
    
    func sharePost(_ post: Post) {
        // TODO: Implement share functionality
        print("Sharing post: \(post.title)")
    }
    
    private func generateMockComments(for post: Post) -> [Comment] {
        let sampleComments = [
            "Great story! Thanks for sharing your experience.",
            "This gives me hope. I've been struggling with dating lately.",
            "What app did you use? I'm curious about your approach.",
            "Congrats! It's nice to hear a success story for once.",
            "Any tips for someone who's new to dating apps?",
            "This is exactly what I needed to read today. Thank you!"
        ]
        
        return (0..<Int.random(in: 0...6)).map { index in
            Comment(
                postId: post.id,
                authorId: UUID(),
                content: sampleComments[index % sampleComments.count],
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...86400)), // Random time in last day
                upvotes: Int.random(in: 0...15)
            )
        }.sorted { $0.createdAt > $1.createdAt }
    }
}

enum PostDetailError: LocalizedError {
    case loadingCommentsFailed
    case addingCommentFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingCommentsFailed:
            return "Failed to load comments"
        case .addingCommentFailed:
            return "Failed to add comment"
        }
    }
}