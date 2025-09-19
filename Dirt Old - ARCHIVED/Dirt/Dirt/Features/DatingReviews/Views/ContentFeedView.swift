import SwiftUI

/// A unified feed view that displays both reviews and discussion posts with filtering and sorting
struct ContentFeedView: View {
    @State private var selectedFilter: ContentFilter = .all
    @State private var selectedSort: SortOption = .popular
    @State private var reviews: [Review] = []
    @State private var posts: [DatingReviewPost] = []
    @State private var userVotes: [UUID: VoteType] = [:]
    @State private var isLoading = false
    @State private var showingFilters = false
    
    let onReviewTap: (Review) -> Void
    let onPostTap: (DatingReviewPost) -> Void
    let onVote: (UUID, ContentType, VoteType) -> Void
    let onComment: (UUID, ContentType) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and sort controls
                filterControls
                
                // Content feed
                ScrollView {
                    LazyVStack(spacing: UISpacing.md) {
                        ForEach(sortedContent, id: \.id) { item in
                            switch item {
                            case .review(let review):
                                ReviewCardView(
                                    review: review,
                                    currentUserVote: userVotes[review.id] ?? .none,
                                    onUpvote: { onVote(review.id, .review, .upvote) },
                                    onDownvote: { onVote(review.id, .review, .downvote) },
                                    onComment: { onComment(review.id, .review) },
                                    onTap: { onReviewTap(review) }
                                )
                                
                            case .post(let post):
                                DiscussionPostCardView(
                                    post: post,
                                    currentUserVote: userVotes[post.id] ?? .none,
                                    onUpvote: { onVote(post.id, .post, .upvote) },
                                    onDownvote: { onVote(post.id, .post, .downvote) },
                                    onComment: { onComment(post.id, .post) },
                                    onTap: { onPostTap(post) }
                                )
                            }
                        }
                        
                        // Loading indicator
                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await refreshContent()
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                FilterSheetView(
                    selectedFilter: $selectedFilter,
                    selectedSort: $selectedSort
                )
            }
        }
        .task {
            await loadContent()
        }
    }
    
    // MARK: - Filter Controls
    
    private var filterControls: some View {
        VStack(spacing: UISpacing.sm) {
            // Quick filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UISpacing.xs) {
                    ForEach(ContentFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Sort and advanced filter controls
            HStack {
                // Sort picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { selectedSort = option }) {
                            HStack {
                                Text(option.displayName)
                                if selectedSort == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: UISpacing.xs) {
                        Image(systemName: selectedSort.iconName)
                            .font(.caption)
                        
                        Text(selectedSort.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(UIColors.accentPrimary)
                    .padding(.horizontal, UISpacing.sm)
                    .padding(.vertical, UISpacing.xs)
                    .background(MaterialDesignSystem.GlassColors.primary, in: Capsule())
                }
                
                Spacer()
                
                // Advanced filters button
                Button(action: { showingFilters = true }) {
                    HStack(spacing: UISpacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        
                        Text("Filters")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(UIColors.secondaryLabel)
                    .padding(.horizontal, UISpacing.sm)
                    .padding(.vertical, UISpacing.xs)
                    .background(MaterialDesignSystem.Glass.ultraThin, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)
        }
        .padding(.vertical, UISpacing.sm)
        .background(MaterialDesignSystem.Glass.ultraThin)
    }
    
    // MARK: - Content Processing
    
    private var sortedContent: [ContentItem] {
        let reviewItems = reviews
            .filter { matchesFilter($0) }
            .map { ContentItem.review($0) }
        
        let postItems = posts
            .filter { matchesFilter($0) }
            .map { ContentItem.post($0) }
        
        let allItems = reviewItems + postItems
        
        return allItems.sorted { item1, item2 in
            switch selectedSort {
            case .popular:
                return item1.engagementScore > item2.engagementScore
            case .recent:
                return item1.createdAt > item2.createdAt
            case .relevance:
                return item1.netScore > item2.netScore
            case .oldest:
                return item1.createdAt < item2.createdAt
            }
        }
    }
    
    private func matchesFilter(_ review: Review) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .reviews:
            return true
        case .posts:
            return false
        case .positive:
            return review.ratings.averageRating >= 3.5
        case .negative:
            return review.ratings.averageRating < 2.5
        case .recent:
            return Calendar.current.isDate(review.createdAt, inSameDayAs: Date()) ||
                   Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains(review.createdAt) == true
        }
    }
    
    private func matchesFilter(_ post: DatingReviewPost) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .reviews:
            return false
        case .posts:
            return true
        case .positive:
            return post.netScore > 0
        case .negative:
            return post.netScore < 0
        case .recent:
            return Calendar.current.isDate(post.createdAt, inSameDayAs: Date()) ||
                   Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains(post.createdAt) == true
        }
    }
    
    // MARK: - Data Loading
    
    private func loadContent() async {
        isLoading = true
        
        // Simulate API calls - replace with actual service calls
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock data
        reviews = [
            Review(
                authorId: UUID(),
                profileScreenshots: ["https://example.com/screenshot1.jpg"],
                ratings: ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4),
                content: "Had a great conversation with this person. Their photos were accurate and the bio was interesting.",
                tags: ["Green Flag", "Good Conversation", "Authentic"],
                datingApp: .tinder,
                upvotes: 15,
                downvotes: 2,
                commentCount: 8
            ),
            Review(
                authorId: UUID(),
                profileScreenshots: ["https://example.com/screenshot2.jpg"],
                ratings: ReviewRatings(photos: 2, bio: 1, conversation: 1, overall: 1),
                content: "Complete catfish situation. Photos were heavily filtered and the conversation was terrible.",
                tags: ["Red Flag", "Catfish", "Poor Conversation"],
                datingApp: .bumble,
                upvotes: 3,
                downvotes: 1,
                commentCount: 12
            )
        ]
        
        posts = [
            DatingReviewPost(
                authorId: UUID(),
                title: "How to improve your dating profile photos?",
                content: "I've been struggling with getting matches on dating apps. What are some tips for taking better photos?",
                category: .question,
                tags: ["Photos", "Profile", "Dating 101"],
                upvotes: 24,
                downvotes: 3,
                commentCount: 15
            ),
            DatingReviewPost(
                authorId: UUID(),
                title: "Success Story: Finally found someone genuine!",
                content: "After months of disappointing dates, I finally met someone who's actually interested in getting to know me.",
                category: .success,
                tags: ["Success", "Long Term Potential", "Authentic"],
                upvotes: 89,
                downvotes: 5,
                commentCount: 32
            )
        ]
        
        isLoading = false
    }
    
    private func refreshContent() async {
        await loadContent()
    }
}

