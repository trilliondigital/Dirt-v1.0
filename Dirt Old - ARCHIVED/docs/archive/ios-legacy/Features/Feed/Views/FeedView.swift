import SwiftUI
import Combine
import UIKit

// MARK: - BlurView
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Post Model
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

// MARK: - FeedView
struct FeedView: View {
    @State private var posts: [Post] = Post.samplePosts
    @State private var selectedFilter = "Latest"
    @State private var showNewPostView = false
    @State private var isRefreshing = false
    @State private var showProfile = false
    @State private var showSearch = false
    @State private var selectedTab = 0
    
    let filters = ["Latest", "Trending", "Following", "Nearby"]
    private let refreshPublisher = PassthroughSubject<Void, Never>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack(spacing: 0) {
                    TabButton(title: "Feed", isSelected: selectedTab == 0) {
                        withAnimation { selectedTab = 0 }
                    }
                    TabButton(title: "Discover", isSelected: selectedTab == 1) {
                        withAnimation { selectedTab = 1 }
                    }
                    TabButton(title: "Activity", isSelected: selectedTab == 2) {
                        withAnimation { selectedTab = 2 }
                    }
                }
                .frame(height: 44)
                .background(Color(.systemBackground))
                .overlay(Divider(), alignment: .bottom)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Header with Search
                        HStack {
                            // Profile Button
                            Button(action: { showProfile = true }) {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                Text("Search")
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onTapGesture {
                                showSearch = true
                            }
                            
                            // Notifications
                            Button(action: {
                                // Show notifications
                            }) {
                                Image(systemName: "bell")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Stories/Highlights
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Add Story Button
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Circle()
                                            .fill(Color(.systemGray6))
                                            .frame(width: 70, height: 70)
                                            .overlay(
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(.blue)
                                            )
                                    }
                                    Text("Add")
                                        .font(.caption)
                                }
                                
                                // Sample Stories
                                ForEach(1...5, id: \.self) { i in
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .stroke(LinearGradient(gradient: Gradient(colors: [.red, .orange, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                                                .frame(width: 70, height: 70)
                                                .overlay(
                                                    Image("user\(i)")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 64, height: 64)
                                                        .clipShape(Circle())
                                                )
                                        }
                                        Text("User \(i)")
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 70)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                        
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
                        }
                        
                        // Posts
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostCard(post: post)
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // End of feed message
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("You're all caught up!")
                                    .font(.headline)
                                Text("New posts will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                        .padding(.vertical, 16)
                    }
                    .padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                .navigationBarHidden(true)
                .refreshable {
                    await refreshData()
                }
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showNewPostView = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                                    .padding()
                            }
                        }
                    }
                )
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewPostView) {
                // Create post view would go here
                Text("New Post")
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        // Simulate network request
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isRefreshing = false
    }
}

// MARK: - PostCard
struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showComments = false
    @State private var isExpanded = false
    @State private var isImageExpanded = false
    @State private var isLongPressing = false
    @State private var currentScale: CGFloat = 1.0
    
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
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // More options button
                Menu {
                    Button(action: { isBookmarked.toggle() }) {
                        Label(isBookmarked ? "Remove from Saved" : "Save Post", 
                              systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    
                    Button(action: {}) {
                        Label("Share Post", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Post Content
            if !post.content.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.content)
                        .font(.body)
                        .lineLimit(isExpanded ? nil : 5)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if needsTruncation(text: post.content) && !isExpanded {
                        Button("Read more") {
                            withAnimation {
                                isExpanded = true
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            // Post Image if available
            if let imageName = post.imageName {
                ZStack(alignment: .bottomTrailing) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .scaleEffect(isImageExpanded ? 1.5 : 1.0)
                        .animation(.spring(), value: isImageExpanded)
                        .onTapGesture(count: 2) {
                            withAnimation {
                                isLiked.toggle()
                                HapticFeedback.impact(style: .medium)
                            }
                        }
                        .gesture(
                            TapGesture(count: 1)
                                .onEnded {
                                    withAnimation(.spring()) {
                                        isImageExpanded.toggle()
                                    }
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .updating($isLongPressing) { currentState, gestureState, _ in
                                    gestureState = currentState
                                    if gestureState {
                                        HapticFeedback.impact(style: .medium)
                                    }
                                }
                        )
                    
                    if isLongPressing {
                        // Add long press action here
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLiked.toggle()
                        HapticFeedback.impact(style: .light)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: isLiked)
                            .font(.title3)
                            .foregroundColor(isLiked ? .red : .primary)
                        Text(formatNumber(post.upvotes + (isLiked ? 1 : 0)))
                            .font(.subheadline)
                            .foregroundColor(isLiked ? .red : .primary)
                    }
                }
                
                Button(action: {
                    showComments = true
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.title3)
                        Text(formatNumber(post.comments))
                            .font(.subheadline)
                    }
                }
                
                Button(action: {
                    // Share action
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.title3)
                        Text("Share")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isBookmarked.toggle()
                        HapticFeedback.impact(style: .light)
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .symbolEffect(.bounce, value: isBookmarked)
                        .font(.title3)
                        .foregroundColor(isBookmarked ? .blue : .primary)
                }
                .frame(width: 24, height: 24)
                .padding(8)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contextMenu {
            Button(action: {
                isBookmarked.toggle()
                HapticFeedback.impact(style: .light)
            }) {
                Label(
                    isBookmarked ? "Remove from Saved" : "Save Post",
                    systemImage: isBookmarked ? "bookmark.slash" : "bookmark"
                )
            }
            
            Button(action: {
                UIPasteboard.general.string = post.content
                HapticFeedback.notification(type: .success)
            }) {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
            
            Button(role: .destructive, action: {
                HapticFeedback.impact(style: .heavy)
            }) {
                Label("Report Post", systemImage: "flag")
            }
        }
        .sheet(isPresented: $showComments) {
            // Comments view would go here
            Text("Comments")
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        if number >= 1000 {
            let formatted = Double(number) / 1000.0
            return "\(formatter.string(from: NSNumber(value: formatted)) ?? "")\\k"
        } else {
            return "\(number)"
        }
    }
    
    private func needsTruncation(text: String) -> Bool {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        let size = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 32, height: .greatestFiniteMagnitude))
        let lineHeight = textView.font?.lineHeight ?? 0
        let maxHeight = lineHeight * 5 // 5 lines
        return size.height > maxHeight
    }
}

// MARK: - TabButton
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                if isSelected {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 30, height: 3)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 30, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - FilterPill
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
                                        gradient: Gradient(colors: [.blue, .purple]),
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

// MARK: - ScaleButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - HapticFeedback
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
