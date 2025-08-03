import SwiftUI

struct Post: Identifiable {
    let id = UUID()
    let username: String
    let timestamp: String
    let content: String
    let imageName: String?
    let isVerified: Bool
    let tags: [String]
    let upvotes: Int
    let comments: Int
    let shares: Int
}

struct FeedView: View {
    @State private var posts: [Post] = [
        Post(
            username: "User123",
            timestamp: "2h ago",
            content: "Met someone amazing last night. Great conversation and respectful. Would definitely meet again! 🌟",
            imageName: "sample1",
            isVerified: true,
            tags: ["green flag", "great conversation", "respectful"],
            upvotes: 24,
            comments: 5,
            shares: 2
        ),
        Post(
            username: "AnonymousUser",
            timestamp: "5h ago",
            content: "Be careful with this one. Ghosted after 3 great dates with no explanation. 🚩",
            imageName: nil,
            isVerified: false,
            tags: ["red flag", "ghosting"],
            upvotes: 15,
            comments: 8,
            shares: 3
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Dirt Feed")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Image(systemName: "bell.fill")
                            .font(.title2)
                    }
                    .padding(.horizontal)
                    
                    // Posts
                    ForEach(posts) { post in
                        PostCard(post: post)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

struct PostCard: View {
    let post: Post
    @State private var isLiked = false
    @State private var isBookmarked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.username.prefix(1).uppercased()))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if post.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text(post.timestamp)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .lineSpacing(4)
            
            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(post.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    tag.contains("red") ? Color.red.opacity(0.2) : 
                                    tag.contains("green") ? Color.green.opacity(0.2) : 
                                    Color.gray.opacity(0.2)
                                )
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Image if available
            if let imageName = post.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(isLiked ? .blue : .gray)
                        Text("\(post.upvotes + (isLiked ? 1 : 0))")
                            .font(.subheadline)
                    }
                }
                
                Button(action: {
                    // Comment action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(post.comments)")
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.gray)
                
                Button(action: {
                    // Share action
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.right")
                        Text("\(post.shares)")
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    isBookmarked.toggle()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .blue : .gray)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
