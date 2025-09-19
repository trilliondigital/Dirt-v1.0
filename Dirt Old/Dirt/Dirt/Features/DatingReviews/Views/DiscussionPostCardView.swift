import SwiftUI

/// A card component for displaying discussion posts with engagement metrics
struct DiscussionPostCardView: View {
    let post: DatingReviewPost
    let currentUserVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onComment: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: UISpacing.md) {
                // Header with category and timestamp
                headerSection
                
                // Title and content
                contentSection
                
                // Tags
                if !post.tags.isEmpty {
                    tagsSection
                }
                
                // Engagement metrics and actions
                engagementSection
            }
            .padding(UISpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .glassCard()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Category badge
            HStack(spacing: UISpacing.xs) {
                Image(systemName: post.category.iconName)
                    .foregroundColor(categoryColor)
                    .font(.caption)
                
                Text(post.category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(categoryColor)
            }
            .padding(.horizontal, UISpacing.xs)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.1), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(categoryColor.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            // Timestamp
            Text(timeAgoString(from: post.createdAt))
                .font(.caption)
                .foregroundColor(UIColors.secondaryLabel)
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: UISpacing.xs) {
            // Title
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(UIColors.label)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Content preview
            Text(post.content)
                .font(.body)
                .foregroundColor(UIColors.secondaryLabel)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UISpacing.xs) {
                ForEach(post.tags, id: \.self) { tag in
                    PostTagView(text: tag)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Engagement Section
    
    private var engagementSection: some View {
        HStack {
            // Vote buttons
            VoteButtonsView(
                upvotes: post.upvotes,
                downvotes: post.downvotes,
                currentVote: currentUserVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote
            )
            
            Spacer()
            
            // Engagement metrics
            HStack(spacing: UISpacing.md) {
                // Comments
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    
                    Text("\(post.commentCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(UIColors.secondaryLabel)
                
                // Engagement score (if significant)
                if post.engagementScore > 10 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.caption)
                        
                        Text("Hot")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(UIColors.warning)
                }
            }
            
            // Comment button
            Button(action: onComment) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.caption)
                    .foregroundColor(UIColors.accentPrimary)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Helper Properties
    
    private var categoryColor: Color {
        switch post.category {
        case .advice:
            return .blue
        case .experience:
            return .purple
        case .question:
            return .orange
        case .strategy:
            return .green
        case .success:
            return .yellow
        case .rant:
            return .red
        case .general:
            return .gray
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

/// A tag view specifically for post tags
struct PostTagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(UIColors.label)
            .padding(.horizontal, UISpacing.xs)
            .padding(.vertical, 4)
            .background(MaterialDesignSystem.GlassColors.neutral, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
            )
    }
}

/// Compact discussion post card for list views
struct CompactDiscussionPostCardView: View {
    let post: DatingReviewPost
    let currentUserVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UISpacing.md) {
                // Vote section
                VStack(spacing: 4) {
                    Button(action: onUpvote) {
                        Image(systemName: currentUserVote == .upvote ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .foregroundColor(currentUserVote == .upvote ? UIColors.accentPrimary : UIColors.secondaryLabel)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(post.netScore)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(post.netScore >= 0 ? UIColors.success : UIColors.danger)
                    
                    Button(action: onDownvote) {
                        Image(systemName: currentUserVote == .downvote ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .foregroundColor(currentUserVote == .downvote ? UIColors.danger : UIColors.secondaryLabel)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(width: 44)
                
                // Content section
                VStack(alignment: .leading, spacing: UISpacing.xs) {
                    // Category and timestamp
                    HStack {
                        Text(post.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                        
                        Spacer()
                        
                        Text(timeAgoString(from: post.createdAt))
                            .font(.caption)
                            .foregroundColor(UIColors.secondaryLabel)
                    }
                    
                    // Title
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(UIColors.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Engagement info
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.caption2)
                            
                            Text("\(post.commentCount)")
                                .font(.caption2)
                        }
                        .foregroundColor(UIColors.secondaryLabel)
                        
                        if post.engagementScore > 10 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame")
                                    .font(.caption2)
                                
                                Text("Hot")
                                    .font(.caption2)
                            }
                            .foregroundColor(UIColors.warning)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(UISpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .background(MaterialDesignSystem.Glass.ultraThin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
        )
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
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: UISpacing.md) {
            DiscussionPostCardView(
                post: DatingReviewPost(
                    authorId: UUID(),
                    title: "How to improve your dating profile photos?",
                    content: "I've been struggling with getting matches on dating apps. I think my photos might be the issue. What are some tips for taking better photos that actually get results? I've tried different angles and lighting but nothing seems to work.",
                    category: .question,
                    tags: ["Photos", "Profile", "Dating 101"],
                    upvotes: 24,
                    downvotes: 3,
                    commentCount: 15
                ),
                currentUserVote: .none,
                onUpvote: {},
                onDownvote: {},
                onComment: {},
                onTap: {}
            )
            
            DiscussionPostCardView(
                post: DatingReviewPost(
                    authorId: UUID(),
                    title: "Success Story: Finally found someone genuine!",
                    content: "After months of disappointing dates and ghosting, I finally met someone who's actually interested in getting to know me. Here's what I learned along the way and what finally worked for me.",
                    category: .success,
                    tags: ["Success", "Long Term Potential", "Authentic"],
                    upvotes: 89,
                    downvotes: 5,
                    commentCount: 32
                ),
                currentUserVote: .upvote,
                onUpvote: {},
                onDownvote: {},
                onComment: {},
                onTap: {}
            )
            
            CompactDiscussionPostCardView(
                post: DatingReviewPost(
                    authorId: UUID(),
                    title: "Red flags to watch out for in conversations",
                    content: "Based on my experience, here are some conversation red flags that usually indicate the person isn't worth your time...",
                    category: .advice,
                    tags: ["Red Flags", "Communication"],
                    upvotes: 45,
                    downvotes: 8,
                    commentCount: 23
                ),
                currentUserVote: .none,
                onUpvote: {},
                onDownvote: {},
                onTap: {}
            )
        }
        .padding()
    }
    .background(UIColors.groupedBackground)
}