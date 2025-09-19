import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var selectedFilter: FeedFilter = .latest
    @Published var selectedCategory: PostCategory?
    @Published var error: FeedError?
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Reload posts when filter changes
        Publishers.CombineLatest($selectedFilter, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                Task {
                    await self?.loadPosts()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadPosts() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedPosts = try await supabaseManager.fetchPosts(
                category: selectedCategory,
                limit: 20
            )
            
            posts = applyFilter(to: fetchedPosts)
        } catch {
            self.error = .loadingFailed
        }
        
        isLoading = false
    }
    
    func refreshPosts() async {
        await loadPosts()
    }
    
    func upvotePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        posts[index].upvotes += 1
        
        Task {
            do {
                _ = try await supabaseManager.updatePost(posts[index])
            } catch {
                // Revert on error
                posts[index].upvotes -= 1
                self.error = .actionFailed
            }
        }
    }
    
    func downvotePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        posts[index].downvotes += 1
        
        Task {
            do {
                _ = try await supabaseManager.updatePost(posts[index])
            } catch {
                // Revert on error
                posts[index].downvotes -= 1
                self.error = .actionFailed
            }
        }
    }
    
    func savePost(_ post: Post) {
        // Implement save functionality
        print("Saving post: \(post.title)")
    }
    
    func sharePost(_ post: Post) {
        // Implement share functionality
        print("Sharing post: \(post.title)")
    }
    
    func reportPost(_ post: Post) {
        // Implement report functionality
        print("Reporting post: \(post.title)")
    }
    
    private func applyFilter(to posts: [Post]) -> [Post] {
        let filteredPosts = posts.filter { post in
            // Apply category filter if selected
            if let category = selectedCategory {
                return post.category == category
            }
            return true
        }
        
        // Apply sort filter
        switch selectedFilter {
        case .latest:
            return filteredPosts.sorted { $0.createdAt > $1.createdAt }
        case .trending:
            return filteredPosts.sorted { $0.engagementScore > $1.engagementScore }
        case .popular:
            return filteredPosts.sorted { $0.upvotes > $1.upvotes }
        case .controversial:
            return filteredPosts.sorted { abs($0.upvotes - $0.downvotes) < abs($1.upvotes - $1.downvotes) }
        }
    }
}

enum FeedFilter: String, CaseIterable {
    case latest = "Latest"
    case trending = "Trending"
    case popular = "Popular"
    case controversial = "Controversial"
    
    var displayName: String {
        return rawValue
    }
    
    var iconName: String {
        switch self {
        case .latest:
            return "clock"
        case .trending:
            return "flame"
        case .popular:
            return "arrow.up.circle"
        case .controversial:
            return "exclamationmark.triangle"
        }
    }
}

enum FeedError: LocalizedError {
    case loadingFailed
    case actionFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Failed to load posts"
        case .actionFailed:
            return "Action failed"
        }
    }
}