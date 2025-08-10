import SwiftUI

struct TopicsView: View {
    struct Topic: Identifiable { let id = UUID(); let icon: String; let title: String; let count: Int }
    @State private var topics: [Topic] = [
        .init(icon: "🚩", title: "Red Flags", count: 1243),
        .init(icon: "✅", title: "Green Flags", count: 987),
        .init(icon: "👻", title: "Ghosting", count: 612),
        .init(icon: "💬", title: "Great Conversation", count: 358),
        .init(icon: "📅", title: "First Dates", count: 421),
        .init(icon: "🛡️", title: "Safety Tips", count: 205)
    ]
    @State private var search: String = ""
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var filtered: [Topic] {
        guard !search.isEmpty else { return topics }
        return topics.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search topics", text: $search)
                if !search.isEmpty {
                    Button { search.removeAll() } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding([.horizontal, .top])
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filtered) { topic in
                        NavigationLink(destination: Text("Filtered feed for \(topic.title)")) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(topic.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(topic.title)
                                        .foregroundColor(.primary)
                                    Text("\(topic.count) posts")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Topics")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct TopicsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { TopicsView() }
    }
}
