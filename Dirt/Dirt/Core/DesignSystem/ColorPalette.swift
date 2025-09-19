import SwiftUI

/// Comprehensive color palette with semantic naming and accessibility support
struct ColorPalette {
    
    // MARK: - Brand Colors
    struct Brand {
        static let primary = Color("BrandPrimary", bundle: .main)
        static let secondary = Color("BrandSecondary", bundle: .main)
        static let accent = Color("BrandAccent", bundle: .main)
        
        // Fallback colors if assets are not available
        static let primaryFallback = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
        static let secondaryFallback = Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        static let accentFallback = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
    }
    
    // MARK: - Semantic Colors
    struct Semantic {
        // Status Colors
        static let success = Color.adaptiveSuccess
        static let warning = Color.adaptiveWarning
        static let error = Color.adaptiveError
        static let info = Color.adaptivePrimary
        
        // Interactive Colors
        static let link = Color.adaptivePrimary
        static let linkVisited = Color(red: 0.5, green: 0.0, blue: 0.5)
        static let focus = Color.adaptivePrimary
        static let selection = Color.adaptivePrimary.opacity(0.2)
        
        // Content Colors
        static let textPrimary = DesignTokens.Colors.textPrimary
        static let textSecondary = DesignTokens.Colors.textSecondary
        static let textTertiary = DesignTokens.Colors.textTertiary
        static let textQuaternary = DesignTokens.Colors.textQuaternary
        static let textInverse = Color.white
        static let textPlaceholder = DesignTokens.Colors.textTertiary
        
        // Background Colors
        static let backgroundPrimary = DesignTokens.Colors.background
        static let backgroundSecondary = DesignTokens.Colors.secondaryBackground
        static let backgroundTertiary = DesignTokens.Colors.tertiaryBackground
        static let backgroundInverse = Color.black
        
        // Surface Colors
        static let surface = DesignTokens.Colors.surface
        static let surfaceElevated = DesignTokens.Colors.surfaceElevated
        static let surfacePressed = Color.adaptivePrimary.opacity(0.1)
        static let surfaceHover = Color.adaptivePrimary.opacity(0.05)
        
        // Border Colors
        static let border = DesignTokens.Colors.border
        static let borderSecondary = DesignTokens.Colors.borderSecondary
        static let borderFocus = Color.adaptivePrimary
        static let borderError = Color.adaptiveError
        static let borderSuccess = Color.adaptiveSuccess
    }
    
    // MARK: - Neutral Grays
    struct Neutral {
        static let gray50 = Color(red: 0.98, green: 0.98, blue: 0.98)   // #FAFAFA
        static let gray100 = Color(red: 0.96, green: 0.96, blue: 0.96)  // #F5F5F5
        static let gray200 = Color(red: 0.93, green: 0.93, blue: 0.93)  // #EEEEEE
        static let gray300 = Color(red: 0.88, green: 0.88, blue: 0.88)  // #E0E0E0
        static let gray400 = Color(red: 0.74, green: 0.74, blue: 0.74)  // #BDBDBD
        static let gray500 = Color(red: 0.62, green: 0.62, blue: 0.62)  // #9E9E9E
        static let gray600 = Color(red: 0.46, green: 0.46, blue: 0.46)  // #757575
        static let gray700 = Color(red: 0.38, green: 0.38, blue: 0.38)  // #616161
        static let gray800 = Color(red: 0.26, green: 0.26, blue: 0.26)  // #424242
        static let gray900 = Color(red: 0.13, green: 0.13, blue: 0.13)  // #212121
        
        // Dynamic grays that adapt to light/dark mode
        static let adaptiveGray50 = Color.dynamicColor(light: gray50, dark: gray900)
        static let adaptiveGray100 = Color.dynamicColor(light: gray100, dark: gray800)
        static let adaptiveGray200 = Color.dynamicColor(light: gray200, dark: gray700)
        static let adaptiveGray300 = Color.dynamicColor(light: gray300, dark: gray600)
        static let adaptiveGray400 = Color.dynamicColor(light: gray400, dark: gray500)
        static let adaptiveGray500 = Color.dynamicColor(light: gray500, dark: gray400)
        static let adaptiveGray600 = Color.dynamicColor(light: gray600, dark: gray300)
        static let adaptiveGray700 = Color.dynamicColor(light: gray700, dark: gray200)
        static let adaptiveGray800 = Color.dynamicColor(light: gray800, dark: gray100)
        static let adaptiveGray900 = Color.dynamicColor(light: gray900, dark: gray50)
    }
    
