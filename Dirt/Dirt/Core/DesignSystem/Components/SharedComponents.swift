import SwiftUI

// MARK: - Category Badge
struct CategoryBadge: View {
    let category: PostCategory
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing.xs) {
            Image(systemName: category.iconName)
                .font(.caption2)
            
            Text(category.displayName)
                .font(TypographyStyles.caption1)
        }
        .foregroundColor(ColorPalette.primary)
        .padding(.horizontal, DesignTokens.spacing.sm)
        .padding(.vertical, DesignTokens.spacing.xs)
        .background(
            Capsule()
                .fill(ColorPalette.primary.opacity(0.1))
        )
    }
}

// MARK: - Sentiment Badge
struct SentimentBadge: View {
    let sentiment: PostSentiment
    
    private var sentimentColor: Color {
        switch sentiment {
        case .positive: return ColorPalette.success
        case .negative: return ColorPalette.error
        case .neutral: return ColorPalette.textSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing.xs) {
            Image(systemName: sentiment.iconName)
                .font(.caption2)
            
            Text(sentiment.displayName)
                .font(TypographyStyles.caption1)
        }
        .foregroundColor(sentimentColor)
        .padding(.horizontal, DesignTokens.spacing.sm)
        .padding(.vertical, DesignTokens.spacing.xs)
        .background(
            Capsule()
                .fill(sentimentColor.opacity(0.1))
        )
    }
}

// MARK: - Engagement Button
struct EngagementButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color
    let onTap: () -> Void
    
    init(
        icon: String,
        count: Int = 0,
        isActive: Bool = false,
        activeColor: Color = ColorPalette.primary,
        inactiveColor: Color = ColorPalette.textSecondary,
        onTap: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.count = count
        self.isActive = isActive
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.spacing.xs) {
                Image(systemName: icon)
                    .font(TypographyStyles.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyStyles.caption1)
                }
            }
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .animation(.easeInOut(duration: 0.15), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryBadge(category: .advice)
        SentimentBadge(sentiment: .positive)
        
        HStack {
            EngagementButton(icon: "arrow.up", count: 24, isActive: true, activeColor: ColorPalette.success) {}
            EngagementButton(icon: "arrow.down", count: 3) {}
            EngagementButton(icon: "bubble.left", count: 12) {}
            EngagementButton(icon: "bookmark", isActive: true) {}
        }
    }
    .padding()
}