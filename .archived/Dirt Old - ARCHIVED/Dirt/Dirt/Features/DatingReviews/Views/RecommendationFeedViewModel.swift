import Foundation
import Combine

// MARK: - Recommendation Feed View Model
@MainActor
class RecommendationFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recommendations: [ContentRecommendation] = []
    @Published var filteredRecommendations: [ContentRecommendation] = []
    @Published var trendingTopics: [TrendingTopic] = []
    @Published var popularContent: [UUID] = []
    @Published var isLoading = false
    @Published var error: ContentRecommendationError?
    
    // MARK: - Private Properties
    private let recommendationService: ContentRecommendationService
    private let currentUserId: UUID
    private var cancellables = Set<AnyCancellable>()
    private var currentFilter: ContentFilter = .all
    
    // MARK: - Initialization
    init(
        recommendationService: ContentRecommendationService = ContentRecommendationService(
            reviewService: ReviewCreationService(),
            postService: DiscussionPostService()
        ),
        userId: UUID = UUID() // In real app, this would come from auth service
    ) {
        self.recommendationService = recommendationService
        self.currentUserId = userId
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to recommendation service updates
        recommendationService.$recommendedContent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recommendations in
                self?.recommendations = recommendations.filter { $0.userId == self?.currentUserId }
                self?.applyCurrentFilter()
            }
            .store(in: &cancellables)
        
        recommendationService.$trendingTopics
            .receive(on: DispatchQueue.main)
            .assign(to: \.trendingTopics, on: self)
            .store(in: &cancellables)
        
        recommendationService.$popularContent
            .receive(on: DispatchQueue.main)
            .assign(to: \.popularContent, on: self)
            .store(in: &cancellables)
        
        recommendationService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        recommendationService.$error
            .receive(on: DispatchQueue.main)
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load initial recommendations
    func loadRecommendations() async {
        await recommendationService.updateRecommendations()
        
        // Load user-specific recommendations
        let userRecommendations = await recommendationService.getRecommendations(for: currentUserId)
        recommendations = userRecommendations
        applyCurrentFilter()
    }
    
    /// Refresh all recommendations
    func refreshRecommendations() async {
        await recommendationService.updateRecommendations()
    }
    
    /// Apply content filter
    func applyFilter(_ filter: ContentFilter) async {
        currentFilter = filter
        applyCurrentFilter()
        
        // Load additional content if needed
        switch filter {
        case .trending:
            trendingTopics = await recommendationService.getTrendingTopics()
        case .popular:
            popularContent = await recommendationService.getPopularContent()
        default:
            break
        }
    }
    
    /// Track user interaction with recommended content
    func trackInteraction(recommendation: ContentRecommendation, interactionType: InteractionType) async {
        await recommendationService.trackInteraction(
            userId: currentUserId,
            contentId: recommendation.contentId,
            contentType: recommendation.contentType,
            interactionType: interactionType
        )
        
        // Mark recommendation as interacted
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            recommendations[index].isInteracted = true
        }
    }
    
    /// Handle selection of a recommendation
    func selectRecommendation(_ recommendation: ContentRecommendation) async {
        // Track view interaction
        await trackInteraction(recommendation: recommendation, interactionType: .view)
        
        // Mark as viewed
        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
            recommendations[index].isViewed = true
        }
        
        // Navigate to content (would be handled by navigation coordinator in real app)
        print("Navigating to content: \(recommendation.contentId)")
    }
    
    /// Handle selection of trending topic
    func selectTrendingTopic(_ topic: TrendingTopic) async {
        // Load content for this trending topic
        if let category = topic.category {
            let categoryContent = await recommendationService.getContentByCategory(category)
            print("Loading category content: \(categoryContent)")
        } else if let tag = topic.tag {
            // Filter recommendations by tag
            let taggedRecommendations = recommendations.filter { recommendation in
                // This would need to check the actual content for tags
                return true // Simplified for now
            }
            filteredRecommendations = taggedRecommendations
        }
    }
    
    /// Handle selection of popular content
    func selectPopularContent(_ contentId: UUID) async {
        // Track interaction with popular content
        await recommendationService.trackInteraction(
            userId: currentUserId,
            contentId: contentId,
            contentType: .post, // Would determine actual type
            interactionType: .view
        )
        
        print("Navigating to popular content: \(contentId)")
    }
    
    /// Get recommendations by category
    func getRecommendationsByCategory(_ category: PostCategory) async -> [ContentRecommendation] {
        return recommendations.filter { recommendation in
            // This would need to check the actual content category
            // For now, return all recommendations
            return true
        }
    }
    
    /// Get content recommendations for specific tags
    func getRecommendationsForTags(_ tags: [String]) async -> [ContentRecommendation] {
        return recommendations.filter { recommendation in
            // This would need to check if content contains any of the specified tags
            return true
        }
    }
    
    // MARK: - Private Methods
    
    private func applyCurrentFilter() {
        switch currentFilter {
        case .all:
            filteredRecommendations = recommendations
        case .posts:
            filteredRecommendations = recommendations.filter { $0.contentType == .post }
        case .reviews:
            filteredRecommendations = recommendations.filter { $0.contentType == .review }
        case .trending:
            // Show recommendations related to trending topics
            filteredRecommendations = recommendations.filter { recommendation in
                recommendation.recommendationReason == .trendingTopic
            }
        case .popular:
            // Show popular content recommendations
            filteredRecommendations = recommendations.filter { recommendation in
                recommendation.recommendationReason == .popularContent
            }
        }
        
        // Sort by recommendation score
        filteredRecommendations.sort { $0.recommendationScore > $1.recommendationScore }
    }
}

