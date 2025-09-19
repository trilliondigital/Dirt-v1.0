import SwiftUI
import Combine

// MARK: - Recommendation Feed View
struct RecommendationFeedView: View {
    @StateObject private var viewModel = RecommendationFeedViewModel()
    @State private var selectedFilter: ContentFilter = .all
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                
                // Content Feed
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Trending Topics Section
                        if !viewModel.trendingTopics.isEmpty {
                            trendingTopicsSection
                        }
                        
                        // Recommended Content Section
                        recommendedContentSection
                        
                        // Popular Content Section
                        if !viewModel.popularContent.isEmpty {
                            popularContentSection
                        }
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.refreshRecommendations()
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(selectedFilter: $selectedFilter)
            }
            .task {
                await viewModel.loadRecommendations()
            }
            .onChange(of: selectedFilter) { _ in
                Task {
                    await viewModel.applyFilter(selectedFilter)
                }
            }
        }
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ContentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: {
                            selectedFilter = filter
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Trending Topics Section
    private var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Trending Now")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.trendingTopics.prefix(10), id: \.id) { topic in
                        TrendingTopicCard(topic: topic) {
                            Task {
                                await viewModel.selectTrendingTopic(topic)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Recommended Content Section
    private var recommendedContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.blue)
                Text("Recommended for You")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredRecommendations, id: \.id) { recommendation in
                    RecommendationCard(
                        recommendation: recommendation,
                        onTap: {
                            Task {
                                await viewModel.selectRecommendation(recommendation)
                            }
                        },
                        onInteraction: { interactionType in
                            Task {
                                await viewModel.trackInteraction(
                                    recommendation: recommendation,
                                    interactionType: interactionType
                                )
                            }
                        }
                    )
                }
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Popular Content Section
    private var popularContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Popular in Community")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.popularContent.prefix(5), id: \.self) { contentId in
                    PopularContentCard(contentId: contentId) {
                        Task {
                            await viewModel.selectPopularContent(contentId)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trending Topic Card
struct TrendingTopicCard: View {
    let topic: TrendingTopic
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: topic.category?.iconName ?? "tag.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(topic.contentCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Text(topic.topic)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Text("Trending")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding()
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: ContentRecommendation
    let onTap: () -> Void
    let onInteraction: (InteractionType) -> Void
    
    @StateObject private var contentLoader = ContentLoader()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recommendation reason
            HStack {
                Image(systemName: recommendation.recommendationReason.iconName)
                    .foregroundColor(.blue)
                Text(recommendation.recommendationReason.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f", recommendation.recommendationScore))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // Content preview
            if let content = contentLoader.content {
                ContentPreviewView(
                    content: content,
                    contentType: recommendation.contentType,
                    onTap: onTap
                )
            } else {
                ContentLoadingView()
            }
            
            // Interaction buttons
            HStack(spacing: 16) {
                InteractionButton(
                    icon: "arrow.up",
                    action: { onInteraction(.upvote) }
                )
                
                InteractionButton(
                    icon: "bubble.left",
                    action: { onInteraction(.comment) }
                )
                
                InteractionButton(
                    icon: "square.and.arrow.up",
                    action: { onInteraction(.share) }
                )
                
                Spacer()
                
                InteractionButton(
                    icon: "bookmark",
                    action: { onInteraction(.save) }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .task {
            await contentLoader.loadContent(
                id: recommendation.contentId,
                type: recommendation.contentType
            )
        }
    }
}

// MARK: - Popular Content Card
struct PopularContentCard: View {
    let contentId: UUID
    let onTap: () -> Void
    
    @StateObject private var contentLoader = ContentLoader()
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let content = contentLoader.content {
                        Text(content.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                        
                        Text(content.preview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 16)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Popular")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            await contentLoader.loadContent(id: contentId, type: .post) // Default to post
        }
    }
}

// MARK: - Content Filter
enum ContentFilter: String, CaseIterable {
    case all = "All"
    case posts = "Posts"
    case reviews = "Reviews"
    case trending = "Trending"
    case popular = "Popular"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Extensions
extension RecommendationReason {
    var iconName: String {
        switch self {
        case .similarInterests:
            return "heart.fill"
        case .popularContent:
            return "chart.line.uptrend.xyaxis"
        case .trendingTopic:
            return "flame.fill"
        case .categoryPreference:
            return "folder.fill"
        case .tagPreference:
            return "tag.fill"
        case .highRated:
            return "star.fill"
        case .recentActivity:
            return "clock.fill"
        case .similarUsers:
            return "person.2.fill"
        }
    }
}

#Preview {
    RecommendationFeedView()
}