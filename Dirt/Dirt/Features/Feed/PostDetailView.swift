import SwiftUI

struct PostDetailView: View {
    let post: Post
    @StateObject private var viewModel = PostDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingReportSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    // Post content
                    PostDetailContent(post: post, viewModel: viewModel)
                    
                    // Comments section
                    PostCommentsSection(
                        comments: viewModel.comments,
                        isLoading: viewModel.isLoadingComments,
                        onLoadMore: {
                            Task {
                                await viewModel.loadMoreComments()
                            }
                        }
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .background(ColorPalette.background.primary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.accent.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            HapticFeedback.buttonTap()
                            Task {
                                await viewModel.savePost(post)
                            }
                        }) {
                            Label(
                                viewModel.isSaved ? "Unsave" : "Save",
                                systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark"
                            )
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            HapticFeedback.buttonTap()
                            showingReportSheet = true
                        }) {
                            Label("Report", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(ColorPalette.accent.primary)
                    }
                }
            }
        }
        .task {
            await viewModel.loadPostDetails(post)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [viewModel.shareText])
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportSheet(post: post) { reason in
                Task {
                    await viewModel.reportPost(post, reason: reason)
                }
            }
        }
    }
}

// MARK: - Post Detail Content
struct PostDetailContent: View {
    let post: Post
    @ObservedObject var viewModel: PostDetailViewModel
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                PostDetailHeader(post: post)
                
                // Badges
                PostDetailBadges(post: post)
                
                // Title and content
                PostDetailText(post: post)
                
                // Media
                if post.hasMedia {
                    PostDetailMedia(mediaURLs: post.mediaURLs)
                }
                
                // Engagement metrics
                PostDetailMetrics(post: post)
                
                // Action buttons
                PostDetailActions(post: post, viewModel: viewModel)
                
                // Comment input
                CommentInputSection(
                    commentText: $viewModel.newCommentText,
                    isSubmitting: viewModel.isSubmittingComment,
                    onSubmit: {
                        Task {
                            await viewModel.submitComment(for: post)
                        }
                    }
                )
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Header
struct PostDetailHeader: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            UserAvatar(size: .large)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Anonymous User")
                    .font(TypographyStyles.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.text.primary)
                
                Text(post.timeAgo)
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.text.secondary)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Label("\(post.viewCount) views", systemImage: "eye")
                    Label("\(post.shareCount) shares", systemImage: "square.and.arrow.up")
                }
                .font(TypographyStyles.caption1)
                .foregroundColor(ColorPalette.text.tertiary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Badges
struct PostDetailBadges: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            CategoryBadge(category: post.category)
            SentimentBadge(sentiment: post.sentiment)
            Spacer()
        }
    }
}

// MARK: - Text Content
struct PostDetailText: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(post.title)
                .font(TypographyStyles.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.text.primary)
            
            Text(post.content)
                .font(TypographyStyles.body)
                .foregroundColor(ColorPalette.text.primary)
                .lineSpacing(4)
            
            if !post.tags.isEmpty {
                PostTags(tags: post.tags)
            }
        }
    }
}

// MARK: - Tags
struct PostTags: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: DesignTokens.Spacing.sm)
        ], spacing: DesignTokens.Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(TypographyStyles.caption1)
                    .fontWeight(.medium)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(ColorPalette.surface.secondary)
                    .foregroundColor(ColorPalette.accent.primary)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Media
struct PostDetailMedia: View {
    let mediaURLs: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(mediaURLs, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(ColorPalette.surface.secondary)
                            .overlay {
                                LoadingSpinner(size: .medium)
                            }
                    }
                    .frame(maxWidth: 300, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
    }
}

