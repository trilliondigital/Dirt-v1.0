import Foundation
import Combine
import SwiftUI

// MARK: - Search Types

enum SearchScope: String, CaseIterable {
    case all = "all"
    case posts = "posts"
    case users = "users"
    case topics = "topics"
    case hashtags = "hashtags"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .posts: return "Posts"
        case .users: return "Users"
        case .topics: return "Topics"
        case .hashtags: return "Hashtags"
        }
    }
    
    var systemImage: String {
        switch self {
        case .all: return "magnifyingglass"
        case .posts: return "doc.text"
        case .users: return "person"
        case .topics: return "tag"
        case .hashtags: return "number"
        }
    }
}

enum SortOption: String, CaseIterable {
    case relevance = "relevance"
    case recent = "recent"
    case popular = "popular"
    case oldest = "oldest"
    
    var displayName: String {
        switch self {
        case .relevance: return "Most Relevant"
        case .recent: return "Most Recent"
        case .popular: return "Most Popular"
        case .oldest: return "Oldest"
        }
    }
}

struct SearchFilter {
    var dateRange: DateRange?
    var userType: UserType?
    var contentType: ContentType?
    var hasMedia: Bool?
    var minEngagement: Int?
    
    enum DateRange: String, CaseIterable {
        case today = "today"
        case week = "week"
        case month = "month"
        case year = "year"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .today: return "Today"
            case .week: return "This Week"
            case .month: return "This Month"
            case .year: return "This Year"
            case .all: return "All Time"
            }
        }
        
        var dateInterval: DateInterval? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                return DateInterval(start: startOfDay, end: now)
            case .week:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return DateInterval(start: startOfWeek, end: now)
            case .month:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return DateInterval(start: startOfMonth, end: now)
            case .year:
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                return DateInterval(start: startOfYear, end: now)
            case .all:
                return nil
            }
        }
    }
    
    enum UserType: String, CaseIterable {
        case verified = "verified"
        case regular = "regular"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .verified: return "Verified Users"
            case .regular: return "Regular Users"
            case .all: return "All Users"
            }
        }
    }
    
    enum ContentType: String, CaseIterable {
        case text = "text"
        case image = "image"
        case video = "video"
        case link = "link"
        case all = "all"
        
        var displayName: String {
            switch self {
            case .text: return "Text Only"
            case .image: return "With Images"
            case .video: return "With Videos"
            case .link: return "With Links"
            case .all: return "All Content"
            }
        }
    }
}

// MARK: - Search Results

struct SearchResult: Identifiable, Codable {
    let id: String
    let type: SearchScope
    let title: String
    let subtitle: String?
    let content: String?
    let imageURL: String?
    let timestamp: Date
    let relevanceScore: Double
    let metadata: [String: String]
}

// MARK: - Enhanced Search Service

@MainActor
class EnhancedSearchService: ObservableObject {
    static let shared = EnhancedSearchService()
    
