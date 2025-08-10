import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "Recent"
    let filters = ["Recent", "Popular", "Nearby", "Trending"]
    @State private var savedSearches: [String] = ["#ghosting", "#redflag", "near: Austin", "@alex", "green flag"]
    
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
                
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
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
                    ScrollView {
                        VStack(spacing: 16) {
                            // In a real app, these would be actual search results
                            ForEach(0..<5) { _ in
                                HStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Search Result")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("This is a sample search result that would match your query.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .cardBackground()
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
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
                            if !savedSearches.contains(trimmed) {
                                savedSearches.insert(trimmed, at: 0)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
