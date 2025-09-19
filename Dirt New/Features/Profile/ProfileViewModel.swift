import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStats?
    @Published var recentPosts: [Post] = []
    @Published var savedPosts: [Post] = []
    @Published var isLoading = false
    @Published var error: ProfileError?
    
    private let supabaseManager = SupabaseManager.shared
    
    func loadUserData() async {
        isLoading = true
        error = nil
        
        do {
            async let stats = loadUserStats()
            async let recent = loadRecentPosts()
            async let saved = loadSavedPosts()
            
            userStats = await stats
            recentPosts = await recent
            savedPosts = await saved
            
        } catch {
            self.error = .loadingFailed
        }
        
        isLoading = false
    }
    
    private func loadUserStats() async -> UserStats {
        // Simulate loading user stats
        await Task.sleep(nanoseconds: 500_000_000)
        
        return UserStats(
            postCount: Int.random(in: 5...25),
            totalUpvotes: Int.random(in: 20...150),
            totalDownvotes: Int.random(in: 0...10),
            commentCount: Int.random(in: 10...50),
            reputation: Int.random(in: 50...500),
            joinDate: Date().addingTimeInterval(-Double.random(in: 86400...2592000)) // 1 day to 30 days ago
        )
    }
    
    private func loadRecentPosts() async -> [Post] {
        do {
            let posts = try await supabaseManager.fetchPosts(limit: 5)
            return posts.sorted { $0.createdAt > $1.createdAt }
        } catch {
            return []
        }
    }
    
    private func loadSavedPosts() async -> [Post] {
        // Simulate loading saved posts
        do {
            let posts = try await supabaseManager.fetchPosts(limit: 3)
            return Array(posts.shuffled().prefix(3))
        } catch {
            return []
        }
    }
}

struct UserStats {
    let postCount: Int
    let totalUpvotes: Int
    let totalDownvotes: Int
    let commentCount: Int
    let reputation: Int
    let joinDate: Date
    
    var netUpvotes: Int {
        return totalUpvotes - totalDownvotes
    }
    
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinDate)
    }
}

enum ProfileError: LocalizedError {
    case loadingFailed
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed:
            return "Failed to load profile data"
        case .updateFailed:
            return "Failed to update profile"
        }
    }
}