import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var toastCenter: ToastCenter
    @State private var searchText = ""
    @State private var selectedFilter = "Recent"
    let filters = ["Recent", "Popular", "Nearby", "Trending"]
    @State private var savedSearches: [String] = []
    private var tagSuggestions: [String] { TagCatalog.all.map { $0.rawValue } }
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search posts, tags, users...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Typeahead Suggestions
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matches = (tagSuggestions + savedSearches)
                        .filter { $0.lowercased().contains(q) }
                        .prefix(5)
                    if !matches.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(matches), id: \.self) { item in
                                Button(action: { searchText = item }) {
                                    HStack {
                                        Image(systemName: "text.magnifyingglass")
                                            .foregroundColor(.gray)
                                        Text(item)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(10)
                                }
                                Divider()
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 6)
                    }
                }

                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                triggerSearch()
                            }) {
                                Text(filter)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .semibold : .regular)
                                    .foregroundColor(selectedFilter == filter ? .blue : .gray)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        selectedFilter == filter ?
                                            Color.blue.opacity(0.1) :
                                            Color.clear
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Lookup entry
                HStack {
                    NavigationLink(destination: LookupWizardView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(.blue)
                            Text("Start a Lookup")
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
                
                // Search Results or Placeholder
                if searchText.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("Search for posts, tags, or users")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Saved Searches
                        if !savedSearches.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Saved searches")
                                        .font(.subheadline).bold()
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                
                                ForEach(savedSearches, id: \.self) { item in
                                    HStack {
                                        Button(action: { searchText = item }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "bookmark")
                                                    .foregroundColor(.blue)
                                                Text(item)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                            .padding()
                                            .cardBackground()
                                        }
                                    }
                                    .padding(.horizontal)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let idx = savedSearches.firstIndex(of: item) {
                                                savedSearches.remove(at: idx)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        .onTapGesture {
                                            Task {
                                                do {
                                                    try await SavedSearchService.shared.delete(query: item)
                                                    savedSearches.removeAll { $0 == item }
                                                    HapticFeedback.impact(style: .light)
                                                    toastCenter.show(.success, NSLocalizedString("Deleted saved search", comment: ""))
                                                } catch {
                                                    HapticFeedback.notification(type: .error)
                                                    toastCenter.show(.error, ErrorPresenter.message(for: error))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Try searching for:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(["#ghosting", "#redflag", "#greendate", "@username"], id: \.self) { suggestion in
                                Button(action: {
                                    searchText = suggestion
                                }) {
                                    HStack {
                                        Text(suggestion)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .cardBackground()
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                } else {
                    // Search Results
                    Group {
                        if let errorMessage = errorMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                                Text(errorMessage).font(.subheadline)
                                Button("Retry") { triggerSearch(immediate: true) }
                                    .buttonStyle(.bordered)
                            }
                            .padding(.top, 24)
                        } else if isLoading {
                            ProgressView().padding(.top, 24)
                        } else if results.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                Text("No results for \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 24)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(results) { r in
                                        SearchResultRow(result: r)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.top)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Search", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchText.isEmpty {
                        Button("Save") {
                            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                do {
                                    try await SavedSearchService.shared.save(query: trimmed)
                                    // refresh list
                                    savedSearches = try await SavedSearchService.shared.list()
                                    HapticFeedback.notification(type: .success)
                                    toastCenter.show(.success, NSLocalizedString("Saved search", comment: ""))
                                } catch {
                                    HapticFeedback.notification(type: .error)
                                    toastCenter.show(.error, ErrorPresenter.message(for: error))
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .onChange(of: searchText) { _ in triggerSearch() }
            .task {
                // Load saved searches on first appear
                do { savedSearches = try await SavedSearchService.shared.list() } catch { }
            }
        }
    }
}

// MARK: - Behaviors
extension SearchView {
    private func triggerSearch(immediate: Bool = false) {
        // cancel previous task
        searchTask?.cancel()
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        searchTask = Task {
            if !immediate {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            guard !Task.isCancelled else { return }
            do {
                let sort: SearchSort
                switch selectedFilter {
                case "Popular": sort = .popular
                case "Nearby": sort = .nearby
                case "Trending": sort = .trending
                default: sort = .recent
                }
                let res = try await SearchService.shared.search(query: q, tags: [], sort: sort)
                if !Task.isCancelled {
                    results = res
                    isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Search failed. Please try again."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Result Row
struct SearchResultRow: View {
    let result: SearchResult
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.title)
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.0f", result.score * 100))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(result.snippet)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            if !result.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(result.tags, id: \.self) { t in
                            Text(t)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .cardBackground()
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
