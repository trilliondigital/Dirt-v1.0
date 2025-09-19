import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var selectedCategory: PostCategory? = nil
    @Published var searchQuery: String = ""
    @Published var sortOrder: SortOrder = .recent
    @Published var hasMoreContent: Bool = true
    @Published var error: FeedError? = nil
    
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var cancellables = Set<AnyCancellable>()
    
    // Mock data for development - replace with actual service calls
    private let mockPosts: [Post] = [
        Post(
            authorId: UUID(),
            title: "Amazing first date at the botanical garden!",
            content: "We spent hours walking through the gardens, talking about everything from travel to our favorite books. The conversation flowed so naturally, and I could tell they were genuinely interested in what I had to say. They even remembered small details I mentioned earlier. Definitely planning a second date!",
            category: .success,
            sentiment: .positive,
            upvotes: 42,
            downvotes: 2,
            commentCount: 18,
            viewCount: 156,
            shareCount: 8,
            saveCount: 23
        ),
        Post(
            authorId: UUID(),
            title: "Red flag or am I overthinking this?",
            content: "They showed up 45 minutes late without any explanation or apology. When I asked about it, they just shrugged and said 'traffic.' Then they spent most of the dinner scrolling through their phone. Should I give them another chance or trust my gut?",
            category: .question,
            sentiment: .negative,
            upvotes: 28,
            downvotes: 5,
            commentCount: 34,
            viewCount: 89,
            shareCount: 12,
            saveCount: 15
        ),
        Post(
            authorId: UUID(),
            title: "How to handle dating app conversations?",
            content: "I'm new to dating apps and struggling with keeping conversations interesting. Any tips on good conversation starters or how to transition from chatting to meeting in person?",
            category: .advice,
            sentiment: .neutral,
            upvotes: 15,
            downvotes: 1,
            commentCount: 22,
            viewCount: 67,
            shareCount: 3,
            saveCount: 8
        ),
        Post(
            authorId: UUID(),
            title: "The coffee shop strategy that actually works",
            content: "After months of dinner dates that felt too formal, I switched to coffee dates and the difference is incredible. More relaxed atmosphere, easier to leave if there's no connection, and way less pressure. Plus you can actually hear each other talk!",
            category: .strategy,
            sentiment: .positive,
            upvotes: 67,
            downvotes: 8,
            commentCount: 29,
            viewCount: 234,
            shareCount: 19,
            saveCount: 45
        ),
        Post(
            authorId: UUID(),
            title: "Ghosted after three great dates",
            content: "We had three amazing dates, great chemistry, they even talked about future plans together. Then complete radio silence for two weeks. I'm so confused and hurt. Why do people do this?",
            category: .rant,
            sentiment: .negative,
            upvotes: 31,
            downvotes: 3,
            commentCount: 41,
            viewCount: 123,
            shareCount: 7,
            saveCount: 12
        )
    ]
    
    enum SortOrder: String, CaseIterable {
        case recent = "recent"
        case popular = "popular"
        case trending = "trending"
        
        var displayName: String {
            switch self {
            case .recent: return "Recent"
            case .popular: return "Popular"
            case .trending: return "Trending"
            }
        }
    }
    
    enum FeedError: Error, LocalizedError {
        case networkError
        case loadingFailed
        case noMoreContent
        
        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection failed"
            case .loadingFailed:
                return "Failed to load posts"
            case .noMoreContent:
                return "No more posts to load"
            }
        }
    }
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe category changes and reload posts
        $selectedCategory
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPosts()
                }
            }
            .store(in: &cancellables)
        
        // Observe search query changes
        $searchQuery
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPosts()
                }
            }
            .store(in: &cancellables)
        
        // Observe sort order changes
        $sortOrder
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPosts()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadInitialPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 0
        
        do {
            let newPosts = try await fetchPosts(page: currentPage)
            posts = newPosts
            hasMoreContent = newPosts.count == pageSize
        } catch {
            self.error = error as? FeedError ?? .loadingFailed
        }
        
        isLoading = false
    }
    
    func refreshPosts() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        error = nil
        currentPage = 0
        
        // Haptic feedback for pull-to-refresh
        await MainActor.run {
            HapticFeedback.pullToRefresh()
        }
        
        do {
            let newPosts = try await fetchPosts(page: currentPage)
            
            withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                posts = newPosts
            }
            
            hasMoreContent = newPosts.count == pageSize
        } catch {
            self.error = error as? FeedError ?? .loadingFailed
        }
        
        isRefreshing = false
    }
    
    func loadMorePosts() async {
        guard !isLoadingMore && hasMoreContent else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let newPosts = try await fetchPosts(page: currentPage)
            
            withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                posts.append(contentsOf: newPosts)
            }
            
            hasMoreContent = newPosts.count == pageSize
        } catch {
            currentPage -= 1 // Revert page increment on error
            self.error = error as? FeedError ?? .loadingFailed
        }
        
        isLoadingMore = false
    }
    
    private func fetchPosts(page: Int) async throws -> [Post] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Apply filters
        var filteredPosts = mockPosts
        
        if let category = selectedCategory {
            filteredPosts = filteredPosts.filter { $0.category == category }
        }
        
        if !searchQuery.isEmpty {
            filteredPosts = filteredPosts.filter { post in
                post.title.localizedCaseInsensitiveContains(searchQuery) ||
                post.content.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .recent:
            filteredPosts.sort { $0.createdAt > $1.createdAt }
        case .popular:
            filteredPosts.sort { $0.netScore > $1.netScore }
        case .trending:
            filteredPosts.sort { $0.engagementScore > $1.engagementScore }
        }
        
        // Simulate pagination
        let startIndex = page * pageSize
        let endIndex = min(startIndex + pageSize, filteredPosts.count)
        
        guard startIndex < filteredPosts.count else {
            return []
        }
        
        return Array(filteredPosts[startIndex..<endIndex])
    }
    
    func retryLoading() async {
        error = nil
        
        if posts.isEmpty {
            await loadInitialPosts()
        } else {
            await loadMorePosts()
        }
    }
    
    func clearError() {
        error = nil
    }
}