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
    @Published var isLoadingMore = false
    @Published var isRefreshing = false
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 0
    private let pageSize = 20
    private var isLoadingMoreContent = false
    
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
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        currentPage = 0
        hasMoreContent = true
        
        do {
            // Add artificial delay to show loading state
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            let (fetchedPosts, fetchedReviews) = try await loadContent()
            
            posts = fetchedPosts
            reviews = fetchedReviews
            feedItems = createMixedFeed(posts: fetchedPosts, reviews: fetchedReviews)
            
            // Determine if there's more content
            hasMoreContent = fetchedPosts.count >= pageSize || fetchedReviews.count >= pageSize
            
        } catch {
            self.error = .loadingFailed
            print("Error loading feed: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshFeed() async {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        error = nil
        
        // Reset pagination
        currentPage = 0
        hasMoreContent = true
        
        do {
            let (fetchedPosts, fetchedReviews) = try await loadContent()
            
            posts = fetchedPosts
            reviews = fetchedReviews
            feedItems = createMixedFeed(posts: fetchedPosts, reviews: fetchedReviews)
            
            hasMoreContent = fetchedPosts.count >= pageSize || fetchedReviews.count >= pageSize
            
        } catch {
            self.error = .loadingFailed
            print("Error refreshing feed: \(error)")
        }
        
        isRefreshing = false
    }
    
    func loadMoreContent() async {
        guard hasMoreContent && !isLoading && !isLoadingMoreContent else { return }
        
        isLoadingMoreContent = true
        isLoadingMore = true
        currentPage += 1
        
        do {
            // Add small delay for better UX
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            let (morePosts, moreReviews) = try await loadContent()
            
            if morePosts.isEmpty && moreReviews.isEmpty {
                hasMoreContent = false
            } else {
                posts.append(contentsOf: morePosts)
                reviews.append(contentsOf: moreReviews)
                
                let newItems = createMixedFeed(posts: morePosts, reviews: moreReviews)
                feedItems.append(contentsOf: newItems)
                
                // Check if we've reached the end
                hasMoreContent = morePosts.count >= pageSize || moreReviews.count >= pageSize
            }
            
        } catch {
            self.error = .actionFailed
            print("Error loading more content: \(error)")
        }
        
        isLoadingMore = false
        isLoadingMoreContent = false
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
        let postTitles = [
            "First date went amazing!",
            "Red flags I wish I'd noticed earlier",
            "How to handle dating anxiety?",
            "Best coffee shops for dates in the city",
            "Dating app success story",
            "When should you have 'the talk'?",
            "Dealing with ghosting - need advice",
            "Perfect date night ideas for winter",
            "How to split the bill gracefully",
            "Meeting their friends for the first time"
        ]
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, postTitles.count * 3) // Allow for multiple pages
        
        return (startIndex..<endIndex).map { index in
            let titleIndex = index % postTitles.count
            Post(
                authorId: UUID(),
                title: postTitles[titleIndex],
                content: "This is a detailed post about dating experiences, advice, and insights from the community. It contains valuable information that others can learn from and engage with.",
                category: categories.randomElement() ?? .general,
                sentiment: sentiments.randomElement() ?? .neutral,
                tags: ["dating", "advice", "experience", "relationships", "tips"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800) - Double(index * 3600)),
                upvotes: Int.random(in: 0...100),
                downvotes: Int.random(in: 0...20),
                commentCount: Int.random(in: 0...50),
                viewCount: Int.random(in: 50...500),
                shareCount: Int.random(in: 0...25),
                saveCount: Int.random(in: 0...15)
            )
        }
    }
    
    private func generateMockReviews() -> [Review] {
        let reviewTitles = [
            "Amazing Coffee Date at Blue Bottle",
            "Perfect Dinner at Italian Bistro",
            "Fun Mini Golf Adventure",
            "Romantic Walk in Golden Gate Park",
            "Great Museum Visit at SFMOMA",
            "Cozy Bookstore Date at City Lights",
            "Exciting Escape Room Challenge",
            "Beautiful Sunset at Crissy Field",
            "Wine Tasting in Napa Valley",
            "Concert at the Fillmore"
        ]
        
        let locations = [
            "San Francisco, CA",
            "Oakland, CA",
            "Berkeley, CA",
            "Palo Alto, CA",
            "San Jose, CA"
        ]
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, reviewTitles.count * 3) // Allow for multiple pages
        
        return (startIndex..<endIndex).map { index in
            let titleIndex = index % reviewTitles.count
            Review(
                authorId: "user_\(index)",
                authorName: "User \(index + 1)",
                title: reviewTitles[titleIndex],
                content: "This was an incredible experience that I would highly recommend to anyone looking for a great date idea. The atmosphere was perfect, the service was excellent, and we had such a wonderful time together. Would definitely go back!",
                rating: Double.random(in: 3.0...5.0),
                tags: ["coffee", "romantic", "fun", "date", "recommended"].shuffled().prefix(Int.random(in: 1...4)).map(String.init),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800) - Double(index * 3600)),
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...20),
                location: locations.randomElement(),
                venue: reviewTitles[titleIndex].components(separatedBy: " at ").last,
                cost: CostLevel.allCases.randomElement(),
                duration: TimeInterval.random(in: 3600...14400), // 1-4 hours
                viewCount: Int.random(in: 25...300),
                shareCount: Int.random(in: 0...20),
                saveCount: Int.random(in: 0...10)
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
    case networkError
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Unable to load content. Please check your connection and try again."
        case .actionFailed:
            return "Action failed. Please try again."
        case .networkError:
            return "Network error occurred. Please check your internet connection."
        case .noConnection:
            return "No internet connection. Please connect to the internet and try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .loadingFailed, .networkError, .noConnection:
            return "Check your internet connection and tap 'Try Again'"
        case .actionFailed:
            return "Please try the action again"
        }
    }
}

// MARK: - Content Type

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