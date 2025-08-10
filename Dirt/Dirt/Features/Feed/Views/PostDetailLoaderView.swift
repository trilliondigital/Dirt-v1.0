import SwiftUI

struct PostDetailLoaderView: View {
    let postId: UUID
    @State private var data: PostDetailData?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let d = data {
                PostDetailView(
                    postId: d.postId,
                    username: d.username,
                    userInitial: d.userInitial,
                    userColor: d.userColor,
                    timestamp: d.timestamp,
                    content: d.content,
                    imageName: d.imageName,
                    isVerified: d.isVerified,
                    tags: d.tags,
                    upvotes: d.upvotes,
                    comments: d.comments,
                    shares: d.shares
                )
            } else if isLoading {
                ProgressView().controlSize(.large)
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
                    Text(errorMessage)
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.bordered)
                }
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Post")
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            data = try await PostService.shared.fetchPost(by: postId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load post."
            isLoading = false
        }
    }
}

struct PostDetailLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { PostDetailLoaderView(postId: UUID()) }
    }
}
