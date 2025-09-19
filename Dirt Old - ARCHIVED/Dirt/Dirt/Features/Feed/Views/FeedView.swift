import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif
import CoreLocation

// MARK: - PostRowLink
private struct PostRowLink: View {
    let post: Post
    var body: some View {
        NavigationLink {
            PostDetailLoaderView(postId: post.id)
        } label: {
            PostCard(post: post)
        }
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
    @Environment(\.services) private var services
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
    private var visiblePosts: [Post] { filteredAndSortedPosts() }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Material Glass Navigation Bar
                GlassNavigationBar(
                    title: "Feed",
                    leading: {
                        Button(action: { showProfile = true }) {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(UIColors.label)
                        }
                    },
                    trailing: {
                        Button(action: { /* Show notifications */ }) {
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(UIColors.label)
                        }
                    }
                )
                
                // Material Glass Tab Bar
                GlassTabBar(
                    selectedTab: $selectedTab,
                    tabs: [
                        GlassTabBar.TabItem(title: "Feed", systemImage: "house", selectedSystemImage: "house.fill"),
                        GlassTabBar.TabItem(title: "Discover", systemImage: "safari", selectedSystemImage: "safari.fill"),
                        GlassTabBar.TabItem(title: "Activity", systemImage: "bell", selectedSystemImage: "bell.fill")
                    ]
                )
                
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
                        TagFiltersRow(
                            tags: TagCatalog.all,
                            isSelected: { tag in activeTagFilters.contains(tag) },
                            onToggle: { tag in
                                if activeTagFilters.contains(tag) { activeTagFilters.remove(tag) } else { activeTagFilters.insert(tag) }
                                HapticFeedback.impact(style: .light)
                            }
                        )

                        // Time filter
                        TimeFiltersRow(
                            filters: timeFilters,
                            selected: selectedTimeFilter,
                            onSelect: { tf in
                                withAnimation(.spring()) {
                                    selectedTimeFilter = tf
                                    HapticFeedback.impact(style: .light)
                                }
                            }
                        )

                        // Proximity filter (disabled unless Nearby + authorized)
                        RadiusFiltersRow(
                            options: radiusOptions,
                            isNearbyActive: isNearbyActive,
                            isLocationAuthorized: isLocationAuthorized,
                            selected: selectedRadius,
                            onSelect: { option in
                                guard isNearbyActive && isLocationAuthorized else { return }
                                withAnimation(.spring()) {
                                    selectedRadius = option
                                    HapticFeedback.impact(style: .light)
                                }
                            },
                            onRequestLocation: { locationManager.requestWhenInUse() }
                        )

                        // Material Glass Search Bar
                        GlassSearchBar(
                            text: .constant(""),
                            placeholder: "Search posts...",
                            onSearchButtonClicked: {
                                showSearch = true
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, UISpacing.xs)
                        .onTapGesture {
                            showSearch = true
                        }
                        
                        // Stories/Highlights with Material Glass
                        GlassCard(
                            material: MaterialDesignSystem.Glass.ultraThin,
                            cornerRadius: UICornerRadius.lg,
                            padding: UISpacing.sm
                        ) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: UISpacing.md) {
                                    // Add Story Button
                                    VStack(spacing: UISpacing.xs) {
                                        ZStack(alignment: .bottomTrailing) {
                                            Circle()
                                                .fill(MaterialDesignSystem.GlassColors.neutral)
                                                .frame(width: 70, height: 70)
                                                .overlay(
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.title2)
                                                        .foregroundColor(UIColors.accentPrimary)
                                                )
                                        }
                                        Text("Add")
                                            .font(.caption)
                                            .foregroundColor(UIColors.label)
                                    }
                                    
                                    // Sample Stories
                                    ForEach(1...5, id: \.self) { i in
                                        VStack(spacing: UISpacing.xs) {
                                            ZStack {
                                                Circle()
                                                    .stroke(UIGradients.primary, lineWidth: 2)
                                                    .frame(width: 70, height: 70)
                                                    .overlay(
                                                        AvatarView(index: i - 1, size: 64)
                                                    )
                                            }
                                            Text("User \(i)")
                                                .font(.caption)
                                                .foregroundColor(UIColors.label)
                                                .lineLimit(1)
                                                .frame(width: 70)
                                        }
                                    }
                                }
                                .padding(.horizontal, UISpacing.xs)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, UISpacing.xs)
                        
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
                        
                        // Browse Topics entry with Material Glass
                        HStack {
                            NavigationLink(destination: TopicsView()) {
                                GlassCard(
                                    material: MaterialDesignSystem.Glass.thin,
                                    cornerRadius: UICornerRadius.md,
                                    padding: UISpacing.sm
                                ) {
                                    HStack(spacing: UISpacing.xs) {
                                        Image(systemName: "square.grid.2x2")
                                            .foregroundColor(UIColors.accentPrimary)
                                        Text("Browse Topics")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(UIColors.label)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(UIColors.secondaryLabel)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Posts
                        LazyVStack(spacing: 16) {
                            ForEach(visiblePosts) { post in
                                PostRowLink(post: post)
                                    .padding(.horizontal)
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
                                HapticFeedback.impact(style: .medium)
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(MaterialDesignSystem.Context.floatingAction, in: Circle())
                                    .overlay(
                                        Circle()
                                            .fill(UIGradients.primary)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(MaterialDesignSystem.GlassBorders.prominent, lineWidth: 1)
                                    )
                                    .shadow(color: MaterialDesignSystem.GlassShadows.strong, radius: 12, x: 0, y: 6)
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
            // Header with Material Glass styling
            HStack(alignment: .top, spacing: UISpacing.sm) {
                // User Avatar with Material Glass effect
                NavigationLink(destination: ProfileView()) {
                    ZStack {
                        Circle()
                            .fill(MaterialDesignSystem.Glass.ultraThin)
                            .overlay(
                                Circle()
                                    .fill(post.userColor.opacity(0.2))
                            )
                            .frame(width: 42, height: 42)
                            .overlay(
                                Text(post.userInitial)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(post.userColor)
                            )
                            .overlay(
                                Circle()
                                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                            )
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(UIColors.label)
                        
                        if post.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(UIColors.accentPrimary)
                                .font(.caption)
                        }
                    }
                    
                    Text(post.timestamp)
                        .font(.caption)
                        .foregroundColor(UIColors.secondaryLabel)
                }
                
                Spacer()
            }
            .padding(.horizontal, UISpacing.md)
            .padding(.top, UISpacing.md)
            
            // Content
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                Text(post.content)
                    .font(.body)
                    .foregroundColor(UIColors.label)
                    .multilineTextAlignment(.leading)
                
                // Image if present
                if let imageName = post.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .clipped()
                        .cornerRadius(UICornerRadius.md)
                }
                
                // Tags with Material Glass styling
                if !post.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UISpacing.xs) {
                            ForEach(post.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(UIColors.label)
                                    .padding(.horizontal, UISpacing.xs)
                                    .padding(.vertical, 4)
                                    .background(MaterialDesignSystem.Glass.ultraThin, in: Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 0.5)
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.horizontal, UISpacing.md)
            
            // Action Buttons with Material Glass styling
            HStack(spacing: UISpacing.md) {
                // Like button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isHelpful.toggle()
                        HapticFeedback.impact(style: .light)
                        services.analyticsService.trackUserAction("helpful_toggled", parameters: [
                            "post_id": post.id.uuidString,
                            "value": isHelpful ? "1" : "0"
                        ])
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .symbolEffect(.bounce, value: isHelpful)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isHelpful ? UIColors.accentPrimary : UIColors.label)
                        Text(formatNumber(post.upvotes))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(UIColors.label)
                    }
                    .padding(.horizontal, UISpacing.sm)
                    .padding(.vertical, UISpacing.xs)
                    .background(
                        isHelpful ? MaterialDesignSystem.GlassColors.primary : MaterialDesignSystem.Glass.ultraThin,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isHelpful ? MaterialDesignSystem.GlassBorders.accent : MaterialDesignSystem.GlassBorders.subtle,
                                lineWidth: 1
                            )
                    )
                }
                
                // Comments button
                Button(action: {
                    showComments = true
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16, weight: .medium))
                        Text(formatNumber(post.comments))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(UIColors.label)
                    .padding(.horizontal, UISpacing.sm)
                    .padding(.vertical, UISpacing.xs)
                    .background(MaterialDesignSystem.Glass.ultraThin, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                    )
                }
                
                // Share button
                Button(action: {
                    HapticFeedback.impact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Share")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(UIColors.label)
                    .padding(.horizontal, UISpacing.sm)
                    .padding(.vertical, UISpacing.xs)
                    .background(MaterialDesignSystem.Glass.ultraThin, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                    )
                }
                
                Spacer()
                
                // Bookmark button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isBookmarked.toggle()
                        HapticFeedback.impact(style: .light)
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .symbolEffect(.bounce, value: isBookmarked)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isBookmarked ? UIColors.accentPrimary : UIColors.label)
                        .frame(width: 32, height: 32)
                        .background(
                            isBookmarked ? MaterialDesignSystem.GlassColors.primary : MaterialDesignSystem.Glass.ultraThin,
                            in: Circle()
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isBookmarked ? MaterialDesignSystem.GlassBorders.accent : MaterialDesignSystem.GlassBorders.subtle,
                                    lineWidth: 1
                                )
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, UISpacing.md)
            .padding(.bottom, UISpacing.md)
        }
        .glassCard(
            material: MaterialDesignSystem.Context.card,
            cornerRadius: UICornerRadius.lg,
            shadowColor: MaterialDesignSystem.GlassShadows.soft,
            shadowRadius: 8
        )
        .padding(.horizontal, UISpacing.xs)
        .padding(.vertical, UISpacing.xs)
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