    // MARK: - Extended Color Palette
    struct Extended {
        // Blues
        static let blue50 = Color(red: 0.94, green: 0.97, blue: 1.0)    // #EFF6FF
        static let blue500 = Color(red: 0.24, green: 0.58, blue: 0.98)  // #3B82F6
        static let blue900 = Color(red: 0.12, green: 0.24, blue: 0.44)  // #1E3A8A
        
        // Greens
        static let green50 = Color(red: 0.94, green: 0.99, blue: 0.95)  // #F0FDF4
        static let green500 = Color(red: 0.13, green: 0.80, blue: 0.33) // #22C55E
        static let green900 = Color(red: 0.05, green: 0.27, blue: 0.11) // #14532D
        
        // Reds
        static let red50 = Color(red: 1.0, green: 0.95, blue: 0.95)     // #FEF2F2
        static let red500 = Color(red: 0.94, green: 0.27, blue: 0.27)   // #EF4444
        static let red900 = Color(red: 0.45, green: 0.05, blue: 0.05)   // #7F1D1D
        
        // Oranges
        static let orange50 = Color(red: 1.0, green: 0.97, blue: 0.93)  // #FFF7ED
        static let orange500 = Color(red: 0.98, green: 0.55, blue: 0.13) // #F97316
        static let orange900 = Color(red: 0.43, green: 0.18, blue: 0.02) // #6C2E05
        
        // Purples
        static let purple50 = Color(red: 0.98, green: 0.95, blue: 1.0)  // #FAF5FF
        static let purple500 = Color(red: 0.66, green: 0.32, blue: 0.88) // #A855F7
        static let purple900 = Color(red: 0.23, green: 0.08, blue: 0.35) // #3B0764
    }
    
    // MARK: - Category Colors (for post categorization)
    struct Category {
        static let dating = Extended.red500
        static let relationship = Extended.purple500
        static let lifestyle = Extended.blue500
        static let career = Extended.orange500
        static let health = Extended.green500
        static let social = Color.adaptivePrimary
        
        static func color(for category: String) -> Color {
            switch category.lowercased() {
            case "dating":
                return dating
            case "relationship":
                return relationship
            case "lifestyle":
                return lifestyle
            case "career":
                return career
            case "health":
                return health
            case "social":
                return social
            default:
                return Neutral.adaptiveGray500
            }
        }
    }
    
    // MARK: - Sentiment Colors
    struct Sentiment {
        static let positive = Extended.green500
        static let negative = Extended.red500
        static let neutral = Neutral.adaptiveGray500
        
        static func color(for sentiment: String) -> Color {
            switch sentiment.lowercased() {
            case "positive", "good", "great", "excellent":
                return positive
            case "negative", "bad", "poor", "terrible":
                return negative
            default:
                return neutral
            }
        }
    }
}

// MARK: - Convenience Properties
extension ColorPalette {
    // Primary colors
    static let primary = Brand.primaryFallback
    static let secondary = Brand.secondaryFallback
    static let accent = Brand.accentFallback
    
    // Semantic colors
    static let success = Semantic.success
    static let warning = Semantic.warning
    static let error = Semantic.error
    static let info = Semantic.info
    
    // Text colors
    static let textPrimary = Semantic.textPrimary
    static let textSecondary = Semantic.textSecondary
    static let textTertiary = Semantic.textTertiary
    static let textQuaternary = Semantic.textQuaternary
    
    // Background colors
    static let backgroundPrimary = Semantic.backgroundPrimary
    static let backgroundSecondary = Semantic.backgroundSecondary
    static let backgroundTertiary = Semantic.backgroundTertiary
    
    // Surface colors
    static let surfacePrimary = Semantic.surface
    static let surfaceSecondary = Semantic.surfaceElevated
    
    // Border colors
    static let border = Semantic.border
    static let borderSecondary = Semantic.borderSecondary
}

