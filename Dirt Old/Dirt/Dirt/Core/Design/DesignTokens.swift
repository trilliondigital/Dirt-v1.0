import SwiftUI

// MARK: - Design Tokens (foundation for future glass UI)
struct UIColors {
    // Semantic colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let label = Color.primary
    static let secondaryLabel = Color.secondary

    // Accents
    static let accentPrimary = Color.blue
    static let accentSecondary = Color.purple
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
}

struct UISpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

struct UICornerRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

struct UIShadow {
    static let soft = Color.black.opacity(0.05)
}

// MARK: - Reusable Gradients
struct UIGradients {
    static let primary = LinearGradient(
        gradient: Gradient(colors: [UIColors.accentPrimary, UIColors.accentSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}