// MARK: - Lightweight filter rows
private struct TagFiltersRow: View {
    let tags: [ControlledTag]
    let isSelected: (ControlledTag) -> Bool
    let onToggle: (ControlledTag) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.id) { tag in
                    let on = isSelected(tag)
                    let accent: Color? = {
                        switch tag {
                        case .avoid: return .red
                        case .greatConversation: return .green
                        default: return nil
                        }
                    }()
                    Button(action: { onToggle(tag) }) {
                        TagPill(title: tag.rawValue, on: on, accent: accent)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct TagPill: View {
    let title: String
    let on: Bool
    let accent: Color?
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            if let accentColor = accent {
                Image(systemName: "flag.fill").foregroundColor(accentColor)
            }
        }
        .font(.footnote.weight(.medium))
        .foregroundColor(on ? UIColors.accentPrimary : UIColors.label)
        .padding(.horizontal, UISpacing.sm)
        .padding(.vertical, UISpacing.xs)
        .background(
            on ? MaterialDesignSystem.GlassColors.primary : MaterialDesignSystem.Glass.ultraThin,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    on ? MaterialDesignSystem.GlassBorders.accent : MaterialDesignSystem.GlassBorders.subtle,
                    lineWidth: 1
                )
        )
    }
}

private struct TimeFiltersRow: View {
    let filters: [String]
    let selected: String
    let onSelect: (String) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { tf in
                    FilterPill(title: tf, isSelected: selected == tf) {
                        onSelect(tf)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct RadiusFiltersRow: View {
    let options: [String]
    let isNearbyActive: Bool
    let isLocationAuthorized: Bool
    let selected: String
    let onSelect: (String) -> Void
    let onRequestLocation: () -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    FilterPill(title: option, isSelected: selected == option) {
                        onSelect(option)
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
                if isNearbyActive && !isLocationAuthorized {
                    Button(action: { onRequestLocation() }) {
                        Label("Enable Location", systemImage: "location")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(UIColors.accentPrimary)
                            .padding(.horizontal, UISpacing.sm)
                            .padding(.vertical, UISpacing.xs)
                            .background(MaterialDesignSystem.Glass.thin, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(MaterialDesignSystem.GlassBorders.accent, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}



// Haptics provided by shared utility in `Dirt/Dirt/Utilities/HapticFeedback.swift`

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
