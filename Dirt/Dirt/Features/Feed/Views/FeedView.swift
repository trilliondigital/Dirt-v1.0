import SwiftUI
import Combine
import UIKit
import CoreLocation

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
    let createdAt: Date
    let coordinate: CLLocationCoordinate2D?
    
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
            isBookmarked: true,
            createdAt: Date(timeIntervalSinceNow: -2 * 60 * 60),
            coordinate: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431) // Austin
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
            isBookmarked: false,
            createdAt: Date(timeIntervalSinceNow: -5 * 60 * 60),
            coordinate: CLLocationCoordinate2D(latitude: 30.2710, longitude: -97.7437)
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
            isBookmarked: true,
            createdAt: Date(timeIntervalSinceNow: -24 * 60 * 60),
            coordinate: nil
        )
    ]
}

// MARK: - FeedView
struct FeedView: View {
    @State private var posts: [Post] = Post.samplePosts
    @State private var selectedFilter = "Latest"
    @State private var selectedSort = 0 // 0 Latest, 1 Trending
    @State private var activeTagFilters: Set<ControlledTag> = []
    @State private var showNewPostView = false
    @State private var isRefreshing = false
    @State private var showProfile = false
    @State private var showSearch = false
    @State private var selectedTab = 0
    @State private var selectedTimeFilter = "Anytime"
    @State private var selectedRadius = "Any"
    @StateObject private var locationManager = LocationManager.shared
    
    let filters = ["Latest", "Trending", "Following", "Nearby"]
    let timeFilters = ["Anytime", "24h", "7d", "30d"]
    let radiusOptions = ["Any", "5 mi", "10 mi", "25 mi", "50 mi"]
    private let refreshPublisher = PassthroughSubject<Void, Never>()
    
