import SwiftUI

struct SearchView: View {
    @Environment(\.services) private var services
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
                // Material Glass Search Bar
                GlassSearchBar(
                    text: $searchText,
                    placeholder: "Search posts, tags, users...",
                    onSearchButtonClicked: {
                        triggerSearch(immediate: true)
                    }
                )
                .padding(.horizontal, UISpacing.md)
                .padding(.top, UISpacing.sm)
                
                // Material Glass Typeahead Suggestions
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matches = (tagSuggestions + savedSearches)
                        .filter { $0.lowercased().contains(q) }
                        .prefix(5)
                    if !matches.isEmpty {
                        GlassCard(
                            material: MaterialDesignSystem.Glass.thin,
                            cornerRadius: UICornerRadius.md,
                            padding: 0
                        ) {
                            VStack(spacing: 0) {
                                ForEach(Array(matches), id: \.self) { item in
                                    Button(action: { 
                                        searchText = item
                                        triggerSearch(immediate: true)
                                    }) {
                                        HStack(spacing: UISpacing.sm) {
                                            Image(systemName: "text.magnifyingglass")
                                                .foregroundColor(UIColors.secondaryLabel)
                                                .font(.system(size: 14))
                                            Text(item)
                                                .foregroundColor(UIColors.label)
                                                .font(.system(size: 15))
                                            Spacer()
                                        }
                                        .padding(.horizontal, UISpacing.md)
                                        .padding(.vertical, UISpacing.sm)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if item != matches.last {
                                        Divider()
                                            .background(MaterialDesignSystem.GlassBorders.subtle)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, UISpacing.md)
                        .padding(.top, UISpacing.xs)
                    }
                }

                // Material Glass Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UISpacing.sm) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                triggerSearch()
                            }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .medium))
                                    .foregroundColor(selectedFilter == filter ? UIColors.accentPrimary : UIColors.secondaryLabel)
                                    .padding(.vertical, UISpacing.xs)
                                    .padding(.horizontal, UISpacing.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .glassButton(
                                material: selectedFilter == filter ? MaterialDesignSystem.Glass.regular : MaterialDesignSystem.Glass.ultraThin,
                                cornerRadius: UICornerRadius.sm
                            )
                            .overlay(
                                selectedFilter == filter ?
                                    RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                        .fill(MaterialDesignSystem.GlassColors.primary) : nil
                            )
                        }
                    }
                    .padding(.horizontal, UISpacing.md)
                    .padding(.vertical, UISpacing.sm)
                }
                
                // Material Glass Lookup Entry
                HStack {
                    NavigationLink(destination: LookupWizardView()) {
                        GlassCard(
                            material: MaterialDesignSystem.Glass.thin,
                            cornerRadius: UICornerRadius.md,
                            padding: UISpacing.sm
                        ) {
                            HStack(spacing: UISpacing.xs) {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(UIColors.accentPrimary)
                                    .font(.system(size: 16, weight: .medium))
                                Text("Start a Lookup")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(UIColors.label)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, UISpacing.md)
                
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
                        
                        // Material Glass Saved Searches
                        if !savedSearches.isEmpty {
                            VStack(alignment: .leading, spacing: UISpacing.sm) {
                                HStack {
                                    Text("Saved searches")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(UIColors.label)
                                    Spacer()
                                }
                                .padding(.horizontal, UISpacing.md)
                                
                                ForEach(savedSearches, id: \.self) { item in
                                    Button(action: { 
                                        searchText = item
                                        triggerSearch(immediate: true)
                                    }) {
                                        GlassCard(
                                            material: MaterialDesignSystem.Glass.thin,
                                            cornerRadius: UICornerRadius.md,
                                            padding: UISpacing.md
                                        ) {
                                            HStack(spacing: UISpacing.sm) {
                                                Image(systemName: "bookmark")
                                                    .foregroundColor(UIColors.accentPrimary)
                                                    .font(.system(size: 16, weight: .medium))
                                                Text(item)
                                                    .foregroundColor(UIColors.label)
                                                    .font(.system(size: 15))
                                                    .lineLimit(1)
                                                Spacer()
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, UISpacing.md)
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
                                                    try await services.searchService.deleteLegacySearch(query: item)
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
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            Text("Try searching for:")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(UIColors.secondaryLabel)
                                .padding(.horizontal, UISpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(["#ghosting", "#redflag", "#greendate", "@username"], id: \.self) { suggestion in
                                Button(action: {
                                    searchText = suggestion
                                    triggerSearch(immediate: true)
                                }) {
                                    GlassCard(
                                        material: MaterialDesignSystem.Glass.thin,
                                        cornerRadius: UICornerRadius.md,
                                        padding: UISpacing.md
                                    ) {
                                        HStack {
                                            Text(suggestion)
                                                .foregroundColor(UIColors.label)
                                                .font(.system(size: 15))
                                            Spacer()
                                            Image(systemName: "arrow.up.left")
                                                .foregroundColor(UIColors.secondaryLabel)
                                                .font(.system(size: 14))
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, UISpacing.md)
                            }
                        }
                        .padding(.top, UISpacing.lg)
                        
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
                        GlassButton(
                            "Save",
                            systemImage: "bookmark",
                            style: .secondary
                        ) {
                            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                do {
                                    try await services.searchService.saveLegacySearch(query: trimmed)
                                    // refresh list
                                    savedSearches = try await services.searchService.listSavedSearchQueries()
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
            .background(MaterialDesignSystem.Glass.ultraThin.ignoresSafeArea())
            .onChange(of: searchText) { triggerSearch() }
            .task {
                // Load saved searches on first appear
                do { savedSearches = try await services.searchService.listSavedSearchQueries() } catch { }
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
                let res = try await services.searchService.search(query: q, tags: [], sort: sort)
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

// MARK: - Material Glass Result Row
struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        GlassCard(
            material: MaterialDesignSystem.Context.card,
            cornerRadius: UICornerRadius.lg,
            padding: UISpacing.md
        ) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                HStack {
                    Text(result.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(UIColors.label)
                    Spacer()
                    Text(String(format: "%.0f%%", result.score * 100))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(UIColors.secondaryLabel)
                        .padding(.horizontal, UISpacing.xs)
                        .padding(.vertical, 2)
                        .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.xs))
                }
                
                Text(result.snippet)
                    .font(.system(size: 14))
                    .foregroundColor(UIColors.secondaryLabel)
                    .lineLimit(3)
                
                if !result.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UISpacing.xs) {
                            ForEach(result.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(UIColors.accentPrimary)
                                    .padding(.horizontal, UISpacing.xs)
                                    .padding(.vertical, 4)
                                    .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.xs))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: UICornerRadius.xs)
                                            .fill(MaterialDesignSystem.GlassColors.primary)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
