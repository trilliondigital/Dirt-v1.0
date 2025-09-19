import SwiftUI

struct FeedView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var posts: [Post] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List(posts) { post in
                PostRowView(post: post)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
            .navigationTitle("Feed")
            .refreshable {
                await loadPosts()
            }
            .task {
                await loadPosts()
            }
            .overlay {
                if isLoading && posts.isEmpty {
                    ProgressView("Loading posts...")
                }
            }
        }
    }
    
    private func loadPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            posts = try await supabaseManager.fetchPosts()
        } catch {
            print("Failed to load posts: \(error)")
        }
    }
}

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Label(post.category.displayName, systemImage: post.category.iconName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(post.content)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Button(action: {}) {
                    Label("\(post.upvotes)", systemImage: "arrow.up")
                }
                .foregroundColor(.green)
                
                Button(action: {}) {
                    Label("\(post.downvotes)", systemImage: "arrow.down")
                }
                .foregroundColor(.red)
                
                Button(action: {}) {
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                }
                .foregroundColor(.orange)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}