    // Location + Nearby helpers
    private var isLocationAuthorized: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
    }
    private var isNearbyActive: Bool { selectedFilter == "Nearby" }
    
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
                        // Sort control
                        Picker("Sort", selection: $selectedSort) {
                            Text("Latest").tag(0)
                            Text("Trending").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Tag filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TagCatalog.all) { tag in
                                    let isOn = activeTagFilters.contains(tag)
                                    Button(action: {
                                        if isOn { activeTagFilters.remove(tag) } else { activeTagFilters.insert(tag) }
                                    }) {
                                        HStack(spacing: 6) {
                                            Text(tag.rawValue)
                                            if tag == .redFlag {
                                                Image(systemName: "flag.fill").foregroundColor(.red)
                                            } else if tag == .greenFlag {
                                                Image(systemName: "flag.fill").foregroundColor(.green)
                                            }
                                        }
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(isOn ? .blue : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isOn ? Color.blue.opacity(0.15) : Color(.systemGray6))
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Time filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(timeFilters, id: \.self) { tf in
                                    FilterPill(title: tf, isSelected: selectedTimeFilter == tf) {
                                        withAnimation(.spring()) {
                                            selectedTimeFilter = tf
                                            HapticFeedback.impact(style: .light)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Proximity filter (disabled unless Nearby + authorized)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(radiusOptions, id: \.self) { option in
                                    FilterPill(title: option, isSelected: selectedRadius == option) {
                                        guard isNearbyActive && isLocationAuthorized else { return }
                                        withAnimation(.spring()) {
                                            selectedRadius = option
                                            HapticFeedback.impact(style: .light)
                                        }
                                    }
                                    .opacity(isNearbyActive && isLocationAuthorized ? 1.0 : 0.5)
                                    .overlay(
                                        Group {
                                            if !(isNearbyActive && isLocationAuthorized) {
                                                RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2))
                                            }
                                        }
                                    )
                                }
                                // Prompt to enable location when Nearby selected but not authorized
                                if isNearbyActive && !isLocationAuthorized {
                                    Button(action: { locationManager.requestWhenInUse() }) {
                                        Label("Enable Location", systemImage: "location")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

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
                        
                        // Browse Topics entry
                        HStack {
                            NavigationLink(destination: TopicsView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.grid.2x2")
                                        .foregroundColor(.blue)
                                    Text("Browse Topics")
                                        .font(.subheadline).bold()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Posts
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAndSortedPosts()) { post in
                                NavigationLink(
                                    destination: PostDetailView(
                                        postId: post.id,
                                        username: post.username,
                                        userInitial: post.userInitial,
                                        userColor: post.userColor,
                                        timestamp: post.timestamp,
                                        content: post.content,
                                        imageName: post.imageName,
                                        isVerified: post.isVerified,
                                        tags: post.tags,
                                        upvotes: post.upvotes,
                                        comments: post.comments,
                                        shares: post.shares
                                    )
                                ) {
                                    PostCard(post: post)
                                        .padding(.horizontal)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
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
    
    private func filteredAndSortedPosts() -> [Post] {
        var list = posts
        // Tag filters
        if !activeTagFilters.isEmpty {
            let keys = activeTagFilters.map { $0.rawValue.lowercased() }
            list = list.filter { post in
                let tagString = post.tags.joined(separator: " ").lowercased()
                return keys.allSatisfy { tagString.contains($0.replacingOccurrences(of: " ", with: "")) || tagString.contains($0) }
            }
        }

        // Time filter
        if selectedTimeFilter != "Anytime" {
            let now = Date()
            let cutoff: Date = {
                switch selectedTimeFilter {
                case "24h": return Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
                case "7d": return Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
                case "30d": return Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
                default: return Date.distantPast
                }
            }()
            list = list.filter { $0.createdAt >= cutoff }
        }

        // Proximity filter (only when Nearby tab is active and authorized)
        if isNearbyActive, isLocationAuthorized, selectedRadius != "Any", let userLoc = locationManager.currentLocation {
            let meters: Double = {
                let comps = selectedRadius.split(separator: " ")
                if let miles = Double(comps.first ?? "0") { return miles * 1609.34 }
                return .greatestFiniteMagnitude
            }()
            list = list.filter { post in
                guard let coord = post.coordinate else { return false }
                let postLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                return postLoc.distance(from: userLoc) <= meters
            }
        }

        // Sort
        if selectedSort == 1 {
            list = list.sorted { $0.upvotes > $1.upvotes }
        }
        return list
    }
}
 

// MARK: - PostCard
struct PostCard: View {
    let post: Post
    @State private var isHelpful: Bool
    @State private var isBookmarked: Bool
    @State private var showComments = false
    @State private var isExpanded = false
    @State private var isImageExpanded = false
    @State private var isImageRevealed = false
    @GestureState private var isLongPressing = false
    @State private var currentScale: CGFloat = 1.0
    @State private var showReportSheet = false
    @State private var selectedReport: ReportReason? = nil
    @State private var isSoftHidden = false
    
    private let animationDuration = 0.2
    
    init(post: Post) {
        self.post = post
        _isHelpful = State(initialValue: post.isLiked)
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
                }
            }
            .padding(.horizontal)
            
            // Action Buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isHelpful.toggle()
                        HapticFeedback.impact(style: .light)
                        AnalyticsService.shared.log("helpful_toggled", [
                            "post_id": post.id.uuidString,
                            "value": isHelpful ? "1" : "0"
                        ])
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .symbolEffect(.bounce, value: isHelpful)
                            .font(.title3)
                            .foregroundColor(isHelpful ? .blue : .primary)
                        Text(formatNumber(post.upvotes))
                            .font(.subheadline)
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

                Button(action: {
                    showReportSheet = true
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "flag")
                            .font(.title3)
                        Text("Report")
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
        .cardBackground()
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .opacity(isSoftHidden ? 0.4 : 1.0)
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
        .sheet(isPresented: $showReportSheet) {
            NavigationView {
                List {
                    Section("Report reason") {
                        ForEach(ReportReason.allCases) { reason in
                            HStack {
                                Text(reason.rawValue)
                                Spacer()
                                if selectedReport == reason { Image(systemName: "checkmark").foregroundColor(.blue) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedReport = reason }
                        }
                    }
                }
                .navigationTitle("Report Post")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showReportSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            if let reason = selectedReport {
                                ReportService.submitReport(postId: post.id, reason: reason)
                            }
                            // Soft-hide locally after report
                            isSoftHidden = true
                            showReportSheet = false
                            HapticFeedback.notification(type: .success)
                        }.disabled(selectedReport == nil)
                    }
                }
            }
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

// Haptics provided by shared utility in `Dirt/Dirt/Utilities/HapticFeedback.swift`

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
