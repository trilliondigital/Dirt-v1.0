import SwiftUI

/// Core design tokens that define the visual foundation of the app
struct DesignTokens {
    
    // MARK: - Spacing System
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Typography Scale
    struct Typography {
        // Large Title: 34pt, Bold - Main screen titles
        static let largeTitle = Font.largeTitle.weight(.bold)
        
        // Title 1: 28pt, Bold - Section headers
        static let title1 = Font.title.weight(.bold)
        
        // Title 2: 22pt, Bold - Card titles, important labels
        static let title2 = Font.title2.weight(.bold)
        
        // Title 3: 20pt, Semibold - Subsection headers
        static let title3 = Font.title3.weight(.semibold)
        
        // Headline: 17pt, Semibold - Post titles, button labels
        static let headline = Font.headline.weight(.semibold)
        
        // Body: 17pt, Regular - Main content text
        static let body = Font.body
        
        // Callout: 16pt, Regular - Secondary content
        static let callout = Font.callout
        
        // Subheadline: 15pt, Regular - Metadata, timestamps
        static let subheadline = Font.subheadline
        
        // Footnote: 13pt, Regular - Fine print, disclaimers
        static let footnote = Font.footnote
        
        // Caption 1: 12pt, Regular - Image captions, small labels
        static let caption = Font.caption
        
        // Caption 2: 11pt, Regular - Smallest text elements
        static let caption2 = Font.caption2
    }
    
    // MARK: - Color Tokens
    struct Colors {
        // Primary Colors
        static let primary = Color.accentColor
        static let primaryLight = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
        static let primaryDark = Color(red: 0.04, green: 0.52, blue: 1.0) // #0A84FF
        
        // Secondary Colors
        static let secondary = Color.secondary
        static let secondaryLight = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        static let secondaryDark = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        
        // Semantic Colors
        static let success = Color.green
        static let successLight = Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
        static let successDark = Color(red: 0.19, green: 0.82, blue: 0.35) // #30D158
        
        static let warning = Color.orange
        static let warningLight = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
        static let warningDark = Color(red: 1.0, green: 0.62, blue: 0.04) // #FF9F0A
        
        static let error = Color.red
        static let errorLight = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
        static let errorDark = Color(red: 1.0, green: 0.27, blue: 0.23) // #FF453A
        
        // Background Colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        
        // Surface Colors (for cards and elevated content)
        static let surface = Color(UIColor.secondarySystemBackground)
        static let surfaceElevated = Color(UIColor.tertiarySystemBackground)
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(UIColor.tertiaryLabel)
        static let textQuaternary = Color(UIColor.quaternaryLabel)
        
        // Border Colors
        static let border = Color(UIColor.separator)
        static let borderSecondary = Color(UIColor.opaqueSeparator)
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 50 // For circular elements
    }
    
    // MARK: - Shadow Tokens
    struct Shadow {
        static let small = (
            color: Color.black.opacity(0.1),
            radius: CGFloat(2),
            x: CGFloat(0),
            y: CGFloat(1)
        )
        
        static let medium = (
            color: Color.black.opacity(0.15),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        
        static let large = (
            color: Color.black.opacity(0.2),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let springResponse: Double = 0.6
        static let springDamping: Double = 0.8
    }
}

// MARK: - Convenience Extensions
extension View {
    /// Apply standard spacing using design tokens
    func spacing(_ token: CGFloat) -> some View {
        self.padding(token)
    }
    
    /// Apply corner radius using design tokens
    func cornerRadius(_ token: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: token))
    }
}