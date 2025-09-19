import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchResults: [Post] = []
    @Published var trendingTopics: [String] = []
    @Published var popularPosts: [Post] = []
    @Published var isLoading = false
    @Published var error: SearchError?
    
    private let supabaseManager = SupabaseManager.shared
    private var searchTask: Task<Void, Never>?
    
    func loadDefaultContent() async {
        isLoading = true
        
        do {
            // Load trending topics and popular posts
            async let topics = loadTrendingTopics()
            async let posts = loadPopularPosts()
            
            trendingTopics = await topics
            popularPosts = await posts
        } catch {
            self.error = .loadingFailed
        }
        
        isLoading = false
    }
    
    func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            await performSearch(query: query)
        }
        
        await searchTask?.value
    }
    
    private func performSearch(query: String) async {
        isLoading = true
        error = nil
        
        do {
            // Simulate search delay
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            try Task.checkCancellation()
            
            // Perform search
            let results = await searchPosts(query: query)
            
            // Check if task was cancelled before updating UI
            try Task.checkCancellation()
            
            searchResults = results
        } catch is CancellationError {
            // Task was cancelled, don't update UI
            return
        } catch {
            self.error = .searchFailed
        }
        
        isLoading = false
    }
    
    private func loadTrendingTopics() async -> [String] {
        // Simulate loading trending topics
        await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            "first-date",
            "dating-apps",
            "red-flags",
            "green-flags",
            "ghosting",
            "texting",
            "profile-tips",
            "conversation"
        ]
    }
    
    private func loadPopularPosts() async -> [Post] {
        // Simulate loading popular posts
        do {
            let posts = try await supabaseManager.fetchPosts(limit: 10)
            return posts.sorted { $0.engagementScore > $1.engagementScore }
        } catch {
            return []
        }
    }
    
    private func searchPosts(query: String) async -> [Post] {
        do {
            // Fetch all posts and filter locally (in production, this would be server-side)
            let allPosts = try await supabaseManager.fetchPosts(limit: 100)
            
            let lowercaseQuery = query.lowercased()
            
            return allPosts.filter { post in
                // Search in title
                if post.title.lowercased().contains(lowercaseQuery) {
                    return true
                }
                
                // Search in content
                if post.content.lowercased().contains(lowercaseQuery) {
                    return true
                }
                
                // Search in tags
                if post.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
                    return true
                }
                
                // Search by category
                if query.hasPrefix("category:") {
                    let categoryQuery = String(query.dropFirst(9)).lowercased()
                    return post.category.displayName.lowercased().contains(categoryQuery)
                }
                
                // Search hashtags
                if query.hasPrefix("#") {
                    let hashtagQuery = String(query.dropFirst(1)).lowercased()
                    return post.tags.contains(where: { $0.lowercased().contains(hashtagQuery) })
                }
                
                return false
            }
            .sorted { post1, post2 in
                // Sort by relevance (simplified scoring)
                let score1 = calculateRelevanceScore(post: post1, query: lowercaseQuery)
                let score2 = calculateRelevanceScore(post: post2, query: lowercaseQuery)
                return score1 > score2
            }
        } catch {
            return []
        }
    }
    
    private func calculateRelevanceScore(post: Post, query: String) -> Double {
        var score = 0.0
        
        // Title matches are more important
        if post.title.lowercased().contains(query) {
            score += 10.0
        }
        
        // Content matches
        if post.content.lowercased().contains(query) {
            score += 5.0
        }
        
        // Tag matches
        if post.tags.contains(where: { $0.lowercased().contains(query) }) {
            score += 7.0
        }
        
        // Boost score based on engagement
        score += post.engagementScore * 0.1
        
        // Boost recent posts slightly
        let daysSinceCreation = Date().timeIntervalSince(post.createdAt) / 86400
        if daysSinceCreation < 7 {
            score += 2.0
        }
        
        return score
    }
}

enum SearchError: LocalizedError {
    case loadingFailed
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Failed to load content"
        case .searchFailed:
            return "Search failed"
        }
    }
}