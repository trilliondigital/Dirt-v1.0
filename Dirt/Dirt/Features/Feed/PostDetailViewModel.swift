import SwiftUI
import Combine

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoadingComments: Bool = false
    @Published var isSubmittingComment: Bool = false
    @Published var newCommentText: String = ""
    @Published var isLiked: Bool = false
    @Published var isDisliked: Bool = false
    @Published var isSaved: Bool = false
    @Published var error: PostDetailError? = nil
    
    private var currentPost: Post?
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var hasMoreComments: Bool = true
    
    enum PostDetailError: Error, LocalizedError {
        case loadingFailed
        case commentSubmissionFailed
        case actionFailed
        
        var errorDescription: String? {
            switch self {
            case .loadingFailed:
                return "Failed to load post details"
            case .commentSubmissionFailed:
                return "Failed to submit comment"
            case .actionFailed:
                return "Action failed"
            }
        }
    }
    
    var shareText: String {
        guard let post = currentPost else { return "" }
        return "Check out this post on Dirt: \"\(post.title)\" - \(post.content.prefix(100))..."
    }
    
    // Mock comments for development
    private let mockComments: [Comment] = [
        Comment(
            id: UUID(),
            postId: UUID(),
            authorId: UUID(),
            content: "This is so relatable! I had a similar experience last month. The key is really finding someone who values genuine conversation over small talk.",
            likeCount: 12,
            replyCount: 3,
            replies: [
                Comment(
                    id: UUID(),
                    postId: UUID(),
                    authorId: UUID(),
                    content: "Absolutely agree! Quality conversation is everything.",
                    likeCount: 5,
                    replyCount: 0
                ),
                Comment(
                    id: UUID(),
                    postId: UUID(),
                    authorId: UUID(),
                    content: "Where do you usually meet people who are good at conversation?",
                    likeCount: 2,
                    replyCount: 0
                )
            ]
        ),
        Comment(
            id: UUID(),
            postId: UUID(),
            authorId: UUID(),
            content: "Coffee dates are definitely the way to go! Less pressure and you can actually hear each other talk. Plus it's easier to extend if things are going well or wrap up if they're not.",
            likeCount: 8,
            replyCount: 1,
            replies: [
                Comment(
                    id: UUID(),
                    postId: UUID(),
                    authorId: UUID(),
                    content: "And way more budget-friendly than dinner dates!",
                    likeCount: 3,
                    replyCount: 0
                )
            ]
        ),
        Comment(
            id: UUID(),
            postId: UUID(),
            authorId: UUID(),
            content: "Love this positive energy! It's so refreshing to hear success stories. Gives me hope for my own dating journey 😊",
            likeCount: 15,
            replyCount: 0
        )
    ]
    
    func loadPostDetails(_ post: Post) async {
        currentPost = post
        
        // Load initial state (in a real app, this would come from a service)
        isLiked = false // Check if user has liked this post
        isDisliked = false // Check if user has disliked this post
        isSaved = false // Check if user has saved this post
        
        await loadComments()
    }
    
    func loadComments() async {
        guard !isLoadingComments else { return }
        
        isLoadingComments = true
        error = nil
        currentPage = 0
        
        do {
            let newComments = try await fetchComments(page: currentPage)
            comments = newComments
            hasMoreComments = newComments.count == pageSize
        } catch {
            self.error = .loadingFailed
        }
        
        isLoadingComments = false
    }
    
    func loadMoreComments() async {
        guard !isLoadingComments && hasMoreComments else { return }
        
        isLoadingComments = true
        currentPage += 1
        
        do {
            let newComments = try await fetchComments(page: currentPage)
            
            withAnimation(.easeInOut(duration: AnimationPreferences.standardDuration)) {
                comments.append(contentsOf: newComments)
            }
            
            hasMoreComments = newComments.count == pageSize
        } catch {
            currentPage -= 1
            self.error = .loadingFailed
        }
        
        isLoadingComments = false
    }
    
    private func fetchComments(page: Int) async throws -> [Comment] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return mock comments for the first page
        if page == 0 {
            return mockComments
        } else {
            return [] // No more comments for subsequent pages
        }
    }
    
    func submitComment(for post: Post) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isSubmittingComment else { return }
        
        isSubmittingComment = true
        
        do {
            let comment = try await createComment(
                postId: post.id,
                content: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            withAnimation(.easeInOut(duration: AnimationPreferences.standardDuration)) {
                comments.insert(comment, at: 0)
            }
            
            newCommentText = ""
            HapticFeedback.successAction()
        } catch {
            self.error = .commentSubmissionFailed
            HapticFeedback.errorOccurred()
        }
        
        isSubmittingComment = false
    }
    
    private func createComment(postId: UUID, content: String) async throws -> Comment {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return Comment(
            id: UUID(),
            postId: postId,
            authorId: UUID(),
            content: content,
            likeCount: 0,
            replyCount: 0
        )
    }
    
    func toggleLike(for post: Post) async {
        let wasLiked = isLiked
        
        // Optimistic update
        withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
            isLiked.toggle()
            if isLiked && isDisliked {
                isDisliked = false
            }
        }
        
        HapticFeedback.likeAction()
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)
            // In a real app, make API call here
        } catch {
            // Revert on error
            withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
                isLiked = wasLiked
            }
            self.error = .actionFailed
            HapticFeedback.errorOccurred()
        }
    }
    
    func toggleDislike(for post: Post) async {
        let wasDisliked = isDisliked
        
        // Optimistic update
        withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
            isDisliked.toggle()
            if isDisliked && isLiked {
                isLiked = false
            }
        }
        
        HapticFeedback.likeAction()
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)
            // In a real app, make API call here
        } catch {
            // Revert on error
            withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
                isDisliked = wasDisliked
            }
            self.error = .actionFailed
            HapticFeedback.errorOccurred()
        }
    }
    
    func savePost(_ post: Post) async {
        let wasSaved = isSaved
        
        // Optimistic update
        withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
            isSaved.toggle()
        }
        
        HapticFeedback.saveAction()
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000)
            // In a real app, make API call here
        } catch {
            // Revert on error
            withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
                isSaved = wasSaved
            }
            self.error = .actionFailed
            HapticFeedback.errorOccurred()
        }
    }
    
    func reportPost(_ post: Post, reason: String) async {
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)
            // In a real app, make API call here
            
            HapticFeedback.successAction()
        } catch {
            self.error = .actionFailed
            HapticFeedback.errorOccurred()
        }
    }
    
    func clearError() {
        error = nil
    }
}