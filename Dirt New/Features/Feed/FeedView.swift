import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showingFilters = false
    @State private var selectedPost: Post?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                FilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    selectedCategory: $viewModel.selectedCategory,
                    onFilterTap: { showingFilters = true }
                )
                
                // Posts List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostCard(
                                post: post,
                                onTap: { selectedPost = post },
                                onUpvote: { viewModel.upvotePost(post) },
                                onDownvote: { viewModel.downvotePost(post) },
                                onSave: { viewModel.savePost(post) },
                                onShare: { viewModel.sharePost(post) },
                                onReport: { viewModel.reportPost(post) }
                            )
                        }
                        
                        // Loading indicator
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshPosts()
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
                FilterSheet(
                    selectedFilter: $viewModel.selectedFilter,
                    selectedCategory: $viewModel.selectedCategory
                )
            }
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .task {
                await viewModel.loadPosts()
            }
            .overlay {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    EmptyFeedView()
                }
            }
        }
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