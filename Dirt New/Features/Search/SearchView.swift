import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedPost: Post?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: {
                    Task {
                        await viewModel.search(query: searchText)
                    }
                })
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if searchText.isEmpty {
                            // Default content when not searching
                            DefaultSearchContent(
                                trendingTopics: viewModel.trendingTopics,
                                popularPosts: viewModel.popularPosts,
                                onTopicTap: { topic in
                                    searchText = topic
                                    Task {
                                        await viewModel.search(query: topic)
                                    }
                                },
                                onPostTap: { post in
                                    selectedPost = post
                                }
                            )
                        } else {
                            // Search results
                            SearchResults(
                                results: viewModel.searchResults,
                                isLoading: viewModel.isLoading,
                                onPostTap: { post in
                                    selectedPost = post
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPost) { post in
                PostDetailView(post: post)
            }
            .task {
                await viewModel.loadDefaultContent()
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search posts, topics, or tags...", text: $text)
                    .focused($isSearchFocused)
                    .onSubmit {
                        onSearchButtonClicked()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearchFocused {
                Button("Cancel") {
                    text = ""
                    isSearchFocused = false
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Default Search Content
struct DefaultSearchContent: View {
    let trendingTopics: [String]
    let popularPosts: [Post]
    let onTopicTap: (String) -> Void
    let onPostTap: (Post) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Trending Topics
            if !trendingTopics.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Trending Topics")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(trendingTopics, id: \.self) { topic in
                            Button(action: { onTopicTap(topic) }) {
                                Text("#\(topic)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            
            // Popular Posts
            if !popularPosts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Popular This Week")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    ForEach(popularPosts.prefix(5)) { post in
                        PopularPostRow(post: post, onTap: { onPostTap(post) })
                    }
                }
            }
            
            // Search Tips
            SearchTips()
        }
    }
}

// MARK: - Popular Post Row
struct PopularPostRow: View {
    let post: Post
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Sentiment indicator
                Circle()
                    .fill(Color(post.sentiment.color))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(post.category.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text("\(post.upvotes) upvotes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Results
struct SearchResults: View {
    let results: [Post]
    let isLoading: Bool
    let onPostTap: (Post) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No results found")
                        .font(.headline)
                    
                    Text("Try different keywords or check your spelling")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(results.count) results")
                        .font(.headline)
                    
                    ForEach(results) { post in
                        PostCard(
                            post: post,
                            onTap: { onPostTap(post) },
                            onUpvote: {},
                            onDownvote: {},
                            onSave: {},
                            onShare: {},
                            onReport: {}
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Search Tips
struct SearchTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Tips")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                SearchTipRow(
                    icon: "number",
                    tip: "Use hashtags to find specific topics",
                    example: "#first-date #dating-apps"
                )
                
                SearchTipRow(
                    icon: "quote.bubble",
                    tip: "Search for exact phrases with quotes",
                    example: "\"red flags\""
                )
                
                SearchTipRow(
                    icon: "tag",
                    tip: "Filter by category",
                    example: "category:advice"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SearchTipRow: View {
    let icon: String
    let tip: String
    let example: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.subheadline)
                
                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontFamily(.monospaced)
            }
        }
    }
}

#Preview {
    SearchView()
}