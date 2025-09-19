import SwiftUI

/// A card component for displaying dating profile reviews with ratings and engagement metrics
struct ReviewCardView: View {
    let review: Review
    let currentUserVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    let onComment: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: UISpacing.md) {
                // Header with app and timestamp
                headerSection
                
                // Screenshots section
                if !review.profileScreenshots.isEmpty {
                    screenshotsSection
                }
                
                // Ratings display
                ratingsSection
                
                // Review content
                contentSection
                
                // Tags
                if !review.tags.isEmpty {
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
            // Dating app badge
            HStack(spacing: UISpacing.xs) {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(UIColors.accentPrimary)
                    .font(.caption)
                
                Text(review.datingApp.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            .padding(.horizontal, UISpacing.xs)
            .padding(.vertical, 4)
            .background(MaterialDesignSystem.GlassColors.primary, in: Capsule())
            
            Spacer()
            
            // Timestamp
            Text(timeAgoString(from: review.createdAt))
                .font(.caption)
                .foregroundColor(UIColors.secondaryLabel)
        }
    }
    
    // MARK: - Screenshots Section
    
    private var screenshotsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UISpacing.xs) {
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
                    .frame(width: 120, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: UICornerRadius.sm))
                    .overlay(
                        RoundedRectangle(cornerRadius: UICornerRadius.sm)
                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 1) // Prevent clipping of borders
        }
    }
    
    // MARK: - Ratings Section
    
    private var ratingsSection: some View {
        VStack(spacing: UISpacing.xs) {
            // Overall rating
            HStack {
                Text("Overall Rating")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                StarRatingView(rating: review.ratings.overall, maxRating: 5)
                
                Text("\(review.ratings.overall)/5")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(UIColors.accentPrimary)
            }
            
            // Detailed ratings
            VStack(spacing: 6) {
                RatingRowView(label: "Photos", rating: review.ratings.photos)
                RatingRowView(label: "Bio", rating: review.ratings.bio)
                RatingRowView(label: "Conversation", rating: review.ratings.conversation)
            }
            .padding(UISpacing.sm)
            .background(MaterialDesignSystem.GlassColors.neutral, in: RoundedRectangle(cornerRadius: UICornerRadius.sm))
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        Text(review.content)
            .font(.body)
            .foregroundColor(UIColors.label)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UISpacing.xs) {
                ForEach(review.tags, id: \.self) { tag in
                    TagView(text: tag, style: tagStyle(for: tag))
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
                upvotes: review.upvotes,
                downvotes: review.downvotes,
                currentVote: currentUserVote,
                onUpvote: onUpvote,
                onDownvote: onDownvote
            )
            
            Spacer()
            
            // Comment button
            Button(action: onComment) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption)
                    
                    Text("\(review.commentCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(UIColors.secondaryLabel)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    
    private func tagStyle(for tag: String) -> TagView.Style {
        if let reviewTag = ReviewTag.allCases.first(where: { $0.rawValue == tag }) {
            return reviewTag.isPositive ? .positive : .negative
        }
        return .neutral
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

/// A view for displaying individual rating rows
private struct RatingRowView: View {
    let label: String
    let rating: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(UIColors.secondaryLabel)
            
            Spacer()
            
            StarRatingView(rating: rating, maxRating: 5, size: .small)
        }
    }
}

/// A star rating display view
struct StarRatingView: View {
    let rating: Int
    let maxRating: Int
    let size: Size
    
    enum Size {
        case small, medium, large
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    init(rating: Int, maxRating: Int, size: Size = .medium) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : UIColors.secondaryLabel)
                    .font(size.fontSize)
            }
        }
    }
}

/// A tag view with different styles
struct TagView: View {
    let text: String
    let style: Style
    
    enum Style {
        case positive, negative, neutral
        
        var backgroundColor: Color {
            switch self {
            case .positive: return MaterialDesignSystem.GlassColors.success
            case .negative: return MaterialDesignSystem.GlassColors.danger
            case .neutral: return MaterialDesignSystem.GlassColors.neutral
            }
        }
        
        var borderColor: Color {
            switch self {
            case .positive: return Color.green.opacity(0.3)
            case .negative: return Color.red.opacity(0.3)
            case .neutral: return MaterialDesignSystem.GlassBorders.subtle
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(UIColors.label)
            .padding(.horizontal, UISpacing.xs)
            .padding(.vertical, 4)
            .background(style.backgroundColor, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(style.borderColor, lineWidth: 1)
            )
    }
}

/// Vote buttons component with upvote/downvote functionality
struct VoteButtonsView: View {
    let upvotes: Int
    let downvotes: Int
    let currentVote: VoteType
    let onUpvote: () -> Void
    let onDownvote: () -> Void
    
    var netScore: Int {
        upvotes - downvotes
    }
    
    var body: some View {
        HStack(spacing: UISpacing.sm) {
            // Upvote button
            Button(action: onUpvote) {
                HStack(spacing: 4) {
                    Image(systemName: currentVote == .upvote ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .foregroundColor(currentVote == .upvote ? UIColors.accentPrimary : UIColors.secondaryLabel)
                    
                    Text("\(upvotes)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(currentVote == .upvote ? UIColors.accentPrimary : UIColors.secondaryLabel)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Net score
            Text("\(netScore >= 0 ? "+" : "")\(netScore)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(netScore >= 0 ? UIColors.success : UIColors.danger)
            
            // Downvote button
            Button(action: onDownvote) {
                HStack(spacing: 4) {
                    Image(systemName: currentVote == .downvote ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundColor(currentVote == .downvote ? UIColors.danger : UIColors.secondaryLabel)
                    
                    Text("\(downvotes)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(currentVote == .downvote ? UIColors.danger : UIColors.secondaryLabel)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: UISpacing.md) {
            ReviewCardView(
                review: Review(
                    authorId: UUID(),
                    profileScreenshots: ["https://example.com/screenshot1.jpg"],
                    ratings: ReviewRatings(photos: 4, bio: 3, conversation: 5, overall: 4),
                    content: "Had a great conversation with this person. Their photos were accurate and the bio was interesting. Would definitely recommend matching if you see this profile!",
                    tags: ["Green Flag", "Good Conversation", "Authentic"],
                    datingApp: .tinder,
                    upvotes: 15,
                    downvotes: 2,
                    commentCount: 8
                ),
                currentUserVote: .none,
                onUpvote: {},
                onDownvote: {},
                onComment: {},
                onTap: {}
            )
            
            ReviewCardView(
                review: Review(
                    authorId: UUID(),
                    profileScreenshots: ["https://example.com/screenshot2.jpg"],
                    ratings: ReviewRatings(photos: 2, bio: 1, conversation: 1, overall: 1),
                    content: "Complete catfish situation. Photos were heavily filtered and the conversation was terrible. Avoid at all costs.",
                    tags: ["Red Flag", "Catfish", "Poor Conversation"],
                    datingApp: .bumble,
                    upvotes: 3,
                    downvotes: 1,
                    commentCount: 12
                ),
                currentUserVote: .upvote,
                onUpvote: {},
                onDownvote: {},
                onComment: {},
                onTap: {}
            )
        }
        .padding()
    }
    .background(UIColors.groupedBackground)
}