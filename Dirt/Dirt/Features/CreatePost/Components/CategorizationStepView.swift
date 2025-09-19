import SwiftUI

struct CategorizationStepView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing.xl) {
                // Category Selection
                CategorySelectionView(
                    selectedCategory: $viewModel.selectedCategory
                )
                
                // Sentiment Selection
                SentimentSelectionView(
                    selectedSentiment: $viewModel.selectedSentiment
                )
                
                // Tag Suggestions
                TagSuggestionsView(
                    selectedTags: $viewModel.selectedTags,
                    suggestedTags: viewModel.suggestedTags,
                    onAddTag: viewModel.addTag,
                    onRemoveTag: viewModel.removeTag
                )
                
                // Preview Section
                PostCategorizationPreview(
                    category: viewModel.selectedCategory,
                    sentiment: viewModel.selectedSentiment,
                    tags: Array(viewModel.selectedTags)
                )
            }
            .padding(DesignTokens.spacing.md)
        }
        .onAppear {
            viewModel.validateCurrentStep()
        }
    }
}

struct CategorySelectionView: View {
    @Binding var selectedCategory: PostCategory
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            Text("Choose a Category")
                .font(TypographyStyles.title3)
                .foregroundColor(ColorPalette.textPrimary)
            
            Text("Help others find your post by selecting the most relevant category")
                .font(TypographyStyles.subheadline)
                .foregroundColor(ColorPalette.textSecondary)
            
            LazyVGrid(columns: columns, spacing: DesignTokens.spacing.md) {
                ForEach(PostCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: PostCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.spacing.sm) {
                // Icon
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : ColorPalette.primary)
                
                // Title
                Text(category.displayName)
                    .font(TypographyStyles.headline)
                    .foregroundColor(isSelected ? .white : ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(category.description)
                    .font(TypographyStyles.caption1)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(DesignTokens.spacing.md)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                    .fill(isSelected ? ColorPalette.primary : ColorPalette.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                            .stroke(
                                isSelected ? ColorPalette.primary : ColorPalette.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct SentimentSelectionView: View {
    @Binding var selectedSentiment: PostSentiment
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            Text("What's the Sentiment?")
                .font(TypographyStyles.title3)
                .foregroundColor(ColorPalette.textPrimary)
            
            Text("Help others understand the nature of your experience")
                .font(TypographyStyles.subheadline)
                .foregroundColor(ColorPalette.textSecondary)
            
            HStack(spacing: DesignTokens.spacing.md) {
                ForEach(PostSentiment.allCases, id: \.self) { sentiment in
                    SentimentCard(
                        sentiment: sentiment,
                        isSelected: selectedSentiment == sentiment,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSentiment = sentiment
                            }
                        }
                    )
                }
            }
        }
    }
}

struct SentimentCard: View {
    let sentiment: PostSentiment
    let isSelected: Bool
    let onTap: () -> Void
    
    private var sentimentColor: Color {
        switch sentiment {
        case .positive:
            return ColorPalette.success
        case .negative:
            return ColorPalette.error
        case .neutral:
            return ColorPalette.textSecondary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.spacing.sm) {
                Image(systemName: sentiment.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : sentimentColor)
                
                Text(sentiment.displayName)
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(isSelected ? .white : ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignTokens.spacing.md)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                    .fill(isSelected ? sentimentColor : ColorPalette.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                            .stroke(
                                isSelected ? sentimentColor : ColorPalette.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct TagSuggestionsView: View {
    @Binding var selectedTags: Set<String>
    let suggestedTags: [String]
    let onAddTag: (String) -> Void
    let onRemoveTag: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            Text("Add Tags (Optional)")
                .font(TypographyStyles.title3)
                .foregroundColor(ColorPalette.textPrimary)
            
            Text("Tags help others find your post. Select up to 5 relevant tags.")
                .font(TypographyStyles.subheadline)
                .foregroundColor(ColorPalette.textSecondary)
            
            // Selected Tags
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    Text("Selected Tags")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    FlowLayout(spacing: DesignTokens.spacing.sm) {
                        ForEach(Array(selectedTags).sorted(), id: \.self) { tag in
                            TagChip(
                                text: tag,
                                style: .selected,
                                onTap: { onRemoveTag(tag) }
                            )
                        }
                    }
                }
            }
            
            // Suggested Tags
            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    Text("Suggested Tags")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    FlowLayout(spacing: DesignTokens.spacing.sm) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                style: .suggested,
                                onTap: { onAddTag(tag) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let style: TagChipStyle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.spacing.xs) {
                Text("#\(text)")
                    .font(TypographyStyles.caption1)
                    .foregroundColor(style.textColor)
                
                if style == .selected {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(style.textColor)
                }
            }
            .padding(.horizontal, DesignTokens.spacing.sm)
            .padding(.vertical, DesignTokens.spacing.xs)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
                    .overlay(
                        Capsule()
                            .stroke(style.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum TagChipStyle {
    case selected
    case suggested
    
    var backgroundColor: Color {
        switch self {
        case .selected:
            return ColorPalette.primary.opacity(0.1)
        case .suggested:
            return ColorPalette.surfaceSecondary
        }
    }
    
    var textColor: Color {
        switch self {
        case .selected:
            return ColorPalette.primary
        case .suggested:
            return ColorPalette.textSecondary
        }
    }
    
    var borderColor: Color {
        switch self {
        case .selected:
            return ColorPalette.primary
        case .suggested:
            return ColorPalette.border
        }
    }
}

struct PostCategorizationPreview: View {
    let category: PostCategory
    let sentiment: PostSentiment
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            Text("Preview in Feed")
                .font(TypographyStyles.title3)
                .foregroundColor(ColorPalette.textPrimary)
            
            VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                // Category and Sentiment Badges
                HStack(spacing: DesignTokens.spacing.sm) {
                    CategoryBadge(category: category)
                    SentimentBadge(sentiment: sentiment)
                    Spacer()
                }
                
                // Sample Title
                Text("Your Post Title")
                    .font(TypographyStyles.headline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                // Sample Content Preview
                Text("Your post content will appear here with proper formatting and styling...")
                    .font(TypographyStyles.body)
                    .foregroundColor(ColorPalette.textSecondary)
                    .lineLimit(2)
                
                // Tags
                if !tags.isEmpty {
                    FlowLayout(spacing: DesignTokens.spacing.xs) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
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
                        
                        if tags.count > 3 {
                            Text("+\(tags.count - 3)")
                                .font(TypographyStyles.caption2)
                                .foregroundColor(ColorPalette.textTertiary)
                        }
                    }
                }
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



// FlowLayout for tags
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
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                    y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

struct FlowResult {
    let bounds: CGSize
    let frames: [CGRect]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var frames: [CGRect] = []
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRowX + size.width > maxWidth && !frames.isEmpty {
                // Start new row
                currentRowY += currentRowHeight + spacing
                currentRowX = 0
                currentRowHeight = 0
            }
            
            frames.append(CGRect(x: currentRowX, y: currentRowY, width: size.width, height: size.height))
            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        self.frames = frames
        self.bounds = CGSize(width: maxWidth, height: currentRowY + currentRowHeight)
    }
}

#Preview {
    CategorizationStepView(viewModel: CreatePostViewModel())
}