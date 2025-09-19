import Foundation
import Combine

// MARK: - Category Browsing View Model
@MainActor
class CategoryBrowsingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categoryStats: [PostCategory: CategoryStats] = [:]
    @Published var popularCategories: [PopularCategoryData] = []
    @Published var categoryActivity: [CategoryActivity] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let recommendationService: ContentRecommendationService
    private let postService: DiscussionPostService
    private let reviewService: ReviewCreationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        recommendationService: ContentRecommendationService = ContentRecommendationService(
            reviewService: ReviewCreationService(),
            postService: DiscussionPostService()
        ),
        postService: DiscussionPostService = DiscussionPostService(),
        reviewService: ReviewCreationService = ReviewCreationService()
    ) {
        self.recommendationService = recommendationService
        self.postService = postService
        self.reviewService = reviewService
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update stats when posts change
        postService.$posts
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.calculateCategoryStats()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load all category data
    func loadData() async {
        isLoading = true
        error = nil
        
        do {
            await calculateCategoryStats()
            await calculatePopularCategories()
            await calculateCategoryActivity()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Refresh all data
    func refreshData() async {
        await loadData()
    }
    
    /// Get content for a specific category
    func getContentForCategory(_ category: PostCategory) async -> [UUID] {
        return await recommendationService.getContentByCategory(category)
    }
    
    // MARK: - Private Methods
    
    private func calculateCategoryStats() async {
        var stats: [PostCategory: CategoryStats] = [:]
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        for category in PostCategory.allCases {
            let categoryPosts = postService.posts.filter { $0.category == category }
            let recentPosts = categoryPosts.filter { $0.createdAt > oneDayAgo }
            let totalEngagement = categoryPosts.reduce(0) { $0 + $1.upvotes + $1.commentCount }
            
            let categoryStats = CategoryStats(
                category: category,
                postCount: categoryPosts.count,
                recentPosts: recentPosts.count,
                totalEngagement: totalEngagement,
                averageRating: calculateAverageRating(for: category),
                activeUsers: calculateActiveUsers(for: category),
                todayPosts: recentPosts.count,
                isActive: recentPosts.count > 0
            )
            
            stats[category] = categoryStats
        }
        
        categoryStats = stats
    }
    
    private func calculatePopularCategories() async {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let twoDaysAgo = now.addingTimeInterval(-48 * 60 * 60)
        
        var popularData: [PopularCategoryData] = []
        
        for category in PostCategory.allCases {
            let todayPosts = postService.posts.filter { 
                $0.category == category && $0.createdAt > oneDayAgo 
            }.count
            
            let yesterdayPosts = postService.posts.filter { 
                $0.category == category && $0.createdAt > twoDaysAgo && $0.createdAt <= oneDayAgo 
            }.count
            
            let growthPercentage = yesterdayPosts > 0 ? 
                Int(((Double(todayPosts) - Double(yesterdayPosts)) / Double(yesterdayPosts)) * 100) : 
                (todayPosts > 0 ? 100 : 0)
            
            if todayPosts > 0 || growthPercentage > 0 {
                popularData.append(PopularCategoryData(
                    category: category,
                    recentPosts: todayPosts,
                    growthPercentage: growthPercentage,
                    trendingScore: Double(todayPosts) + (Double(growthPercentage) * 0.1)
                ))
            }
        }
        
        popularCategories = popularData
            .sorted { $0.trendingScore > $1.trendingScore }
            .prefix(5)
            .map { $0 }
    }
    
    private func calculateCategoryActivity() async {
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        
        var activities: [CategoryActivity] = []
        
        for category in PostCategory.allCases {
            let recentPosts = postService.posts.filter { 
                $0.category == category && $0.createdAt > oneDayAgo 
            }
            
            let totalEngagement = recentPosts.reduce(0) { 
                $0 + $1.upvotes + $1.downvotes + $1.commentCount 
            }
            
            if recentPosts.count > 0 {
                activities.append(CategoryActivity(
                    category: category,
                    newPosts: recentPosts.count,
                    totalEngagement: totalEngagement,
                    lastActivity: recentPosts.max { $0.createdAt < $1.createdAt }?.createdAt ?? now
                ))
            }
        }
        
        categoryActivity = activities
            .sorted { $0.totalEngagement > $1.totalEngagement }
    }
    
    private func calculateAverageRating(for category: PostCategory) -> Double {
        let categoryPosts = postService.posts.filter { $0.category == category }
        guard !categoryPosts.isEmpty else { return 0.0 }
        
        let totalScore = categoryPosts.reduce(0.0) { $0 + $1.engagementScore }
        return totalScore / Double(categoryPosts.count)
    }
    
    private func calculateActiveUsers(for category: PostCategory) -> Int {
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let activeUserIds = Set(postService.posts
            .filter { $0.category == category && $0.createdAt > oneDayAgo }
            .map { $0.authorId })
        
        return activeUserIds.count
    }
}

// MARK: - Category Detail View Model
@MainActor
class CategoryDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var content: [CategoryContent] = []
    @Published var categoryStats: CategoryStats?
    @Published var selectedSort: ContentSortOption = .recent
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let postService: DiscussionPostService
    private let reviewService: ReviewCreationService
    private var currentCategory: PostCategory?
    
    // MARK: - Initialization
    init(
        postService: DiscussionPostService = DiscussionPostService(),
        reviewService: ReviewCreationService = ReviewCreationService()
    ) {
        self.postService = postService
        self.reviewService = reviewService
    }
    
    // MARK: - Public Methods
    
    /// Load content for a specific category
    func loadContent(for category: PostCategory) async {
        currentCategory = category
        isLoading = true
        error = nil
        
        do {
            await loadCategoryStats(for: category)
            await loadCategoryContent(for: category)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Update sort option and reload content
    func updateSort(_ sort: ContentSortOption) async {
        selectedSort = sort
        
        if let category = currentCategory {
            await loadCategoryContent(for: category)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadCategoryStats(for category: PostCategory) async {
        let categoryPosts = postService.posts.filter { $0.category == category }
        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let recentPosts = categoryPosts.filter { $0.createdAt > oneDayAgo }
        let totalEngagement = categoryPosts.reduce(0) { $0 + $1.upvotes + $1.commentCount }
        
        let activeUserIds = Set(recentPosts.map { $0.authorId })
        
        categoryStats = CategoryStats(
            category: category,
            postCount: categoryPosts.count,
            recentPosts: recentPosts.count,
            totalEngagement: totalEngagement,
            averageRating: categoryPosts.isEmpty ? 0.0 : 
                categoryPosts.reduce(0.0) { $0 + $1.engagementScore } / Double(categoryPosts.count),
            activeUsers: activeUserIds.count,
            todayPosts: recentPosts.count,
            isActive: recentPosts.count > 0
        )
    }
    
    private func loadCategoryContent(for category: PostCategory) async {
        let categoryPosts = postService.posts.filter { $0.category == category && $0.isVisible }
        
        // Sort based on selected option
        let sortedPosts: [DatingReviewPost]
        switch selectedSort {
        case .recent:
            sortedPosts = categoryPosts.sorted { $0.createdAt > $1.createdAt }
        case .popular:
            sortedPosts = categoryPosts.sorted { $0.upvotes > $1.upvotes }
        case .trending:
            sortedPosts = categoryPosts.sorted { $0.engagementScore > $1.engagementScore }
        case .topRated:
            sortedPosts = categoryPosts.sorted { $0.netScore > $1.netScore }
        }
        
        // Convert to CategoryContent
        content = sortedPosts.map { post in
            CategoryContent(
                id: post.id,
                title: post.title,
                preview: String(post.content.prefix(150)) + (post.content.count > 150 ? "..." : ""),
                type: .post,
                upvotes: post.upvotes,
                comments: post.commentCount,
                timeAgo: formatTimeAgo(post.createdAt),
                category: post.category
            )
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Data Models

struct CategoryStats {
    let category: PostCategory
    let postCount: Int
    let recentPosts: Int
    let totalEngagement: Int
    let averageRating: Double
    let activeUsers: Int
    let todayPosts: Int
    let isActive: Bool
}

struct PopularCategoryData {
    let category: PostCategory
    let recentPosts: Int
    let growthPercentage: Int
    let trendingScore: Double
}

struct CategoryActivity {
    let category: PostCategory
    let newPosts: Int
    let totalEngagement: Int
    let lastActivity: Date
}

struct CategoryContent: Identifiable {
    let id: UUID
    let title: String
    let preview: String
    let type: ContentType
    let upvotes: Int
    let comments: Int
    let timeAgo: String
    let category: PostCategory
}