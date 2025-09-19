import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var reviews: [Review] = []
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var selectedFilter: FeedFilter = .latest
    @Published var selectedCategory: PostCategory?
    @Published var selectedContentType: ContentType = .all
    @Published var error: FeedError?
    @Published var hasMoreContent = true
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Reload content when filters change
        Publishers.CombineLatest3($selectedFilter, $selectedCategory, $selectedContentType)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                Task {
                    await self?.loadFeed()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadFeed() async {
        isLoading = true
        error = nil
        currentPage = 0
        hasMoreContent = true
        
        do {
            let (fetchedPosts, fetchedReviews) = try await loadContent()
            
            posts = fetchedPosts
            reviews = fetchedReviews
            feedItems = createMixedFeed(posts: fetchedPosts, reviews: fetchedReviews)
            
        } catch {
            self.error = .loadingFailed
        }
        
        isLoading = false
    }
    
    func refreshFeed() async {
        await loadFeed()
    }
    
    func loadMoreContent() async {
        guard hasMoreContent && !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let (morePosts, moreReviews) = try await loadContent()
            
            if morePosts.isEmpty && moreReviews.isEmpty {
                hasMoreContent = false
            } else {
                posts.append(contentsOf: morePosts)
                reviews.append(contentsOf: moreReviews)
                
                let newItems = createMixedFeed(posts: morePosts, reviews: moreReviews)
                feedItems.append(contentsOf: newItems)
            }
            
        } catch {
            self.error = .loadingFailed
        }
        
        isLoading = false
    }
    
    private func loadContent() async throws -> ([Post], [Review]) {
        async let postsTask = loadPosts()
        async let reviewsTask = loadReviews()
        
        let (posts, reviews) = try await (postsTask, reviewsTask)
        return (posts, reviews)
    }
    
    private func loadPosts() async throws -> [Post] {
        // For now, return mock data - replace with actual API call
        return generateMockPosts()
    }
    
    private func loadReviews() async throws -> [Review] {
        // For now, return mock data - replace with actual API call
        return generateMockReviews()
    }
    
    private func createMixedFeed(posts: [Post], reviews: [Review]) -> [FeedItem] {
        var items: [FeedItem] = []
        
        switch selectedContentType {
        case .all:
            // Mix posts and reviews
            items.append(contentsOf: posts.map { FeedItem(type: .post($0), timestamp: $0.createdAt) })
            items.append(contentsOf: reviews.map { FeedItem(type: .review($0), timestamp: $0.createdAt) })
        case .posts:
            items = posts.map { FeedItem(type: .post($0), timestamp: $0.createdAt) }
        case .reviews:
            items = reviews.map { FeedItem(type: .review($0), timestamp: $0.createdAt) }
        }
        
        return applyFilter(to: items)
    }
    
    func upvoteItem(_ item: FeedItem) {
        switch item.type {
        case .post(let post):
            upvotePost(post)
        case .review:
            break // Reviews don't have upvotes, they have likes
        }
    }
    
    func downvoteItem(_ item: FeedItem) {
        switch item.type {
        case .post(let post):
            downvotePost(post)
        case .review:
            break // Reviews don't have downvotes
        }
    }
    
    func likeItem(_ item: FeedItem) {
        switch item.type {
        case .post:
            break // Posts don't have likes, they have upvotes
        case .review(let review):
            likeReview(review)
        }
    }
    
    func saveItem(_ item: FeedItem) {
        switch item.type {
        case .post(let post):
            savePost(post)
        case .review(let review):
            saveReview(review)
        }
    }
    
    func shareItem(_ item: FeedItem) {
        switch item.type {
        case .post(let post):
            sharePost(post)
        case .review(let review):
            shareReview(review)
        }
    }
    
    func reportItem(_ item: FeedItem) {
        switch item.type {
        case .post(let post):
            reportPost(post)
        case .review(let review):
            reportReview(review)
        }
    }
    
    private func upvotePost(_ post: Post) {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }),
              let feedIndex = feedItems.firstIndex(where: { 
                  if case .post(let feedPost) = $0.type {
                      return feedPost.id == post.id
                  }
                  return false
              }) else { return }
        
        posts[postIndex].upvotes += 1
        feedItems[feedIndex] = FeedItem(type: .post(posts[postIndex]), timestamp: posts[postIndex].createdAt)
        
        Task {
            do {
                _ = try await supabaseManager.updatePost(posts[postIndex])
            } catch {
                // Revert on error
                posts[postIndex].upvotes -= 1
                feedItems[feedIndex] = FeedItem(type: .post(posts[postIndex]), timestamp: posts[postIndex].createdAt)
                self.error = .actionFailed
            }
        }
    }
    
    private func downvotePost(_ post: Post) {
        guard let postIndex = posts.firstIndex(where: { $0.id == post.id }),
              let feedIndex = feedItems.firstIndex(where: { 
                  if case .post(let feedPost) = $0.type {
                      return feedPost.id == post.id
                  }
                  return false
              }) else { return }
        
        posts[postIndex].downvotes += 1
        feedItems[feedIndex] = FeedItem(type: .post(posts[postIndex]), timestamp: posts[postIndex].createdAt)
        
        Task {
            do {
                _ = try await supabaseManager.updatePost(posts[postIndex])
            } catch {
                // Revert on error
                posts[postIndex].downvotes -= 1
                feedItems[feedIndex] = FeedItem(type: .post(posts[postIndex]), timestamp: posts[postIndex].createdAt)
                self.error = .actionFailed
            }
        }
    }
    
    private func likeReview(_ review: Review) {
        guard let reviewIndex = reviews.firstIndex(where: { $0.id == review.id }),
              let feedIndex = feedItems.firstIndex(where: { 
                  if case .review(let feedReview) = $0.type {
                      return feedReview.id == review.id
                  }
                  return false
              }) else { return }
        
        reviews[reviewIndex].isLiked.toggle()
        reviews[reviewIndex].likeCount += reviews[reviewIndex].isLiked ? 1 : -1
        feedItems[feedIndex] = FeedItem(type: .review(reviews[reviewIndex]), timestamp: reviews[reviewIndex].createdAt)
        
        // TODO: Implement API call for review likes
    }
    
    private func savePost(_ post: Post) {
        print("Saving post: \(post.title)")
        // TODO: Implement save functionality
    }
    
    private func saveReview(_ review: Review) {
        print("Saving review: \(review.title)")
        // TODO: Implement save functionality
    }
    
    private func sharePost(_ post: Post) {
        print("Sharing post: \(post.title)")
        // TODO: Implement share functionality
    }
    
    private func shareReview(_ review: Review) {
        print("Sharing review: \(review.title)")
        // TODO: Implement share functionality
    }
    
    private func reportPost(_ post: Post) {
        print("Reporting post: \(post.title)")
        // TODO: Implement report functionality
    }
    
    private func reportReview(_ review: Review) {
        print("Reporting review: \(review.title)")
        // TODO: Implement report functionality
    }
    
    private func applyFilter(to items: [FeedItem]) -> [FeedItem] {
        let filteredItems = items.filter { item in
            // Apply category filter if selected
            if let category = selectedCategory {
                switch item.type {
                case .post(let post):
                    return post.category == category
                case .review:
                    return false // Reviews don't have post categories
                }
            }
            return true
        }
        
        // Apply sort filter
        switch selectedFilter {
        case .latest:
            return filteredItems.sorted { $0.timestamp > $1.timestamp }
        case .trending:
            return filteredItems.sorted { $0.engagementScore > $1.engagementScore }
        case .popular:
            return filteredItems.sorted { $0.popularityScore > $1.popularityScore }
        case .controversial:
            return filteredItems.sorted { $0.controversyScore > $1.controversyScore }
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockPosts() -> [Post] {
        let categories = PostCategory.allCases
        let sentiments = PostSentiment.allCases
        
        return (0..<10).map { index in
            Post(
                authorId: UUID(),
                title: "Dating Experience #\(index + 1)",
                content: "This is a sample post about dating experiences and advice for the community.",
                category: categories.randomElement() ?? .general,
                sentiment: sentiments.randomElement() ?? .neutral,
                tags: ["dating", "advice", "experience"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)),
                upvotes: Int.random(in: 0...100),
                downvotes: Int.random(in: 0...20),
                commentCount: Int.random(in: 0...50)
            )
        }
    }
    
    private func generateMockReviews() -> [Review] {
        let titles = [
            "Amazing Coffee Date at Local Café",
            "Perfect Dinner Experience Downtown",
            "Fun Mini Golf Adventure",
            "Romantic Walk in the Park",
            "Great Museum Visit Together"
        ]
        
        return titles.enumerated().map { index, title in
            Review(
                authorId: "user_\(index)",
                authorName: "User \(index + 1)",
                title: title,
                content: "This was an incredible experience that I would highly recommend to anyone looking for a great date idea. The atmosphere was perfect and we had such a wonderful time together.",
                rating: Double.random(in: 3.0...5.0),
                tags: ["coffee", "romantic", "fun", "date"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)),
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...20),
                location: "San Francisco, CA"
            )
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
// MARK
: - Content Type

enum ContentType: String, CaseIterable {
    case all = "All"
    case posts = "Posts"
    case reviews = "Reviews"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Feed Item

struct FeedItem: Identifiable {
    let id = UUID()
    let type: FeedItemType
    let timestamp: Date
    
    var engagementScore: Double {
        switch type {
        case .post(let post):
            return post.engagementScore
        case .review(let review):
            return review.engagementScore
        }
    }
    
    var popularityScore: Double {
        switch type {
        case .post(let post):
            return Double(post.upvotes)
        case .review(let review):
            return Double(review.likeCount)
        }
    }
    
    var controversyScore: Double {
        switch type {
        case .post(let post):
            let total = post.upvotes + post.downvotes
            return total > 0 ? Double(abs(post.upvotes - post.downvotes)) / Double(total) : 0
        case .review:
            return 0 // Reviews don't have controversy scores
        }
    }
}

enum FeedItemType {
    case post(Post)
    case review(Review)
}