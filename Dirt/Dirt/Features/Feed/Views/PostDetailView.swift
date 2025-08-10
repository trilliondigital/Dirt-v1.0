import SwiftUI

struct PostDetailView: View {
    let username: String
    let userInitial: String
    let userColor: Color
    let timestamp: String
    let content: String
    let imageName: String?
    let isVerified: Bool
    let tags: [String]
    let upvotes: Int
    let comments: Int
    let shares: Int
    
    @State private var helpful: Bool = false
    @State private var bookmarked: Bool = false
    @State private var showComments: Bool = false
    @State private var showReportSheet: Bool = false
    @State private var selectedReport: ReportReason? = nil
    @State private var isSoftHidden: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    Circle()
                        .fill(userColor.opacity(0.2))
                        .overlay(Text(userInitial).font(.headline))
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(username).font(.subheadline).fontWeight(.semibold)
                            if isVerified { Image(systemName: "checkmark.seal.fill").foregroundColor(.blue) }
                        }
                        Text(timestamp).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Content
                Text(content)
                    .font(.body)
                    .padding(.horizontal)
                
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                
                // Tags
                if !tags.isEmpty {
                    FlowLayout(tags, spacing: 8) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button { helpful.toggle() } label: {
                        Label("\(upvotes)", systemImage: helpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    }
                    Button { showComments = true } label: {
                        Label("\(comments)", systemImage: "bubble.left")
                    }
                    Button { /* share */ } label: {
                        Label("\(shares)", systemImage: "arrowshape.turn.up.right")
                    }
                    Button { showReportSheet = true } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Spacer()
                    Button { bookmarked.toggle() } label: {
                        Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .opacity(isSoftHidden ? 0.4 : 1.0)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showComments) {
            NavigationView { Text("Comments").navigationTitle("Comments") }
        }
        .sheet(isPresented: $showReportSheet) {
            NavigationView {
                List {
                    Section("Report reason") {
                        ForEach(ReportReason.allCases) { reason in
                            HStack {
                                Text(reason.rawValue)
                                Spacer()
                                if selectedReport == reason { Image(systemName: "checkmark").foregroundColor(.blue) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedReport = reason }
                        }
                    }
                }
                .navigationTitle("Report Post")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showReportSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            isSoftHidden = true
                            showReportSheet = false
                        }.disabled(selectedReport == nil)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// Simple flow layout for tag chips
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    private let items: [Data.Element]
    private let spacing: CGFloat
    private let content: (Data.Element) -> Content
    
    init(_ items: Data, spacing: CGFloat, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = Array(items)
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding(.all, 4)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height + spacing
                            }
                            let result = width
                            if item == items.last { width = 0 } else { width -= d.width + spacing }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 10)
    }
}

struct PostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PostDetailView(
                username: "Alex Johnson",
                userInitial: "AJ",
                userColor: .blue,
                timestamp: "2h ago",
                content: "Sample post content lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                imageName: nil,
                isVerified: true,
                tags: ["green flag", "great conversation"],
                upvotes: 1200,
                comments: 42,
                shares: 8
            )
        }
    }
}