// MARK: - Metrics
struct PostDetailMetrics: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            MetricItem(
                icon: "arrow.up",
                count: post.upvotes,
                label: "Upvotes",
                color: ColorPalette.semantic.success
            )
            
            MetricItem(
                icon: "arrow.down",
                count: post.downvotes,
                label: "Downvotes",
                color: ColorPalette.semantic.error
            )
            
            MetricItem(
                icon: "bubble.left",
                count: post.commentCount,
                label: "Comments",
                color: ColorPalette.accent.primary
            )
            
            MetricItem(
                icon: "bookmark",
                count: post.saveCount,
                label: "Saves",
                color: ColorPalette.text.secondary
            )
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .background(ColorPalette.surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }
}

struct MetricItem: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(TypographyStyles.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(TypographyStyles.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.text.primary)
            
            Text(label)
                .font(TypographyStyles.caption2)
                .foregroundColor(ColorPalette.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Actions
struct PostDetailActions: View {
    let post: Post
    @ObservedObject var viewModel: PostDetailViewModel
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Upvote
            ActionButton(
                title: viewModel.isLiked ? "Liked" : "Like",
                style: viewModel.isLiked ? .primary : .secondary,
                size: .medium,
                icon: "arrow.up",
                action: {
                    Task {
                        await viewModel.toggleLike(for: post)
                    }
                }
            )
            
            // Downvote
            ActionButton(
                title: viewModel.isDisliked ? "Disliked" : "Dislike",
                style: viewModel.isDisliked ? .destructive : .secondary,
                size: .medium,
                icon: "arrow.down",
                action: {
                    Task {
                        await viewModel.toggleDislike(for: post)
                    }
                }
            )
        }
    }
}

// MARK: - Comment Input
struct CommentInputSection: View {
    @Binding var commentText: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Add a comment")
                .font(TypographyStyles.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.text.primary)
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                CustomTextField(
                    text: $commentText,
                    placeholder: "Share your thoughts...",
                    style: .multiline
                )
                
                Button(action: {
                    HapticFeedback.buttonTap()
                    onSubmit()
                }) {
                    if isSubmitting {
                        LoadingSpinner(size: .small)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(TypographyStyles.callout)
                    }
                }
                .foregroundColor(ColorPalette.accent.primary)
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
    }
}

// MARK: - Comments Section
struct PostCommentsSection: View {
    let comments: [Comment]
    let isLoading: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Comments (\(comments.count))")
                    .font(TypographyStyles.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.text.primary)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            
            if comments.isEmpty && !isLoading {
                CommentsEmptyState()
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(comments) { comment in
                        CommentCard(comment: comment)
                    }
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            LoadingSpinner(size: .medium)
                            Spacer()
                        }
                        .padding(.vertical, DesignTokens.Spacing.lg)
                    }
                }
            }
        }
    }
}