// MARK: - Color Accessibility Utilities
extension ColorPalette {
    
    /// Check if a color combination meets WCAG contrast requirements
    static func meetsContrastRequirements(
        foreground: Color,
        background: Color,
        level: ContrastLevel = .AA
    ) -> Bool {
        // This is a simplified implementation
        // In a real app, you'd use a proper contrast calculation library
        return true // Placeholder
    }
    
    enum ContrastLevel {
        case AA      // 4.5:1 for normal text, 3:1 for large text
        case AAA     // 7:1 for normal text, 4.5:1 for large text
        
        var normalTextRatio: Double {
            switch self {
            case .AA: return 4.5
            case .AAA: return 7.0
            }
        }
        
        var largeTextRatio: Double {
            switch self {
            case .AA: return 3.0
            case .AAA: return 4.5
            }
        }
    }
}

// MARK: - Color Showcase View
struct ColorShowcase: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                // Brand Colors
                colorSection(
                    title: "Brand Colors",
                    colors: [
                        ("Primary", ColorPalette.Brand.primaryFallback),
                        ("Secondary", ColorPalette.Brand.secondaryFallback),
                        ("Accent", ColorPalette.Brand.accentFallback)
                    ]
                )
                
                // Semantic Colors
                colorSection(
                    title: "Semantic Colors",
                    colors: [
                        ("Success", ColorPalette.Semantic.success),
                        ("Warning", ColorPalette.Semantic.warning),
                        ("Error", ColorPalette.Semantic.error),
                        ("Info", ColorPalette.Semantic.info),
                        ("Link", ColorPalette.Semantic.link)
                    ]
                )
                
                // Neutral Grays
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Neutral Grays", style: .title2, weight: .bold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DesignTokens.Spacing.sm) {
                        colorCard("50", ColorPalette.Neutral.gray50)
                        colorCard("100", ColorPalette.Neutral.gray100)
                        colorCard("200", ColorPalette.Neutral.gray200)
                        colorCard("300", ColorPalette.Neutral.gray300)
                        colorCard("400", ColorPalette.Neutral.gray400)
                        colorCard("500", ColorPalette.Neutral.gray500)
                        colorCard("600", ColorPalette.Neutral.gray600)
                        colorCard("700", ColorPalette.Neutral.gray700)
                        colorCard("800", ColorPalette.Neutral.gray800)
                        colorCard("900", ColorPalette.Neutral.gray900)
                    }
                }
                
                // Category Colors
                colorSection(
                    title: "Category Colors",
                    colors: [
                        ("Dating", ColorPalette.Category.dating),
                        ("Relationship", ColorPalette.Category.relationship),
                        ("Lifestyle", ColorPalette.Category.lifestyle),
                        ("Career", ColorPalette.Category.career),
                        ("Health", ColorPalette.Category.health),
                        ("Social", ColorPalette.Category.social)
                    ]
                )
                
                // Sentiment Colors
                colorSection(
                    title: "Sentiment Colors",
                    colors: [
                        ("Positive", ColorPalette.Sentiment.positive),
                        ("Negative", ColorPalette.Sentiment.negative),
                        ("Neutral", ColorPalette.Sentiment.neutral)
                    ]
                )
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(ColorPalette.Semantic.backgroundPrimary)
    }
    
    private func colorSection(title: String, colors: [(String, Color)]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            TypographyText(title, style: .title2, weight: .bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                ForEach(colors, id: \.0) { name, color in
                    colorCard(name, color)
                }
            }
        }
    }
    
    private func colorCard(_ name: String, _ color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                        .stroke(ColorPalette.Semantic.border, lineWidth: 1)
                )
            
            TypographyText(name, style: .caption1, semanticStyle: .secondary)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    /// Create a color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get hex string representation of color
    var hexString: String {
        // This is a simplified implementation
        // In a real app, you'd properly extract RGB values
        return "#000000"
    }
    
    /// Lighten color by percentage
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 - percentage)
    }
    
    /// Darken color by percentage
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.opacity(1.0 + percentage)
    }
}

// MARK: - Preview
#Preview("Color Palette") {
    ColorShowcase()
}