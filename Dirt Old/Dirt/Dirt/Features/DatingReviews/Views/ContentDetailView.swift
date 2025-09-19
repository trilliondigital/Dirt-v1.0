import SwiftUI

/// A detailed view for individual reviews or posts with full comment threads
struct ContentDetailView: View {
    let contentItem: ContentItem
    @State private var comments: [Comment] = []
    @State private var userVotes: [UUID: VoteType] = [:]
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var showingReportSheet = false
    
    let onVote: (UUID, ContentType, VoteType) -> Void
    let onReport: (UUID, ContentType) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UISpacing.lg) {
                // Main content
                mainContentSection
                
                // Comments section
                commentsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: moreButton)
        .sheet(isPresented: $showingReportSheet) {
            ReportContentSheet(
                contentId: contentItem.id,
                contentType: contentType,
                onReport: onReport
            )
        }
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Main Content Section
    
    @ViewBuilder
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: UISpacing.md) {
            switch contentItem {
            case .review(let review):
                DetailedReviewView(
                    review: review,
                    currentUserVote: userVotes[review.id] ?? .none,
                    onUpvote: { onVote(review.id, .review, .upvote) },
                    onDownvote: { onVote(review.id, .review, .downvote) }
                )
                
            case .post(let post):
                DetailedPostView(
                    post: post,
                    currentUserVote: userVotes[post.id] ?? .none,
                    onUpvote: { onVote(post.id, .post, .upvote) },
                    onDownvote: { onVote(post.id, .post, .downvote) }
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: UISpacing.md) {
            // Comments header
            HStack {
                Text("Comments")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("(\(comments.count))")
                    .font(.title2)
                    .foregroundColor(UIColors.secondaryLabel)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Comment input
            CommentInputView(
                text: $newCommentText,
                onSubmit: submitComment
            )
            .padding(.horizontal)
            
            // Comments thread
            if comments.isEmpty && !isLoading {
                emptyCommentsView
            } else {
                CommentThreadView(
                    comments: comments,
                    currentUserVotes: userVotes,
                    onUpvote: { comment in
                        onVote(comment.id, .comment, .upvote)
                    },
                    onDownvote: { comment in
                        onVote(comment.id, .comment, .downvote)
                    },
                    onReply: { comment in
                        // Handle reply submission
                        submitReply(to: comment)
                    },
                    onReport: { comment in
                        onReport(comment.id, .comment)
                    }
                )
                .padding(.horizontal)
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Empty Comments View
    
    private var emptyCommentsView: some View {
        VStack(spacing: UISpacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(UIColors.secondaryLabel)
            
            Text("No comments yet")
                .font(.headline)
                .foregroundColor(UIColors.secondaryLabel)
            
            Text("Be the first to share your thoughts!")
                .font(.body)
                .foregroundColor(UIColors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, UISpacing.xl)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - More Button
    
    private var moreButton: some View {
        Menu {
            Button(action: { showingReportSheet = true }) {
                Label("Report Content", systemImage: "flag")
            }
            
            Button(action: shareContent) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Button(action: copyLink) {
                Label("Copy Link", systemImage: "link")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
    }
    
    // MARK: - Helper Properties
    
    private var contentType: ContentType {
        switch contentItem {
        case .review: return .review
        case .post: return .post
        }
    }
    
    // MARK: - Actions
    
    private func submitComment(_ text: String) {
        let comment = Comment(
            authorId: UUID(), // Would come from current user
            contentId: contentItem.id,
            contentType: contentType,
            content: text
        )
        
        // Add to local comments immediately for optimistic UI
        comments.append(comment)
        
        // TODO: Submit to backend
    }
    
    private func submitReply(to parentComment: Comment) {
        // TODO: Handle reply submission
    }
    
    private func loadComments() async {
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock comments data
        comments = [
            Comment(
                authorId: UUID(),
                contentId: contentItem.id,
                contentType: contentType,
                content: "This is really helpful! I've had similar experiences and can definitely relate to what you're saying here.",
                upvotes: 12,
                downvotes: 1
            ),
            Comment(
                authorId: UUID(),
                contentId: contentItem.id,
                contentType: contentType,
                content: "Thanks for sharing this. What specific strategies worked best for you in this situation?",
                upvotes: 5,
                downvotes: 0
            ),
            Comment(
                authorId: UUID(),
                contentId: contentItem.id,
                contentType: contentType,
                content: "I have to disagree with some of the points made here. In my experience, this approach doesn't always work and can sometimes backfire. It really depends on the specific context and the people involved.",
                upvotes: 3,
                downvotes: 8
            )
        ]
        
        isLoading = false
    }
    
    private func shareContent() {
        // TODO: Implement sharing
    }
    
    private func copyLink() {
        // TODO: Implement copy link
    }
}

// MARK: - Detailed Review View

struct DetailedReviewView: View {
    let review: Review
    let currentUserVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: UISpacing.md) {
            // Header
            HStack {
                HStack(spacing: UISpacing.xs) {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(UIColors.accentPrimary)
                    
                    Text(review.datingApp.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, UISpacing.sm)
                .padding(.vertical, UISpacing.xs)
                .background(MaterialDesignSystem.GlassColors.primary, in: Capsule())
                
                Spacer()
                
                Text(timeAgoString(from: review.createdAt))
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            
            // Screenshots
            if !review.profileScreenshots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UISpacing.sm) {
                        ForEach(Array(review.profileScreenshots.enumerated()), id: \.offset) { index, screenshot in
                            AsyncImage(url: URL(string: screenshot)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(MaterialDesignSystem.GlassColors.neutral)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(UIColors.secondaryLabel)
                                    )
                            }
                            .frame(width: 200, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: UICornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: UICornerRadius.md)
                                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Detailed ratings
            VStack(spacing: UISpacing.md) {
                // Overall rating
                HStack {
                    Text("Overall Rating")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    StarRatingView(rating: review.ratings.overall, maxRating: 5, size: .large)
                    
                    Text("\(review.ratings.overall)/5")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(UIColors.accentPrimary)
                }
                
                // Individual ratings
                VStack(spacing: UISpacing.sm) {
                    DetailedRatingRow(label: "Photos", rating: review.ratings.photos, description: "How accurate and appealing were the photos?")
                    DetailedRatingRow(label: "Bio", rating: review.ratings.bio, description: "How interesting and informative was the bio?")
                    DetailedRatingRow(label: "Conversation", rating: review.ratings.conversation, description: "How was the quality of conversation?")
                }
                .padding(UISpacing.md)
                .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
            }
            
            // Review content
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                Text("Review")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(review.content)
                    .font(.body)
                    .foregroundColor(UIColors.label)
            }
            
            // Tags
            if !review.tags.isEmpty {
                VStack(alignment: .leading, spacing: UISpacing.sm) {
                    Text("Tags")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    FlowLayout(spacing: UISpacing.xs) {
                        ForEach(review.tags, id: \.self) { tag in
                            TagView(text: tag, style: tagStyle(for: tag))
                        }
                    }
                }
            }
            
            // Engagement
            VoteButtonsView(
                upvotes: review.upvotes,
                downvotes: review.downvotes,
                currentVote: currentUserVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote
            )
        }
        .padding(UISpacing.md)
        .glassCard()
    }
    
    private func tagStyle(for tag: String) -> TagView.Style {
        if let reviewTag = ReviewTag.allCases.first(where: { $0.rawValue == tag }) {
            return reviewTag.isPositive ? .positive : .negative
        }
        return .neutral
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Detailed Post View

struct DetailedPostView: View {
    let post: DatingReviewPost
    let currentUserVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: UISpacing.md) {
            // Header
            HStack {
                HStack(spacing: UISpacing.xs) {
                    Image(systemName: post.category.iconName)
                        .foregroundColor(categoryColor)
                    
                    Text(post.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                }
                .padding(.horizontal, UISpacing.sm)
                .padding(.vertical, UISpacing.xs)
                .background(categoryColor.opacity(0.1), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
                
                Spacer()
                
                Text(timeAgoString(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            
            // Title
            Text(post.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(UIColors.label)
            
            // Content
            Text(post.content)
                .font(.body)
                .foregroundColor(UIColors.label)
            
            // Tags
            if !post.tags.isEmpty {
                FlowLayout(spacing: UISpacing.xs) {
                    ForEach(post.tags, id: \.self) { tag in
                        PostTagView(text: tag)
                    }
                }
            }
            
            // Engagement
            VoteButtonsView(
                upvotes: post.upvotes,
                downvotes: post.downvotes,
                currentVote: currentUserVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote
            )
        }
        .padding(UISpacing.md)
        .glassCard()
    }
    
    private var categoryColor: Color {
        switch post.category {
        case .advice: return .blue
        case .experience: return .purple
        case .question: return .orange
        case .strategy: return .green
        case .success: return .yellow
        case .rant: return .red
        case .general: return .gray
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

struct DetailedRatingRow: View {
    let label: String
    let rating: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                StarRatingView(rating: rating, maxRating: 5)
                
                Text("\(rating)/5")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(UIColors.accentPrimary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(UIColors.secondaryLabel)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: subviewSize.width, height: subviewSize.height))
                
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Report Sheet

struct ReportContentSheet: View {
    let contentId: UUID
    let contentType: ContentType
    let onReport: (UUID, ContentType) -> Void
    
    @State private var selectedReason: DatingReviewReportReason = .inappropriate
    @State private var additionalContext = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: UISpacing.lg) {
                Text("Why are you reporting this \(contentType.displayName.lowercased())?")
                    .font(.headline)
                
                VStack(spacing: UISpacing.xs) {
                    ForEach(DatingReviewReportReason.allCases, id: \.self) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text(reason.description)
                                        .font(.caption)
                                        .foregroundColor(UIColors.secondaryLabel)
                                }
                                
                                Spacer()
                                
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(UIColors.accentPrimary)
                                }
                            }
                            .padding()
                            .background(
                                selectedReason == reason ? MaterialDesignSystem.GlassColors.primary : Color.clear,
                                in: RoundedRectangle(cornerRadius: UICornerRadius.sm)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: UISpacing.sm) {
                    Text("Additional Context (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Provide more details about the issue...", text: $additionalContext, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                        )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Submit") {
                    onReport(contentId, contentType)
                    dismiss()
                }
                .fontWeight(.semibold)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ContentDetailView(
            contentItem: .review(Review(
                authorId: UUID(),
                profileScreenshots: ["https://example.com/screenshot1.jpg"],
                ratings: ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4),
                content: "Had a great conversation with this person. Their photos were accurate and the bio was interesting. Would definitely recommend matching if you see this profile! The conversation flowed naturally and they seemed genuinely interested in getting to know me.",
                tags: ["Green Flag", "Good Conversation", "Authentic"],
                datingApp: .tinder,
                upvotes: 15,
                downvotes: 2,
                commentCount: 8
            )),
            onVote: { _, _, _ in },
            onReport: { _, _ in }
        )
    }
}