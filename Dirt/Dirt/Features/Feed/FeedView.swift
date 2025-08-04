import SwiftUI
import Combine
import UIKit

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
    @State private var isRefreshing = false
    @State private var showProfile = false
    @State private var showSearch = false
    
    let filters = ["Latest", "Trending", "Following", "Nearby"]
    private let refreshPublisher = PassthroughSubject<Void, Never>()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    // Filter tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterPill(
                                    title: filter,
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        withAnimation(.spring()) {
                                            selectedFilter = filter
                                            HapticFeedback.impact(style: .light)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    
                    // Posts
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCard(post: post)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
            .overlay(
                newPostButton,
                alignment: .bottomTrailing
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewPostView) {
            CreatePostView()
        }
    }
}

struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showComments = false
    @State private var isExpanded = false
    @State private var showActionSheet = false
    @State private var currentScale: CGFloat = 1.0
    @GestureState private var isLongPressing = false
    
    // Constants
    private let maxContentLines = 5
    private let animationDuration = 0.2
    
    init(post: Post) {
        self.post = post
        _isLiked = State(initialValue: post.isLiked)
        _isBookmarked = State(initialValue: post.isBookmarked)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // User Avatar with tap gesture for profile
                NavigationLink(destination: ProfileView()) {
                    ZStack {
                        Circle()
                            .fill(post.userColor.opacity(0.2))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Text(post.userInitial)
                                    .font(.headline)
                                    .foregroundColor(post.userColor)
                            )
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(post.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        if post.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)
                        }
                        
                        Spacer()
                        
                        Text(post.timestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                    }
                    
                    // Post content with read more/less
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.content)
                            .font(.subheadline)
                            .lineSpacing(4)
                            .lineLimit(isExpanded ? nil : maxContentLines)
                            .fixedSize(horizontal: false, vertical: true)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded.toggle()
                                }
                            }
                        
                        if !isExpanded && needsTruncation(text: post.content) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = true
                                }
                            }) {
                                Text("Read more")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, post.imageName != nil ? 0 : 16)
            
            // Post Image with zoom and save
            if let imageName = post.imageName {
                ZStack(alignment: .topTrailing) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .scaleEffect(currentScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    currentScale = value.magnitude
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        currentScale = 1.0
                                    }
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .updating($isLongPressing) { currentState, gestureState, _ in
                                    gestureState = currentState
                                    if currentState {
                                        HapticFeedback.impact(style: .medium)
                                    }
                                }
                        )
                    
                    if isLongPressing {
                        Button(action: {
                            // Save image action
                            HapticFeedback.notification(type: .success)
                            showActionSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .actionSheet(isPresented: $showActionSheet) {
                    ActionSheet(
                        title: Text("Save Image"),
                        message: Text("Would you like to save this image to your photos?"),
                        buttons: [
                            .default(Text("Save")) {
                                // Implement save to photos
                            },
                            .cancel()
                        ]
                    )
                }
            }
            
            // Enhanced Action Buttons with animations
            HStack(spacing: 0) {
                // Like Button with animation
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLiked.toggle()
                        HapticFeedback.impact(style: isLiked ? .heavy : .light)
                    }
                }) {
                    HStack(spacing: 6) {
                        ZStack {
                            Group {
                                Image(systemName: "heart.fill")
                                    .opacity(isLiked ? 1 : 0)
                                    .scaleEffect(isLiked ? 1.0 : 0.1)
                                
                                Image(systemName: "heart")
                                    .opacity(isLiked ? 0 : 1)
                            }
                            .font(.system(size: 18))
                            .foregroundColor(isLiked ? .red : .primary)
                        }
                        .frame(width: 24, height: 24)
                        
                        Text(formatNumber(post.upvotes + (isLiked && !post.isLiked ? 1 : 0)))
                            .font(.caption)
                            .foregroundColor(isLiked ? .red : .primary)
                            .contentTransition(.numericText())
                    }
                    .padding(8)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Comment Button with animation
                Button(action: {
                    HapticFeedback.impact(style: .light)
                    showComments = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                        
                        Text(formatNumber(post.comments))
                            .font(.caption)
                    }
                    .padding(8)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .sheet(isPresented: $showComments) {
                    // Comments view would go here
                    NavigationView {
                        Text("Comments")
                            .navigationTitle("Comments")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showComments = false
                                    }
                                }
                            }
                    }
                }
                
                Spacer()
                
                // Share Button with menu
                Menu {
                    Button(action: {
                        // Share to messages
                        HapticFeedback.impact(style: .medium)
                    }) {
                        Label("Share via Messages", systemImage: "message.fill")
                    }
                    
                    Button(action: {
                        // Share to other apps
                        HapticFeedback.impact(style: .medium)
                    }) {
                        Label("Share via...", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // Copy link
                        HapticFeedback.notification(type: .success)
                    }) {
                        Label("Copy Link", systemImage: "link")
                    }
                    
                    Button(role: .destructive, action: {
                        // Report post
                        HapticFeedback.impact(style: .heavy)
                    }) {
                        Label("Report Post", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Bookmark Button with animation
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isBookmarked.toggle()
                        HapticFeedback.impact(style: .light)
                    }
                }) {
                    ZStack {
                        Group {
                            Image(systemName: "bookmark.fill")
                                .opacity(isBookmarked ? 1 : 0)
                                .scaleEffect(isBookmarked ? 1.0 : 0.1)
                            
                            Image(systemName: "bookmark")
                                .opacity(isBookmarked ? 0 : 1)
                        }
                        .font(.system(size: 18))
                        .foregroundColor(isBookmarked ? .blue : .primary)
                    }
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contextMenu {
            Button(action: {
                // Copy post text
                UIPasteboard.general.string = post.content
                HapticFeedback.notification(type: .success)
            }) {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                // Save post
                isBookmarked.toggle()
                HapticFeedback.impact(style: .light)
            }) {
                Label(
                    isBookmarked ? "Remove from Saved" : "Save Post",
                    systemImage: isBookmarked ? "bookmark.slash" : "bookmark"
                )
            }
            
            Button(role: .destructive, action: {
                // Report post
                HapticFeedback.impact(style: .heavy)
            }) {
                Label("Report Post", systemImage: "flag")
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func needsTruncation(text: String) -> Bool {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        let size = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 64, height: .greatestFiniteMagnitude))
        let lineHeight = textView.font?.lineHeight ?? 20
        let maxHeight = lineHeight * CGFloat(maxContentLines)
        return size.height > maxHeight
    }
}

// MARK: - Subviews
private extension FeedView {
    var headerView: some View {
        HStack {
            Button(action: { showProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
            }
            .sheet(isPresented: $showProfile) {
                // Profile view would go here
                Text("Profile")
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Dirt Feed")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                NavigationLink(destination: NotificationsView()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 4, y: -2)
                    }
                }
            }
        }
    }
    
    var newPostButton: some View {
        Button(action: {
            HapticFeedback.impact(style: .medium)
            showNewPostView = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.blue)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
        .sheet(isPresented: $showNewPostView) {
            // Create post view would go here
            Text("New Post")
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        // Simulate network request
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isRefreshing = false
    }
}

// MARK: - Filter Pill View
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
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected ?
                                AnyShapeStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                ) :
                                AnyShapeStyle(Color(.systemGray6))
                        )
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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
