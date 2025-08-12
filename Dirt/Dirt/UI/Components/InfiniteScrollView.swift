import SwiftUI
import Combine

// MARK: - Infinite Scroll View

struct InfiniteScrollView<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let isLoading: Bool
    let hasMoreContent: Bool
    let onLoadMore: () -> Void
    let onRefresh: (() async -> Void)?
    let content: (Item) -> Content
    
    @State private var isRefreshing = false
    
    init(
        items: [Item],
        isLoading: Bool = false,
        hasMoreContent: Bool = true,
        onLoadMore: @escaping () -> Void,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.isLoading = isLoading
        self.hasMoreContent = hasMoreContent
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    content(item)
                        .onAppear {
                            if item.id == items.last?.id && hasMoreContent && !isLoading {
                                onLoadMore()
                            }
                        }
                }
                
                if isLoading && !items.isEmpty {
                    LoadingIndicator()
                        .padding()
                }
                
                if !hasMoreContent && !items.isEmpty {
                    EndOfContentView()
                        .padding()
                }
            }
        }
        .refreshable {
            if let onRefresh = onRefresh {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
        }
    }
}

// MARK: - Pagination Manager

@MainActor
class PaginationManager<T: Codable & Identifiable>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var hasMoreContent = true
    @Published var errorMessage: String?
    
    private var currentPage = 0
    private let pageSize: Int
    private let loadData: (Int, Int) async throws -> [T]
    
    init(pageSize: Int = 20, loadData: @escaping (Int, Int) async throws -> [T]) {
        self.pageSize = pageSize
        self.loadData = loadData
    }
    
    func loadInitialData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 0
        
        do {
            let newItems = try await loadData(currentPage, pageSize)
            items = newItems
            hasMoreContent = newItems.count == pageSize
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreData() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let newItems = try await loadData(currentPage, pageSize)
            items.append(contentsOf: newItems)
            hasMoreContent = newItems.count == pageSize
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadInitialData()
    }
    
    func reset() {
        items = []
        currentPage = 0
        hasMoreContent = true
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Loading States

struct LoadingIndicator: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading...")
                .foregroundColor(.secondary)
        }
    }
}

struct EndOfContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("You're all caught up!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Loading Skeleton

struct SkeletonView: View {
    @State private var isAnimating = false
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat = 200, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .offset(x: isAnimating ? width : -width)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
            .clipped()
    }
}

struct PostSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(width: 40, height: 40, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    SkeletonView(width: 120, height: 16)
                    SkeletonView(width: 80, height: 12)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: .infinity, height: 16)
                SkeletonView(width: 250, height: 16)
                SkeletonView(width: 180, height: 16)
            }
            
            HStack {
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Pull to Refresh Custom Implementation

struct PullToRefreshView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    @State private var isRefreshing = false
    @State private var pullOffset: CGFloat = 0
    @State private var refreshTriggerOffset: CGFloat = -100
    
    init(onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Pull to refresh indicator
                    HStack {
                        Spacer()
                        
                        if isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if pullOffset < refreshTriggerOffset {
                            Image(systemName: "arrow.down")
                                .rotationEffect(.degrees(180))
                        } else if pullOffset < 0 {
                            Image(systemName: "arrow.down")
                        }
                        
                        Spacer()
                    }
                    .frame(height: max(0, -pullOffset))
                    .opacity(pullOffset < 0 ? 1 : 0)
                    
                    content
                }
            }
            .coordinateSpace(name: "pullToRefresh")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                pullOffset = offset
                
                if offset < refreshTriggerOffset && !isRefreshing {
                    Task {
                        isRefreshing = true
                        await onRefresh()
                        isRefreshing = false
                    }
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("pullToRefresh")).minY
                        )
                }
            )
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
