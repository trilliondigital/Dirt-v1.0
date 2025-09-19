import SwiftUI
import Combine

@MainActor
class ReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var filteredReviews: [Review] = []
    @Published var isLoading = false
    @Published var showingFilterSheet = false
    @Published var currentFilter = ContentFilter()
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var allReviews: [Review] = []
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe filter changes
        $currentFilter
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // Update filtered reviews when reviews change
        $reviews
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadReviews() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call - replace with actual service call
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 second delay
            
            // Mock data for now
            let loadedReviews = generateMockReviews()
            allReviews = loadedReviews
            reviews = loadedReviews
            
        } catch {
            errorMessage = "Failed to load reviews: \(error.localizedDescription)"
            print("Error loading reviews: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshReviews() async {
        await loadReviews()
    }
    
    // MARK: - Filtering
    
    func applyFilter(_ filter: ContentFilter) {
        currentFilter = filter
        showingFilterSheet = false
    }
    
    func clearFilters() {
        currentFilter = ContentFilter()
    }
    
    private func applyFilters() {
        var filtered = reviews
        
        // Apply category filter
        if !currentFilter.categories.isEmpty {
            filtered = filtered.filter { review in
                // For now, we'll use tags as categories since Review model doesn't have category
                return currentFilter.categories.contains { category in
                    review.tags.contains(category.rawValue.lowercased())
                }
            }
        }
        
        // Apply rating filter
        filtered = filtered.filter { review in
            review.rating >= currentFilter.ratingRange.lowerBound &&
            review.rating <= currentFilter.ratingRange.upperBound
        }
        
        // Apply date range filter
        if let dateRange = currentFilter.dateRange {
            filtered = filtered.filter { review in
                review.createdAt >= dateRange.start && review.createdAt <= dateRange.end
            }
        }
        
        // Apply location filter
        if let location = currentFilter.location, !location.isEmpty {
            filtered = filtered.filter { review in
                review.location?.localizedCaseInsensitiveContains(location) == true
            }
        }
        
        // Apply sorting
        switch currentFilter.sortBy {
        case .recent:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .popular:
            filtered.sort { $0.likeCount > $1.likeCount }
        case .nearby:
            // For now, just sort by location name
            filtered.sort { ($0.location ?? "") < ($1.location ?? "") }
        }
        
        filteredReviews = filtered
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockReviews() -> [Review] {
        let titles = [
            "Great Coffee Date at Blue Bottle",
            "Romantic Dinner Experience",
            "Fun Mini Golf Adventure",
            "Cozy Bookstore Browse",
            "Amazing Hiking Trail Date",
            "Perfect Brunch Spot",
            "Exciting Escape Room Challenge",
            "Beautiful Art Gallery Visit"
        ]
        
        return titles.enumerated().map { index, title in
            Review(
                id: UUID().uuidString,
                authorId: "user_\(index)",
                authorName: "User \(index + 1)",
                title: title,
                content: "This was an amazing experience that I would definitely recommend to others looking for a great date idea.",
                rating: Double.random(in: 3.0...5.0),
                category: ReviewCategory.allCases.randomElement(),
                tags: ["coffee", "romantic", "fun"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)), // Random time in last week
                updatedAt: Date(),
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...20),
                isLiked: Bool.random(),
                isVisible: true,
                isReported: false,
                reportCount: 0,
                imageUrls: [],
                location: "San Francisco, CA",
                venue: nil,
                cost: CostLevel.allCases.randomElement(),
                duration: nil,
                wouldRecommend: true,
                viewCount: Int.random(in: 0...100),
                shareCount: Int.random(in: 0...10),
                saveCount: Int.random(in: 0...15)
            )
        }
    }
}

// MARK: - Content Filter

struct ContentFilter {
    var sortBy: SortOption = .recent
    var categories: Set<ReviewCategory> = []
    var dateRange: DateRange?
    var ratingRange: ClosedRange<Double> = 1.0...5.0
    var location: String?
    
    var isActive: Bool {
        return sortBy != .recent ||
               !categories.isEmpty ||
               dateRange != nil ||
               ratingRange != 1.0...5.0 ||
               location != nil
    }
}

enum SortOption: String, CaseIterable {
    case recent = "Most Recent"
    case rating = "Highest Rated"
    case popular = "Most Popular"
    case nearby = "Nearby"
    
    var systemImage: String {
        switch self {
        case .recent:
            return "clock"
        case .rating:
            return "star.fill"
        case .popular:
            return "heart.fill"
        case .nearby:
            return "location.fill"
        }
    }
}

enum ReviewCategory: String, CaseIterable, Codable {
    case coffee = "Coffee"
    case dinner = "Dinner"
    case activities = "Activities"
    case outdoor = "Outdoor"
    case cultural = "Cultural"
    case nightlife = "Nightlife"
    
    var systemImage: String {
        switch self {
        case .coffee:
            return "cup.and.saucer"
        case .dinner:
            return "fork.knife"
        case .activities:
            return "gamecontroller"
        case .outdoor:
            return "leaf"
        case .cultural:
            return "building.columns"
        case .nightlife:
            return "moon.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .coffee:
            return .brown
        case .dinner:
            return .red
        case .activities:
            return .blue
        case .outdoor:
            return .green
        case .cultural:
            return .purple
        case .nightlife:
            return .indigo
        }
    }
}

struct DateRange {
    let start: Date
    let end: Date
    
    static let lastWeek = DateRange(
        start: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        end: Date()
    )
    
    static let lastMonth = DateRange(
        start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        end: Date()
    )
    
    static let lastYear = DateRange(
        start: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
        end: Date()
    )
}