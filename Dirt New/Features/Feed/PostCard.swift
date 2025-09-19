import SwiftUI

struct PostCard: View {
    let post: Post
    let onTap: () -> Void
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let onReport: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                PostHeader(post: post)
                
                // Content
                PostContent(post: post)
                
                // Media (if any)
                if post.hasMedia {
                    PostMediaView(mediaURLs: post.mediaURLs)
                }
                
                // Engagement Bar
                PostEngagementBar(
                    post: post,
                    onUpvote: onUpvote,
                    onDownvote: onDownvote,
                    onComment: onTap,
                    onMore: { showingActionSheet = true }
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Post Actions", isPresented: $showingActionSheet) {
            Button("Save Post") { onSave() }
            Button("Share Post") { onShare() }
            Button("Report Post", role: .destructive) { onReport() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Post Header
struct PostHeader: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Author Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Anonymous")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Sentiment Badge
                    SentimentBadge(sentiment: post.sentiment)
                }
                
                HStack(spacing: 8) {
                    // Category
                    Text(post.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    // Time
                    Text(post.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Post Content
struct PostContent: View {
    let post: Post
    @State private var isExpanded = false
    
    private let previewLength = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
            
            // Content
            let shouldTruncate = post.content.count > previewLength
            let displayContent = shouldTruncate && !isExpanded 
                ? String(post.content.prefix(previewLength)) + "..."
                : post.content
            
            Text(displayContent)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            if shouldTruncate {
                Button(isExpanded ? "Show less" : "Show more") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Tags
            if !post.tags.isEmpty {
                TagsView(tags: post.tags)
            }
        }
    }
}

// MARK: - Sentiment Badge
struct SentimentBadge: View {
    let sentiment: PostSentiment
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sentiment.iconName)
                .font(.caption)
            Text(sentiment.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color(sentiment.color).opacity(0.2))
        .foregroundColor(Color(sentiment.color))
        .cornerRadius(8)
    }
}

// MARK: - Tags View
struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

// MARK: - Post Media View
struct PostMediaView: View {
    let mediaURLs: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mediaURLs, id: \.self) { url in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

// MARK: - Post Engagement Bar
struct PostEngagementBar: View {
    let post: Post
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onComment: () -> Void
    let onMore: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Upvote
            EngagementButton(
                icon: "arrow.up",
                count: post.upvotes,
                color: .green,
                action: onUpvote
            )
            
            // Downvote
            EngagementButton(
                icon: "arrow.down",
                count: post.downvotes,
                color: .red,
                action: onDownvote
            )
            
            // Comments
            EngagementButton(
                icon: "bubble.left",
                count: post.commentCount,
                color: .blue,
                action: onComment
            )
            
            Spacer()
            
            // More actions
            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EngagementButton: View {
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text("\(count)")
                    .font(.caption)
            }
            .foregroundColor(color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            PostCard(
                post: Post(
                    authorId: UUID(),
                    title: "First date went amazing!",
                    content: "Had an incredible first date last night. Great conversation, shared interests, and genuine connection. Sometimes the apps do work! We talked for hours and I'm really excited to see her again.",
                    category: .success,
                    sentiment: .positive,
                    tags: ["first-date", "success", "dating-apps"],
                    upvotes: 24,
                    downvotes: 2,
                    commentCount: 8
                ),
                onTap: {},
                onUpvote: {},
                onDownvote: {},
                onSave: {},
                onShare: {},
                onReport: {}
            )
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}