import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showingFilters = false
    @State private var selectedPost: Post?
    @State private var selectedReview: Review?
    
    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            VStack(spacing: 0) {
                // Enhanced Filter Bar with content type toggle
                EnhancedFilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    selectedCategory: $viewModel.selectedCategory,
                    selectedContentType: $viewModel.selectedContentType,
                    onFilterTap: { showingFilters = true }
                )
                
                // Mixed Content Feed
                if viewModel.isLoading && viewModel.feedItems.isEmpty {
                    FeedLoadingView()
                } else if viewModel.feedItems.isEmpty {
                    EmptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.feedItems, id: \.id) { item in
                                FeedItemView(
                                    item: item,
                                    onPostTap: { post in selectedPost = post },
                                    onReviewTap: { review in selectedReview = review },
                                    onUpvote: { viewModel.upvoteItem(item) },
                                    onDownvote: { viewModel.downvoteItem(item) },
                                    onLike: { viewModel.likeItem(item) },
                                    onSave: { viewModel.saveItem(item) },
                                    onShare: { viewModel.shareItem(item) },
                                    onReport: { viewModel.reportItem(item) }
                                )
                            }
                            
                            // Infinite scroll loading
                            if viewModel.hasMoreContent {
                                ProgressView()
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMoreContent()
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FeedFilterSheet(
                    selectedFilter: $viewModel.selectedFilter,
                    selectedCategory: $viewModel.selectedCategory,
                    selectedContentType: $viewModel.selectedContentType
                )
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .sheet(item: $selectedReview) { review in
                ReviewDetailView(review: review)
            }
            .task {
                await viewModel.loadFeed()
            }
            .onReceive(appState.$deepLinkPath) { path in
                if let path = path, appState.selectedTab == .feed {
                    handleDeepLink(path)
                }
            }
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // Handle deep linking within feed
        appState.deepLinkPath = nil // Clear after handling
    }
}

// MARK: - Filter Bar
struct FilterBar: View {
    @Binding var selectedFilter: FeedFilter
    @Binding var selectedCategory: PostCategory?
    let onFilterTap: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Filter button
                Button(action: onFilterTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filter")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Feed filters
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
                
                // Category filter (if selected)
                if let category = selectedCategory {
                    FilterChip(
                        title: category.displayName,
                        isSelected: true,
                        action: { selectedCategory = nil }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No posts yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Be the first to share your dating experience!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create First Post") {
                // Navigate to create post
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    FeedView()
        .environmentObject(AppState())
}
// M
ARK: - Enhanced Filter Bar
struct EnhancedFilterBar: View {
    @Binding var selectedFilter: FeedFilter
    @Binding var selectedCategory: PostCategory?
    @Binding var selectedContentType: ContentType
    let onFilterTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Content Type Selector
            HStack {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Button(action: { selectedContentType = type }) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedContentType == type ? Color.accentColor : Color(.systemGray6))
                            )
                            .foregroundColor(selectedContentType == type ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                Button(action: onFilterTap) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeedFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: { selectedFilter = filter }
                        )
                    }
                    
                    if let category = selectedCategory {
                        FilterChip(
                            title: category.displayName,
                            isSelected: true,
                            action: { selectedCategory = nil }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Feed Item View
struct FeedItemView: View {
    let item: FeedItem
    let onPostTap: (Post) -> Void
    let onReviewTap: (Review) -> Void
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    
    var body: some View {
        switch item.type {
        case .post(let post):
            PostCard(
                post: post,
                onTap: { onPostTap(post) },
                onUpvote: onUpvote,
                onDownvote: onDownvote,
                onSave: onSave,
                onShare: onShare,
                onReport: onReport
            )
        case .review(let review):
            ReviewFeedCard(
                review: review,
                onTap: { onReviewTap(review) },
                onLike: onLike,
                onSave: onSave,
                onShare: onShare,
                onReport: onReport
            )
        }
    }
}

// MARK: - Review Feed Card
struct ReviewFeedCard: View {
    let review: Review
    let onTap: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(review.authorName.prefix(1)))
                            .font(.headline)
                            .fontWeight(.semibold)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(review.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(review.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(review.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
                
                if let location = review.location {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags
                if !review.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(review.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            // Actions
            HStack(spacing: 20) {
                ActionButton(
                    icon: review.isLiked ? "heart.fill" : "heart",
                    count: review.likeCount,
                    isActive: review.isLiked,
                    action: onLike
                )
                
                ActionButton(
                    icon: "bubble.left",
                    count: review.commentCount,
                    action: onTap
                )
                
                Spacer()
                
                Button(action: onSave) {
                    Image(systemName: "bookmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    init(icon: String, count: Int, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.count = count
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isActive ? .red : .secondary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Feed Loading View
struct FeedLoadingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    FeedItemSkeleton()
                }
            }
            .padding()
        }
    }
}

struct FeedItemSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .shimmer(isAnimating: isAnimating)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 12)
                        .shimmer(isAnimating: isAnimating)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 10)
                        .shimmer(isAnimating: isAnimating)
                }
                
                Spacer()
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .shimmer(isAnimating: isAnimating)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 40)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Review Detail View Placeholder
struct ReviewDetailView: View {
    let review: Review
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(review.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(review.content)
                        .font(.body)
                    
                    // This is a placeholder - full implementation would be in a separate task
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Feed Filter Sheet
struct FeedFilterSheet: View {
    @Binding var selectedFilter: FeedFilter
    @Binding var selectedCategory: PostCategory?
    @Binding var selectedContentType: ContentType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Filter options would go here")
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}