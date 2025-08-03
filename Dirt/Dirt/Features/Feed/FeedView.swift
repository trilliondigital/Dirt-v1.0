import SwiftUI

struct Post: Identifiable {
    let id = UUID()
    let username: String
    let userInitial: String
    let userColor: Color
    let timestamp: String
    let content: String
    let imageName: String?
    let isVerified: Bool
    let tags: [String]
    let upvotes: Int
    let comments: Int
    let shares: Int
    let isLiked: Bool
    let isBookmarked: Bool
    
    static let samplePosts: [Post] = [
        Post(
            username: "Alex Johnson",
            userInitial: "AJ",
            userColor: .blue,
            timestamp: "2h ago",
            content: "Just had an amazing first date! Great conversation and lots of common interests. Can't wait to see them again! 🥰",
            imageName: "date1",
            isVerified: true,
            tags: ["green flag", "great conversation", "second date planned"],
            upvotes: 128,
            comments: 24,
            shares: 8,
            isLiked: false,
            isBookmarked: true
        ),
        Post(
            username: "Taylor Smith",
            userInitial: "TS",
            userColor: .purple,
            timestamp: "5h ago",
            content: "Be cautious with this one. Ghosted after three amazing dates with no explanation. Really thought there was a connection. 💔",
            imageName: nil,
            isVerified: false,
            tags: ["red flag", "ghosting", "mixed signals"],
            upvotes: 89,
            comments: 42,
            shares: 15,
            isLiked: true,
            isBookmarked: false
        ),
        Post(
            username: "Jordan Lee",
            userInitial: "JL",
            userColor: .green,
            timestamp: "1d ago",
            content: "Found someone who actually reads the same books as me! We talked for hours about our favorite authors. 📚 #booklover #greatconnection",
            imageName: "book-date",
            isVerified: true,
            tags: ["green flag", "shared interests", "intellectual connection"],
            upvotes: 256,
            comments: 31,
            shares: 12,
            isLiked: false,
            isBookmarked: true
        )
    ]
}

struct FeedView: View {
    @State private var posts: [Post] = Post.samplePosts
    @State private var selectedFilter = "Latest"
    @State private var showNewPostView = false
    
    let filters = ["Latest", "Trending", "Following", "Nearby"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Dirt Feed")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
                .overlay(Divider(), alignment: .bottom)
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterPill(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
                
                // Posts
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCard(post: post)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewPostView) {
                CreatePostView()
            }
            .onAppear {
                // Refresh feed data
            }
        }
    }
}

// MARK: - Post Card
struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showComments = false
    @State private var showShareSheet = false
    
    init(post: Post) {
        self.post = post
        _isLiked = State(initialValue: post.isLiked)
        _isBookmarked = State(initialValue: post.isBookmarked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // User Avatar
                Circle()
                    .fill(post.userColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(post.userInitial)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(post.userColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // User Info
                    HStack(spacing: 4) {
                        Text(post.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if post.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Text(post.timestamp)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Tags
                    if !post.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(post.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            tag.lowercased().contains("red") ?
                                                Color.red.opacity(0.1) :
                                                Color.green.opacity(0.1)
                                        )
                                        .foregroundColor(
                                            tag.lowercased().contains("red") ?
                                                .red :
                                                .green
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
                .offset(y: -8)
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Image if available
            if let imageName = post.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
            }
            
            // Action Buttons
            HStack(spacing: 0) {
                // Like Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLiked.toggle()
                    }
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isLiked ? .blue : .gray)
                        Text(formatNumber(post.upvotes + (isLiked ? 1 : 0)))
                            .font(.subheadline)
                            .foregroundColor(isLiked ? .blue : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                // Comment Button
                Button(action: {
                    showComments = true
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16, weight: .medium))
                        Text(formatNumber(post.comments))
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showComments) {
                    // Comments View
                    Text("Comments")
                }
                
                Spacer()
                
                // Share Button
                Button(action: {
                    showShareSheet = true
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 16, weight: .medium))
                        Text(formatNumber(post.shares))
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showShareSheet) {
                    // Share Sheet
                    Text("Share Options")
                }
                
                Spacer()
                
                // Bookmark Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isBookmarked.toggle()
                    }
                    HapticFeedback.impact(style: .light)
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isBookmarked ? .blue : .gray)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 4)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if number >= 1000 {
            let formatted = formatter.string(from: NSNumber(value: Double(number) / 1000.0)) ?? ""
            return "\(formatted)K"
        }
        return "\(number)"
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        Color(.systemGray6)
                )
                .cornerRadius(20)
                .animation(.easeInOut, value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