// MARK: - Supporting Types

enum ContentFilter: String, CaseIterable {
    case all = "All"
    case reviews = "Reviews"
    case posts = "Posts"
    case positive = "Positive"
    case negative = "Negative"
    case recent = "Recent"
    
    var displayName: String {
        return rawValue
    }
}

// SortOption is defined in SearchService.swift

enum ContentItem {
    case review(Review)
    case post(DatingReviewPost)
    
    var id: UUID {
        switch self {
        case .review(let review): return review.id
        case .post(let post): return post.id
        }
    }
    
    var createdAt: Date {
        switch self {
        case .review(let review): return review.createdAt
        case .post(let post): return post.createdAt
        }
    }
    
    var netScore: Int {
        switch self {
        case .review(let review): return review.netScore
        case .post(let post): return post.netScore
        }
    }
    
    var engagementScore: Double {
        switch self {
        case .review(let review):
            let totalVotes = review.upvotes + review.downvotes
            let commentWeight = review.commentCount * 2
            let timeDecay = max(0.1, 1.0 - (Date().timeIntervalSince(review.createdAt) / (24 * 60 * 60)))
            return Double(netScore + commentWeight) * timeDecay
            
        case .post(let post):
            return post.engagementScore
        }
    }
    
    var controversyScore: Double {
        switch self {
        case .review(let review):
            let totalVotes = review.upvotes + review.downvotes
            guard totalVotes > 0 else { return 0 }
            let ratio = Double(min(review.upvotes, review.downvotes)) / Double(max(review.upvotes, review.downvotes))
            return ratio * Double(totalVotes)
            
        case .post(let post):
            let totalVotes = post.upvotes + post.downvotes
            guard totalVotes > 0 else { return 0 }
            let ratio = Double(min(post.upvotes, post.downvotes)) / Double(max(post.upvotes, post.downvotes))
            return ratio * Double(totalVotes)
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Binding var selectedFilter: ContentFilter
    @Binding var selectedSort: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: UISpacing.lg) {
                // Content type filters
                VStack(alignment: .leading, spacing: UISpacing.md) {
                    Text("Content Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: UISpacing.xs) {
                        ForEach(ContentFilter.allCases, id: \.self) { filter in
                            FilterOptionRow(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                }
                
                Divider()
                
                // Sort options
                VStack(alignment: .leading, spacing: UISpacing.md) {
                    Text("Sort By")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: UISpacing.xs) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            FilterOptionRow(
                                title: option.displayName,
                                isSelected: selectedSort == option,
                                action: { selectedSort = option }
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct FilterOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(UIColors.label)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(UIColors.accentPrimary)
                }
            }
            .padding(.vertical, UISpacing.sm)
            .padding(.horizontal, UISpacing.md)
            .background(
                isSelected ? MaterialDesignSystem.GlassColors.primary : Color.clear,
                in: RoundedRectangle(cornerRadius: UICornerRadius.sm)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ContentFeedView(
        onReviewTap: { _ in },
        onPostTap: { _ in },
        onVote: { _, _, _ in },
        onComment: { _, _ in }
    )
}