    @Published var searchText = ""
    @Published var searchScope: SearchScope = .all
    @Published var sortOption: SortOption = .relevance
    @Published var searchFilter = SearchFilter()
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var hasMoreResults = true
    @Published var recentSearches: [String] = []
    @Published var savedSearches: [SavedSearch] = []
    @Published var suggestions: [String] = []
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    private var currentPage = 0
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadRecentSearches()
        loadSavedSearches()
        setupSearchDebouncing()
    }
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                if !searchText.isEmpty {
                    self?.performSearch(reset: true)
                    self?.loadSuggestions(for: searchText)
                } else {
                    self?.clearResults()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(reset: Bool = false) {
        searchTask?.cancel()
        
        if reset {
            currentPage = 0
            results = []
            hasMoreResults = true
        }
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearResults()
            return
        }
        
        searchTask = Task {
            await executeSearch()
        }
    }
    
    private func executeSearch() async {
        isSearching = true
        errorMessage = nil
        
        do {
            let searchResults = try await searchContent(
                query: searchText,
                scope: searchScope,
                sort: sortOption,
                filter: searchFilter,
                page: currentPage,
                pageSize: pageSize
            )
            
            if currentPage == 0 {
                results = searchResults
                addToRecentSearches(searchText)
            } else {
                results.append(contentsOf: searchResults)
            }
            
            hasMoreResults = searchResults.count == pageSize
            currentPage += 1
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    func loadMoreResults() {
        guard !isSearching && hasMoreResults else { return }
        performSearch(reset: false)
    }
    
    private func searchContent(
        query: String,
        scope: SearchScope,
        sort: SortOption,
        filter: SearchFilter,
        page: Int,
        pageSize: Int
    ) async throws -> [SearchResult] {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock search results
        let mockResults = generateMockResults(for: query, scope: scope, count: pageSize)
        return mockResults
    }
    
    private func generateMockResults(for query: String, scope: SearchScope, count: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        
        for i in 0..<count {
            let result = SearchResult(
                id: UUID().uuidString,
                type: scope == .all ? SearchScope.allCases.randomElement()! : scope,
                title: "Result \(i + 1) for '\(query)'",
                subtitle: "Subtitle for result \(i + 1)",
                content: "Content preview for search result \(i + 1) matching query '\(query)'",
                imageURL: Bool.random() ? "https://picsum.photos/200/200?random=\(i)" : nil,
                timestamp: Date().addingTimeInterval(-Double.random(in: 0...86400*30)),
                relevanceScore: Double.random(in: 0.5...1.0),
                metadata: ["author": "User \(i + 1)", "engagement": "\(Int.random(in: 0...1000))"]
            )
            results.append(result)
        }
        
        return results
    }
    
    private func loadSuggestions(for query: String) async {
        // Simulate loading suggestions
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        let mockSuggestions = [
            "\(query) tips",
            "\(query) tutorial",
            "\(query) guide",
            "\(query) examples",
            "\(query) best practices"
        ]
        
        await MainActor.run {
            suggestions = mockSuggestions
        }
    }
    
    func clearResults() {
        searchTask?.cancel()
        results = []
        isSearching = false
        hasMoreResults = true
        currentPage = 0
        suggestions = []
        errorMessage = nil
    }
    
    // MARK: - Recent Searches
    
    private func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        recentSearches.removeAll { $0 == trimmedQuery }
        recentSearches.insert(trimmedQuery, at: 0)
        recentSearches = Array(recentSearches.prefix(10))
        
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    // MARK: - Saved Searches
    
    func saveCurrentSearch(name: String) {
        let savedSearch = SavedSearch(
            id: UUID().uuidString,
            name: name,
            query: searchText,
            scope: searchScope,
            filter: searchFilter,
            createdAt: Date()
        )
        
        savedSearches.append(savedSearch)
        saveSavedSearches()
    }
    
    func deleteSavedSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.id == search.id }
        saveSavedSearches()
    }
    
    func loadSavedSearch(_ search: SavedSearch) {
        searchText = search.query
        searchScope = search.scope
        searchFilter = search.filter
        performSearch(reset: true)
    }
    
    private func loadSavedSearches() {
        if let data = UserDefaults.standard.data(forKey: "savedSearches"),
           let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            savedSearches = searches
        }
    }
    
    private func saveSavedSearches() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            UserDefaults.standard.set(data, forKey: "savedSearches")
        }
    }
}

// MARK: - Saved Search Model

struct SavedSearch: Identifiable, Codable {
    let id: String
    let name: String
    let query: String
    let scope: SearchScope
    let filter: SearchFilter
    let createdAt: Date
}

// MARK: - Search UI Components

struct SearchBar: View {
    @ObservedObject var searchService: EnhancedSearchService
    @State private var isShowingFilters = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search...", text: $searchService.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchService.searchText.isEmpty {
                        Button(action: {
                            searchService.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: { isShowingFilters.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.accentColor)
                }
            }
            
            // Search scope picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        SearchScopeButton(
                            scope: scope,
                            isSelected: searchService.searchScope == scope
                        ) {
                            searchService.searchScope = scope
                            searchService.performSearch(reset: true)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            SearchFiltersView(searchService: searchService)
        }
    }
}

struct SearchScopeButton: View {
    let scope: SearchScope
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: scope.systemImage)
                    .font(.caption)
                
                Text(scope.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonHaptic(.light)
    }
}

struct SearchFiltersView: View {
    @ObservedObject var searchService: EnhancedSearchService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Sort By") {
                    Picker("Sort Option", selection: $searchService.sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Date Range") {
                    Picker("Date Range", selection: Binding(
                        get: { searchService.searchFilter.dateRange ?? .all },
                        set: { searchService.searchFilter.dateRange = $0 }
                    )) {
                        ForEach(SearchFilter.DateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                }
                
                Section("Content Type") {
                    Picker("Content Type", selection: Binding(
                        get: { searchService.searchFilter.contentType ?? .all },
                        set: { searchService.searchFilter.contentType = $0 }
                    )) {
                        ForEach(SearchFilter.ContentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("User Type") {
                    Picker("User Type", selection: Binding(
                        get: { searchService.searchFilter.userType ?? .all },
                        set: { searchService.searchFilter.userType = $0 }
                    )) {
                        ForEach(SearchFilter.UserType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("Additional Filters") {
                    Toggle("Has Media", isOn: Binding(
                        get: { searchService.searchFilter.hasMedia ?? false },
                        set: { searchService.searchFilter.hasMedia = $0 ? $0 : nil }
                    ))
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        searchService.searchFilter = SearchFilter()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        searchService.performSearch(reset: true)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Result type icon or image
            if let imageURL = result.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            } else {
                Image(systemName: result.type.systemImage)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let content = result.content {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(result.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let engagement = result.metadata["engagement"] {
                        Text("\(engagement) interactions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
