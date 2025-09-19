import SwiftUI

/// A view for displaying threaded comments with nested replies
struct CommentThreadView: View {
    let comments: [Comment]
    let currentUserVotes: [UUID: VoteType]
    let maxDepth: Int
    let onUpvote: (Comment) -> Void
    let onDownvote: (Comment) -> Void
    let onReply: (Comment) -> Void
    let onReport: (Comment) -> Void
    
    init(
        comments: [Comment],
        currentUserVotes: [UUID: VoteType] = [:],
        maxDepth: Int = 3,
        onUpvote: @escaping (Comment) -> Void,
        onDownvote: @escaping (Comment) -> Void,
        onReply: @escaping (Comment) -> Void,
        onReport: @escaping (Comment) -> Void
    ) {
        self.comments = comments
        self.currentUserVotes = currentUserVotes
        self.maxDepth = maxDepth
        self.onUpvote = onUpvote
        self.onDownvote = onDownvote
        self.onReply = onReply
        self.onReport = onReport
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: UISpacing.sm) {
            ForEach(topLevelComments, id: \.id) { comment in
                CommentView(
                    comment: comment,
                    currentUserVote: currentUserVotes[comment.id] ?? .none,
                    depth: 0,
                    maxDepth: maxDepth,
                    replies: getReplies(for: comment.id),
                    currentUserVotes: currentUserVotes,
                    onUpvote: onUpvote,
                    onDownvote: onDownvote,
                    onReply: onReply,
                    onReport: onReport
                )
            }
        }
    }
    
    private var topLevelComments: [Comment] {
        comments.filter { $0.parentId == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    private func getReplies(for commentId: UUID) -> [Comment] {
        comments.filter { $0.parentId == commentId }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

/// Individual comment view with threading support
struct CommentView: View {
    let comment: Comment
    let currentUserVote: VoteType
    let depth: Int
    let maxDepth: Int
    let replies: [Comment]
    let currentUserVotes: [UUID: VoteType]
    let onUpvote: (Comment) -> Void
    let onDownvote: (Comment) -> Void
    let onReply: (Comment) -> Void
    let onReport: (Comment) -> Void
    
    @State private var isExpanded = true
    @State private var showReplyField = false
    @State private var replyText = ""
    
    private let indentWidth: CGFloat = 20
    private let maxIndentWidth: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main comment
            HStack(alignment: .top, spacing: 0) {
                // Threading indicator
                if depth > 0 {
                    threadingIndicator
                }
                
                // Comment content
                VStack(alignment: .leading, spacing: UISpacing.xs) {
                    commentHeader
                    commentContent
                    commentActions
                }
                .padding(.leading, depth > 0 ? UISpacing.xs : 0)
                .padding(.trailing, UISpacing.sm)
                .padding(.vertical, UISpacing.sm)
                .background(
                    depth > 0 ? MaterialDesignSystem.GlassColors.neutral : Color.clear,
                    in: RoundedRectangle(cornerRadius: UICornerRadius.sm)
                )
            }
            
            // Reply field
            if showReplyField {
                replyField
            }
            
            // Nested replies
            if isExpanded && !replies.isEmpty && depth < maxDepth {
                VStack(alignment: .leading, spacing: UISpacing.xs) {
                    ForEach(replies, id: \.id) { reply in
                        CommentView(
                            comment: reply,
                            currentUserVote: currentUserVotes[reply.id] ?? .none,
                            depth: depth + 1,
                            maxDepth: maxDepth,
                            replies: [], // Simplified for now - could be recursive
                            currentUserVotes: currentUserVotes,
                            onUpvote: onUpvote,
                            onDownvote: onDownvote,
                            onReply: onReply,
                            onReport: onReport
                        )
                    }
                }
            }
            
            // Show more replies button
            if !replies.isEmpty && (!isExpanded || depth >= maxDepth) {
                showMoreRepliesButton
            }
        }
    }
    
    // MARK: - Threading Indicator
    
    private var threadingIndicator: some View {
        Rectangle()
            .fill(MaterialDesignSystem.GlassBorders.subtle)
            .frame(width: 2)
            .padding(.leading, min(CGFloat(depth) * indentWidth, maxIndentWidth))
    }
    
    // MARK: - Comment Header
    
    private var commentHeader: some View {
        HStack {
            // Anonymous username (would come from user lookup)
            Text("Anonymous User")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(UIColors.accentPrimary)
            
            // Reputation indicator
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                
                Text("1.2k") // Would come from user data
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            
            Spacer()
            
            // Timestamp
            Text(timeAgoString(from: comment.createdAt))
                .font(.caption2)
                .foregroundColor(UIColors.secondaryLabel)
            
            // Collapse/expand button for replies
            if !replies.isEmpty {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(UIColors.secondaryLabel)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Comment Content
    
    private var commentContent: some View {
        Text(comment.content)
            .font(.body)
            .foregroundColor(UIColors.label)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Comment Actions
    
    private var commentActions: some View {
        HStack(spacing: UISpacing.md) {
            // Vote buttons
            HStack(spacing: UISpacing.xs) {
                Button(action: { onUpvote(comment) }) {
                    HStack(spacing: 2) {
                        Image(systemName: currentUserVote == .upvote ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.caption)
                        
                        Text("\(comment.upvotes)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(currentUserVote == .upvote ? UIColors.accentPrimary : UIColors.secondaryLabel)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
                
                Text("\(comment.netScore)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(comment.netScore >= 0 ? UIColors.success : UIColors.danger)
                
                Button(action: { onDownvote(comment) }) {
                    HStack(spacing: 2) {
                        Image(systemName: currentUserVote == .downvote ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.caption)
                        
                        Text("\(comment.downvotes)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(currentUserVote == .downvote ? UIColors.danger : UIColors.secondaryLabel)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
            }
            
            // Reply button
            if depth < maxDepth {
                Button(action: { showReplyField.toggle() }) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption)
                        
                        Text("Reply")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(showReplyField ? UIColors.accentPrimary : UIColors.secondaryLabel)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
            }
            
            Spacer()
            
            // Report button
            Button(action: { onReport(comment) }) {
                Image(systemName: "flag")
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            .buttonStyle(ScaleButtonStyle(scaleAmount: 0.9))
        }
    }
    
    // MARK: - Reply Field
    
    private var replyField: some View {
        VStack(alignment: .leading, spacing: UISpacing.xs) {
            HStack(alignment: .top, spacing: UISpacing.xs) {
                TextField("Write a reply...", text: $replyText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(UISpacing.sm)
                    .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: UICornerRadius.sm)
                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                    )
                
                Button(action: submitReply) {
                    Image(systemName: "paperplane.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(UISpacing.sm)
                        .background(UIColors.accentPrimary, in: Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.leading, min(CGFloat(depth + 1) * indentWidth, maxIndentWidth))
        .padding(.top, UISpacing.xs)
    }
    
    // MARK: - Show More Replies Button
    
    private var showMoreRepliesButton: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: UISpacing.xs) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                
                Text(isExpanded ? "Hide replies" : "Show \(replies.count) more replies")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(UIColors.accentPrimary)
            .padding(.horizontal, UISpacing.sm)
            .padding(.vertical, UISpacing.xs)
            .background(MaterialDesignSystem.GlassColors.primary, in: Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.leading, min(CGFloat(depth + 1) * indentWidth, maxIndentWidth))
        .padding(.top, UISpacing.xs)
    }
    
    // MARK: - Helper Methods
    
    private func submitReply() {
        // Create new comment and call onReply
        let newComment = Comment(
            authorId: UUID(), // Would come from current user
            parentId: comment.id,
            contentId: comment.contentId,
            contentType: comment.contentType,
            content: replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        onReply(newComment)
        replyText = ""
        showReplyField = false
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Comment Input View

/// A standalone comment input view for creating new top-level comments
struct CommentInputView: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: (String) -> Void
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "Add a comment...",
        onSubmit: @escaping (String) -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        VStack(spacing: UISpacing.sm) {
            HStack(alignment: .top, spacing: UISpacing.sm) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .padding(UISpacing.md)
                    .background(MaterialDesignSystem.Glass.thin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: UICornerRadius.md)
                            .stroke(
                                isFocused ? UIColors.accentPrimary : MaterialDesignSystem.GlassBorders.subtle,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                
                Button(action: submitComment) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(UISpacing.md)
                        .background(UIColors.accentPrimary, in: Circle())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if isFocused {
                HStack {
                    Text("Be respectful and constructive in your comments")
                        .font(.caption)
                        .foregroundColor(UIColors.secondaryLabel)
                    
                    Spacer()
                    
                    Text("\(text.count)/2000")
                        .font(.caption)
                        .foregroundColor(text.count > 1800 ? UIColors.warning : UIColors.secondaryLabel)
                }
                .padding(.horizontal, UISpacing.sm)
            }
        }
        .padding(UISpacing.md)
        .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.lg))
    }
    
    private func submitComment() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        onSubmit(trimmedText)
        text = ""
        isFocused = false
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: UISpacing.lg) {
            CommentInputView(
                text: .constant(""),
                onSubmit: { _ in }
            )
            
            CommentThreadView(
                comments: [
                    Comment(
                        authorId: UUID(),
                        contentId: UUID(),
                        contentType: .post,
                        content: "This is a great post! I've had similar experiences and can definitely relate to what you're saying here.",
                        upvotes: 12,
                        downvotes: 1
                    ),
                    Comment(
                        id: UUID(),
                        authorId: UUID(),
                        parentId: UUID(), // Would be the first comment's ID
                        contentId: UUID(),
                        contentType: .post,
                        content: "Thanks for sharing your perspective! What specific strategies worked best for you?",
                        upvotes: 5,
                        downvotes: 0
                    ),
                    Comment(
                        authorId: UUID(),
                        contentId: UUID(),
                        contentType: .post,
                        content: "I disagree with some of the points made here. In my experience, the approach described doesn't always work and can sometimes backfire.",
                        upvotes: 3,
                        downvotes: 8
                    )
                ],
                onUpvote: { _ in },
                onDownvote: { _ in },
                onReply: { _ in },
                onReport: { _ in }
            )
        }
        .padding()
    }
    .background(UIColors.groupedBackground)
}