// MARK: - Content Loader
@MainActor
class ContentLoader: ObservableObject {
    @Published var content: ContentPreview?
    @Published var isLoading = false
    
    func loadContent(id: UUID, type: ContentType) async {
        isLoading = true
        
        // Simulate loading content
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock content based on type
        switch type {
        case .post:
            content = ContentPreview(
                id: id,
                title: "Dating Strategy Discussion",
                preview: "What's the best approach for first dates? Looking for advice from the community...",
                type: .post
            )
        case .review:
            content = ContentPreview(
                id: id,
                title: "Profile Review - Tinder",
                preview: "Reviewed a profile from Tinder. Photos: 4/5, Bio: 3/5, Overall experience was positive...",
                type: .review
            )
        case .comment:
            content = ContentPreview(
                id: id,
                title: "Comment",
                preview: "Great advice! I tried this approach and it worked really well...",
                type: .comment
            )
        }
        
        isLoading = false
    }
}

// MARK: - Content Preview Model
struct ContentPreview: Identifiable {
    let id: UUID
    let title: String
    let preview: String
    let type: ContentType
}

// MARK: - Supporting Views
struct ContentPreviewView: View {
    let content: ContentPreview
    let contentType: ContentType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: contentType.iconName)
                        .foregroundColor(contentType.color)
                    Text(contentType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(content.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Text(content.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 16)
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 40)
        }
        .redacted(reason: .placeholder)
    }
}

struct InteractionButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterSheetView: View {
    @Binding var selectedFilter: ContentFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ContentFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter.displayName)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Filter Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension ContentType {
    var iconName: String {
        switch self {
        case .post:
            return "bubble.left.and.bubble.right"
        case .review:
            return "star.fill"
        case .comment:
            return "bubble.left"
        }
    }
    
    var color: Color {
        switch self {
        case .post:
            return .blue
        case .review:
            return .orange
        case .comment:
            return .green
        }
    }
    
    var displayName: String {
        switch self {
        case .post:
            return "Discussion"
        case .review:
            return "Review"
        case .comment:
            return "Comment"
        }
    }
}