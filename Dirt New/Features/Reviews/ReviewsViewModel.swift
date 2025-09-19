import SwiftUI
import Combine

@MainActor
class ReviewsViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var showingFilterSheet = false
    @Published var currentFilter = ContentFilter()
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe filter changes
        $currentFilter
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadReviews()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadReviews() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call - replace with actual service call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            // Mock data for now
            reviews = generateMockReviews()
            
        } catch {
            errorMessage = "Failed to load reviews: \(error.localizedDescription)"
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
                title: title,
                content: "This was an amazing experience that I would definitely recommend to others looking for a great date idea.",
                rating: Double.random(in: 3.0...5.0),
                authorId: "user_\(index)",
                authorName: "User \(index + 1)",
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)), // Random time in last week
                updatedAt: Date(),
                tags: ["coffee", "romantic", "fun"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                imageUrls: [],
                likeCount: Int.random(in: 0...50),
                commentCount: Int.random(in: 0...20),
                isLiked: Bool.random(),
                location: "San Francisco, CA"
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

enum ReviewCategory: String, CaseIterable {
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