// MARK: - Comment Card
struct CommentCard: View {
    let comment: Comment
    @State private var isLiked = false
    @State private var showingReplies = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Comment header
                HStack(spacing: DesignTokens.Spacing.sm) {
                    UserAvatar(size: .small)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Anonymous User")
                            .font(TypographyStyles.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorPalette.text.primary)
                        
                        Text(comment.timeAgo)
                            .font(TypographyStyles.caption1)
                            .foregroundColor(ColorPalette.text.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.buttonTap()
                        // Show comment options
                    }) {
                        Image(systemName: "ellipsis")
                            .font(TypographyStyles.caption1)
                            .foregroundColor(ColorPalette.text.secondary)
                    }
                }
                
                // Comment content
                Text(comment.content)
                    .font(TypographyStyles.body)
                    .foregroundColor(ColorPalette.text.primary)
                
                // Comment actions
                HStack(spacing: DesignTokens.Spacing.lg) {
                    Button(action: {
                        HapticFeedback.likeAction()
                        withAnimation(.easeInOut(duration: AnimationPreferences.quickDuration)) {
                            isLiked.toggle()
                        }
                    }) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(TypographyStyles.caption1)
                            
                            if comment.likeCount > 0 {
                                Text("\(comment.likeCount)")
                                    .font(TypographyStyles.caption2)
                            }
                        }
                        .foregroundColor(isLiked ? ColorPalette.semantic.error : ColorPalette.text.secondary)
                    }
                    
                    Button(action: {
                        HapticFeedback.buttonTap()
                        // Reply to comment
                    }) {
                        Text("Reply")
                            .font(TypographyStyles.caption1)
                            .foregroundColor(ColorPalette.text.secondary)
                    }
                    
                    if comment.replyCount > 0 {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            withAnimation(.easeInOut(duration: AnimationPreferences.standardDuration)) {
                                showingReplies.toggle()
                            }
                        }) {
                            Text("\(showingReplies ? "Hide" : "Show") \(comment.replyCount) replies")
                                .font(TypographyStyles.caption1)
                                .foregroundColor(ColorPalette.accent.primary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Replies (if showing)
                if showingReplies && !comment.replies.isEmpty {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(comment.replies) { reply in
                            CommentReply(reply: reply)
                        }
                    }
                    .padding(.leading, DesignTokens.Spacing.lg)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
}

// MARK: - Comment Reply
struct CommentReply: View {
    let reply: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            UserAvatar(size: .small)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("Anonymous User")
                        .font(TypographyStyles.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.text.primary)
                    
                    Text(reply.timeAgo)
                        .font(TypographyStyles.caption2)
                        .foregroundColor(ColorPalette.text.secondary)
                    
                    Spacer()
                }
                
                Text(reply.content)
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.text.primary)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(ColorPalette.surface.secondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }
}

// MARK: - Comments Empty State
struct CommentsEmptyState: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bubble.left")
                .font(.system(size: 32))
                .foregroundColor(ColorPalette.text.tertiary)
            
            Text("No comments yet")
                .font(TypographyStyles.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.text.primary)
            
            Text("Be the first to share your thoughts!")
                .font(TypographyStyles.body)
                .foregroundColor(ColorPalette.text.secondary)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Report Sheet
struct ReportSheet: View {
    let post: Post
    let onReport: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = ""
    
    private let reportReasons = [
        "Inappropriate content",
        "Harassment or bullying",
        "Spam or misleading",
        "False information",
        "Hate speech",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("Why are you reporting this post?")
                    .font(TypographyStyles.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.text.primary)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(reportReasons, id: \.self) { reason in
                        Button(action: {
                            HapticFeedback.selection()
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason)
                                    .font(TypographyStyles.body)
                                    .foregroundColor(ColorPalette.text.primary)
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ColorPalette.accent.primary)
                                }
                            }
                            .padding(DesignTokens.Spacing.md)
                            .background(
                                selectedReason == reason ?
                                ColorPalette.accent.primary.opacity(0.1) :
                                ColorPalette.surface.secondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                        }
                    }
                }
                
                Spacer()
                
                ActionButton(
                    title: "Submit Report",
                    style: .destructive,
                    size: .large,
                    isEnabled: !selectedReason.isEmpty,
                    action: {
                        onReport(selectedReason)
                        dismiss()
                    }
                )
            }
            .padding(DesignTokens.Spacing.lg)
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(ColorPalette.accent.primary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PostDetailView(post: Post(
        authorId: UUID(),
        title: "Amazing first date experience!",
        content: "Had the most incredible first date last night. We went to this cozy little coffee shop downtown and ended up talking for over 4 hours! The conversation flowed so naturally - we discussed everything from our favorite travel destinations to our career goals. They were genuinely interested in what I had to say and asked thoughtful follow-up questions. What really impressed me was how they remembered small details I mentioned earlier in the conversation. We're already planning our second date for this weekend!",
        category: .success,
        sentiment: .positive,
        tags: ["coffee", "conversation", "connection"],
        upvotes: 42,
        downvotes: 2,
        commentCount: 18,
        viewCount: 156,
        shareCount: 8,
        saveCount: 23,
        mediaURLs: []
    ))
}