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
            // Glass search bar
            GlassSearchBar(
                text: $search,
                placeholder: "Search topics"
            )
            .padding([.horizontal, .top])
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: UISpacing.sm) {
                    ForEach(filtered) { topic in
                        NavigationLink(destination: Text("Filtered feed for \(topic.title)")) {
                            GlassCard(
                                material: MaterialDesignSystem.Context.card,
                                padding: UISpacing.md
                            ) {
                                HStack(alignment: .center, spacing: UISpacing.sm) {
                                    Text(topic.icon)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: UISpacing.xxs) {
                                        Text(topic.title)
                                            .foregroundColor(UIColors.label)
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        Text("\(topic.count) posts")
                                            .font(.caption)
                                            .foregroundColor(UIColors.secondaryLabel)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(UIColors.secondaryLabel)
                                }
                            }
                            .glassAppear()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Topics")
        .navigationBarTitleDisplayMode(.inline)
        .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
    }
}

struct TopicsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { TopicsView() }
    }
}
