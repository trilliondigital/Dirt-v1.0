import SwiftUI

struct PostCard: View {
    let post: Post
    @State private var isLiked: Bool = false
    @State private var isDisliked: Bool = false
    @State private var isSaved: Bool = false
    @State private var showingActions: Bool = false
    @State private var showingPostDetail: Bool = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Header with user info and metadata
                PostCardHeader(post: post)
                
                // Category and sentiment badges
                PostCardBadges(post: post)
                
                // Content
                PostCardContent(post: post)
                
                // Media if present
                if post.hasMedia {
                    PostCardMedia(mediaURLs: post.mediaURLs)
                }
                
                // Engagement bar
                PostCardEngagementBar(
                    post: post,
                    isLiked: $isLiked,
                    isDisliked: $isDisliked,
                    isSaved: $isSaved
                )
            }
            .padding(DesignTokens.Spacing.md)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.cardTap()
            showingPostDetail = true
        }
        .sheet(isPresented: $showingPostDetail) {
            PostDetailView(post: post)
        }
    }
}

// MARK: - Header Component
struct PostCardHeader: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // User avatar
            UserAvatar(size: .medium)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("Anonymous User")
                    .font(TypographyStyles.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Text(post.timeAgo)
                    .font(TypographyStyles.caption1)
                    .foregroundColor(ColorPalette.textSecondary)
            }
            
            Spacer()
            
            // More actions button
            Button(action: {
                HapticFeedback.buttonTap()
                // Show more actions
            }) {
                Image(systemName: "ellipsis")
                    .font(TypographyStyles.callout)
                    .foregroundColor(ColorPalette.text.secondary)
                    .frame(width: 24, height: 24)
            }
        }
    }
}

// MARK: - Badges Component
struct PostCardBadges: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Category badge
            CategoryBadge(category: post.category)
            
            // Sentiment badge
            SentimentBadge(sentiment: post.sentiment)
            
            Spacer()
        }
    }
}

// MARK: - Content Component
struct PostCardContent: View {
    let post: Post
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Title
            Text(post.title)
                .font(TypographyStyles.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
                .lineLimit(2)
            
            // Content
            Text(post.content)
                .font(TypographyStyles.body)
                .foregroundColor(ColorPalette.text.primary)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: AnimationPreferences.standardDuration), value: isExpanded)
            
            // Show more/less button if content is long
            if post.content.count > 150 {
                Button(action: {
                    HapticFeedback.buttonTap()
                    withAnimation(.easeInOut(duration: AnimationPreferences.standardDuration)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(TypographyStyles.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(ColorPalette.accent.primary)
                }
            }
        }
    }
}

// MARK: - Media Component
struct PostCardMedia: View {
    let mediaURLs: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(mediaURLs, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(ColorPalette.surfaceSecondary)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(ColorPalette.textTertiary)
                            }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
        }
    }
}

// MARK: - Engagement Bar Component
struct PostCardEngagementBar: View {
    let post: Post
    @Binding var isLiked: Bool
    @Binding var isDisliked: Bool
    @Binding var isSaved: Bool
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Upvote button
            EngagementButton(
                icon: "arrow.up",
                count: post.upvotes,
                isActive: isLiked,
                activeColor: ColorPalette.success
            ) {
                HapticFeedback.likeAction()
                withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                    isLiked.toggle()
                    if isLiked && isDisliked {
                        isDisliked = false
                    }
                }
            }
            
            // Downvote button
            EngagementButton(
                icon: "arrow.down",
                count: post.downvotes,
                isActive: isDisliked,
                activeColor: ColorPalette.error
            ) {
                HapticFeedback.likeAction()
                withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                    isDisliked.toggle()
                    if isDisliked && isLiked {
                        isLiked = false
                    }
                }
            }
            
            // Comment button
            EngagementButton(
                icon: "bubble.left",
                count: post.commentCount,
                isActive: false,
                activeColor: ColorPalette.accent
            ) {
                HapticFeedback.buttonTap()
                // Handle comment navigation
            }
            
            Spacer()
            
            // Save button
            Button(action: {
                HapticFeedback.saveAction()
                withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                    isSaved.toggle()
                }
            }) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(TypographyStyles.callout)
                    .foregroundColor(isSaved ? ColorPalette.accent.primary : ColorPalette.text.secondary)
            }
            
            // Share button
            Button(action: {
                HapticFeedback.buttonTap()
                // Share post
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(TypographyStyles.callout)
                    .foregroundColor(ColorPalette.text.secondary)
            }
        }
    }
}

// MARK: - Supporting Components

struct UserAvatar: View {
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 48
            }
        }
    }
    
    let size: Size
    
    var body: some View {
        Circle()
            .fill(ColorPalette.surface.secondary)
            .frame(width: size.dimension, height: size.dimension)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size.dimension * 0.5))
                    .foregroundColor(ColorPalette.textTertiary)
            }
    }
}



// MARK: - Preview
#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        PostCard(post: Post(
            authorId: UUID(),
            title: "Great first date experience!",
            content: "Had an amazing first date last night. We went to this cozy coffee shop and talked for hours. The conversation flowed naturally and we had so much in common. Looking forward to seeing them again!",
            category: .success,
            sentiment: .positive,
            upvotes: 24,
            downvotes: 3,
            commentCount: 12
        ))
        
        PostCard(post: Post(
            authorId: UUID(),
            title: "Red flag or am I overthinking?",
            content: "They showed up 30 minutes late without any explanation and spent most of the time on their phone. Should I give them another chance?",
            category: .question,
            sentiment: .negative,
            upvotes: 8,
            downvotes: 2,
            commentCount: 15
        ))
    }
    .padding()
    .background(ColorPalette.backgroundPrimary)
}