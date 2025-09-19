import SwiftUI

struct PreviewStepView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    Text("Preview Your Post")
                        .font(TypographyStyles.title2)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Text("This is how your post will appear in the community feed. Review everything before publishing.")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textSecondary)
                }
                
                // Post Preview
                PostPreviewCard(
                    title: viewModel.title,
                    content: viewModel.content,
                    category: viewModel.selectedCategory,
                    sentiment: viewModel.selectedSentiment,
                    tags: Array(viewModel.selectedTags),
                    images: viewModel.selectedImages
                )
                
                // Community Guidelines Check
                CommunityGuidelinesCheck(
                    title: viewModel.title,
                    content: viewModel.content,
                    validationErrors: viewModel.validationErrors
                )
                
                // Publishing Info
                PublishingInfoView()
            }
            .padding(DesignTokens.spacing.md)
        }
        .onAppear {
            viewModel.validateCurrentStep()
        }
    }
}

struct PostPreviewCard: View {
    let title: String
    let content: String
    let category: PostCategory
    let sentiment: PostSentiment
    let tags: [String]
    let images: [UIImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            // Header
            HStack {
                Text("Feed Preview")
                    .font(TypographyStyles.headline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Spacer()
                
                Text("Just now")
                    .font(TypographyStyles.caption1)
                    .foregroundColor(ColorPalette.textSecondary)
            }
            
            // Post Card Preview
            VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
                // User Info
                HStack(spacing: DesignTokens.spacing.sm) {
                    Circle()
                        .fill(ColorPalette.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("You")
                                .font(TypographyStyles.caption1)
                                .foregroundColor(ColorPalette.primary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anonymous User")
                            .font(TypographyStyles.subheadline)
                            .foregroundColor(ColorPalette.textPrimary)
                        
                        Text("Just now")
                            .font(TypographyStyles.caption2)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    .disabled(true)
                }
                
                // Category and Sentiment
                HStack(spacing: DesignTokens.spacing.sm) {
                    CategoryBadge(category: category)
                    SentimentBadge(sentiment: sentiment)
                    Spacer()
                }
                
                // Title
                Text(title.isEmpty ? "Your post title will appear here" : title)
                    .font(TypographyStyles.headline)
                    .foregroundColor(title.isEmpty ? ColorPalette.textTertiary : ColorPalette.textPrimary)
                
                // Content
                Text(content.isEmpty ? "Your post content will appear here with proper formatting..." : content)
                    .font(TypographyStyles.body)
                    .foregroundColor(content.isEmpty ? ColorPalette.textTertiary : ColorPalette.textSecondary)
                    .lineLimit(4)
                
                // Images
                if !images.isEmpty {
                    ImagePreviewGrid(images: images)
                }
                
                // Tags
                if !tags.isEmpty {
                    FlowLayout(spacing: DesignTokens.spacing.xs) {
                        ForEach(tags.prefix(5), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(TypographyStyles.caption2)
                                .foregroundColor(ColorPalette.primary)
                                .padding(.horizontal, DesignTokens.spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(ColorPalette.primary.opacity(0.1))
                                )
                        }
                    }
                }
                
                // Engagement Bar
                HStack(spacing: DesignTokens.spacing.lg) {
                    EngagementButton(icon: "arrow.up", count: 0, isActive: false)
                    EngagementButton(icon: "arrow.down", count: 0, isActive: false)
                    EngagementButton(icon: "bubble.left", count: 0, isActive: false)
                    EngagementButton(icon: "bookmark", count: 0, isActive: false)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    .disabled(true)
                }
                .padding(.top, DesignTokens.spacing.sm)
            }
            .padding(DesignTokens.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                    .fill(ColorPalette.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                            .stroke(ColorPalette.border, lineWidth: 1)
                    )
            )
        }
    }
}

struct ImagePreviewGrid: View {
    let images: [UIImage]
    
    var body: some View {
        switch images.count {
        case 1:
            SingleImageView(image: images[0])
        case 2:
            HStack(spacing: DesignTokens.spacing.xs) {
                ForEach(0..<2, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(DesignTokens.cornerRadius.sm)
                }
            }
        case 3:
            HStack(spacing: DesignTokens.spacing.xs) {
                Image(uiImage: images[0])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(DesignTokens.cornerRadius.sm)
                
                VStack(spacing: DesignTokens.spacing.xs) {
                    ForEach(1..<3, id: \.self) { index in
                        Image(uiImage: images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 58)
                            .clipped()
                            .cornerRadius(DesignTokens.cornerRadius.sm)
                    }
                }
            }
        case 4:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.spacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipped()
                        .cornerRadius(DesignTokens.cornerRadius.sm)
                }
            }
        default:
            EmptyView()
        }
    }
}

struct SingleImageView: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxHeight: 200)
            .clipped()
            .cornerRadius(DesignTokens.cornerRadius.md)
    }
}



struct CommunityGuidelinesCheck: View {
    let title: String
    let content: String
    let validationErrors: [ValidationError]
    
    private var hasIssues: Bool {
        !validationErrors.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            HStack {
                Image(systemName: hasIssues ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(hasIssues ? ColorPalette.warning : ColorPalette.success)
                
                Text("Community Guidelines")
                    .font(TypographyStyles.headline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Spacer()
                
                Text(hasIssues ? "Issues Found" : "All Good")
                    .font(TypographyStyles.caption1)
                    .foregroundColor(hasIssues ? ColorPalette.warning : ColorPalette.success)
                    .padding(.horizontal, DesignTokens.spacing.sm)
                    .padding(.vertical, DesignTokens.spacing.xs)
                    .background(
                        Capsule()
                            .fill((hasIssues ? ColorPalette.warning : ColorPalette.success).opacity(0.1))
                    )
            }
            
            if hasIssues {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    ForEach(validationErrors) { error in
                        HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(ColorPalette.error)
                                .font(.caption)
                            
                            Text(error.message)
                                .font(TypographyStyles.caption1)
                                .foregroundColor(ColorPalette.error)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.xs) {
                    ChecklistItem(text: "Content is appropriate and respectful")
                    ChecklistItem(text: "No personal identifying information")
                    ChecklistItem(text: "Follows community standards")
                }
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill((hasIssues ? ColorPalette.warning : ColorPalette.success).opacity(0.05))
        )
    }
}

struct ChecklistItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing.sm) {
            Image(systemName: "checkmark")
                .foregroundColor(ColorPalette.success)
                .font(.caption)
            
            Text(text)
                .font(TypographyStyles.caption1)
                .foregroundColor(ColorPalette.textSecondary)
        }
    }
}

struct PublishingInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            Text("Publishing Information")
                .font(TypographyStyles.headline)
                .foregroundColor(ColorPalette.textPrimary)
            
            VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                InfoRow(icon: "globe", title: "Visibility", description: "Your post will be visible to all community members")
                InfoRow(icon: "person.crop.circle.badge.questionmark", title: "Anonymous", description: "Your identity remains private")
                InfoRow(icon: "clock", title: "Timing", description: "Post will appear immediately after publishing")
                InfoRow(icon: "pencil", title: "Editing", description: "You can edit or delete your post after publishing")
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(ColorPalette.primary.opacity(0.05))
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(ColorPalette.primary)
                .font(.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Text(description)
                    .font(TypographyStyles.caption1)
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
    }
}

#Preview {
    PreviewStepView(viewModel: CreatePostViewModel())
}