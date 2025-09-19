import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeader(
                        user: authService.currentUser,
                        stats: viewModel.userStats,
                        onEditProfile: { showingEditProfile = true }
                    )
                    
                    // Reputation Section
                    if let user = authService.currentUser {
                        ReputationSection(user: user)
                    }
                    
                    // Activity Section
                    ActivitySection(
                        recentPosts: viewModel.recentPosts,
                        savedPosts: viewModel.savedPosts
                    )
                    
                    // Quick Actions
                    QuickActionsSection(
                        onSettingsTap: { showingSettings = true },
                        onHelpTap: { /* Handle help */ },
                        onFeedbackTap: { /* Handle feedback */ }
                    )
                }
                .padding()
            }
            .navigationTitle("Profile")
            
            .toolbar {
                ToolbarItem(placement: .trailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .task {
                await viewModel.loadUserData()
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeader: View {
    let user: User?
    let stats: UserStats?
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and basic info
            VStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    )
                
                VStack(spacing: 4) {
                    Text(user?.displayName ?? "Anonymous User")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let user = user {
                        HStack(spacing: 8) {
                            Image(systemName: user.reputationLevel.iconName)
                                .foregroundColor(Color(user.reputationLevel.color))
                            Text(user.reputationLevel.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button("Edit Profile") {
                    onEditProfile()
                }
                .buttonStyle(.bordered)
            }
            
            // Stats
            if let stats = stats {
                HStack(spacing: 32) {
                    StatItem(title: "Posts", value: "\(stats.postCount)")
                    StatItem(title: "Upvotes", value: "\(stats.totalUpvotes)")
                    StatItem(title: "Reputation", value: "\(stats.reputation)")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Reputation Section
struct ReputationSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reputation")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Current level
                HStack {
                    Image(systemName: user.reputationLevel.iconName)
                        .foregroundColor(Color(user.reputationLevel.color))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.reputationLevel.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(user.reputation) points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Progress to next level
                ReputationProgress(currentReputation: user.reputation)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ReputationProgress: View {
    let currentReputation: Int
    
    private var nextLevelThreshold: Int {
        switch currentReputation {
        case 0..<100: return 100
        case 100..<500: return 500
        case 500..<1000: return 1000
        case 1000..<2500: return 2500
        default: return 2500
        }
    }
    
    private var progress: Double {
        let previousThreshold: Int
        switch currentReputation {
        case 0..<100: previousThreshold = 0
        case 100..<500: previousThreshold = 100
        case 500..<1000: previousThreshold = 500
        case 1000..<2500: previousThreshold = 1000
        default: return 1.0
        }
        
        let range = nextLevelThreshold - previousThreshold
        let current = currentReputation - previousThreshold
        return Double(current) / Double(range)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress to next level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if currentReputation < 2500 {
                    Text("\(nextLevelThreshold - currentReputation) points to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
    }
}

// MARK: - Activity Section
struct ActivitySection: View {
    let recentPosts: [Post]
    let savedPosts: [Post]
    @State private var selectedTab: ActivityTab = .recent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Tab selector
            Picker("Activity", selection: $selectedTab) {
                ForEach(ActivityTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Content
            switch selectedTab {
            case .recent:
                RecentPostsList(posts: recentPosts)
            case .saved:
                SavedPostsList(posts: savedPosts)
            }
        }
    }
}

enum ActivityTab: String, CaseIterable {
    case recent = "Recent"
    case saved = "Saved"
}

struct RecentPostsList: View {
    let posts: [Post]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("No recent posts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else {
            LazyVStack(spacing: 8) {
                ForEach(posts.prefix(5)) { post in
                    PostSummaryRow(post: post)
                }
            }
        }
    }
}

struct SavedPostsList: View {
    let posts: [Post]
    
    var body: some View {
        if posts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "bookmark")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("No saved posts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else {
            LazyVStack(spacing: 8) {
                ForEach(posts.prefix(5)) { post in
                    PostSummaryRow(post: post)
                }
            }
        }
    }
}

struct PostSummaryRow: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(post.sentiment.color))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(post.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(post.upvotes)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    let onSettingsTap: () -> Void
    let onHelpTap: () -> Void
    let onFeedbackTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                QuickActionRow(
                    icon: "gearshape",
                    title: "Settings",
                    action: onSettingsTap
                )
                
                QuickActionRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    action: onHelpTap
                )
                
                QuickActionRow(
                    icon: "envelope",
                    title: "Send Feedback",
                    action: onFeedbackTap
                )
            }
        }
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationService())
}