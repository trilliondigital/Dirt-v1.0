import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var commentText = ""
    @State private var showingReportSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Post Content
                    PostDetailContent(post: post)
                    
                    Divider()
                    
                    // Comments Section
                    CommentsSection(
                        comments: viewModel.comments,
                        isLoading: viewModel.isLoadingComments
                    )
                }
                .padding()
            }
            .navigationTitle("Post")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Save Post") {
                            viewModel.savePost(post)
                        }
                        
                        Button("Share Post") {
                            viewModel.sharePost(post)
                        }
                        
                        Button("Report Post", role: .destructive) {
                            showingReportSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CommentInputBar(
                    text: $commentText,
                    onSend: {
                        viewModel.addComment(to: post, text: commentText)
                        commentText = ""
                    }
                )
            }
        }
        .task {
            await viewModel.loadComments(for: post)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportSheet(post: post)
        }
    }
}

// MARK: - Post Detail Content
struct PostDetailContent: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            PostDetailHeader(post: post)
            
            // Title
            Text(post.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            // Content
            Text(post.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Tags
            if !post.tags.isEmpty {
                TagsView(tags: post.tags)
            }
            
            // Media
            if post.hasMedia {
                PostMediaView(mediaURLs: post.mediaURLs)
            }
            
            // Engagement
            PostDetailEngagementBar(post: post)
        }
    }
}

// MARK: - Post Detail Header
struct PostDetailHeader: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Author Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Anonymous")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    SentimentBadge(sentiment: post.sentiment)
                }
                
                HStack(spacing: 12) {
                    Text(post.category.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Text(post.timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Post Detail Engagement Bar
struct PostDetailEngagementBar: View {
    let post: Post
    @State private var hasUpvoted = false
    @State private var hasDownvoted = false
    
    var body: some View {
        HStack(spacing: 24) {
            // Upvote
            Button(action: { hasUpvoted.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: hasUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title3)
                    Text("\(post.upvotes)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(hasUpvoted ? .green : .secondary)
            }
            
            // Downvote
            Button(action: { hasDownvoted.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: hasDownvoted ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.title3)
                    Text("\(post.downvotes)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(hasDownvoted ? .red : .secondary)
            }
            
            // Comments
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.title3)
                Text("\(post.commentCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            
            Spacer()
            
            // Views
            HStack(spacing: 6) {
                Image(systemName: "eye")
                    .font(.subheadline)
                Text("\(post.viewCount)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Comments Section
struct CommentsSection: View {
    let comments: [Comment]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comments (\(comments.count))")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to share your thoughts!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(comments) { comment in
                        CommentCard(comment: comment)
                    }
                }
            }
        }
    }
}

// MARK: - Comment Input Bar
struct CommentInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a comment...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(text.isEmpty ? .gray : .blue)
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

#Preview {
    PostDetailView(
        post: Post(
            authorId: UUID(),
            title: "First date went amazing!",
            content: "Had an incredible first date last night. Great conversation, shared interests, and genuine connection. Sometimes the apps do work! We talked for hours and I'm really excited to see her again.",
            category: .success,
            sentiment: .positive,
            tags: ["first-date", "success", "dating-apps"],
            upvotes: 24,
            downvotes: 2,
            commentCount: 8,
            viewCount: 156
        )
    )
}