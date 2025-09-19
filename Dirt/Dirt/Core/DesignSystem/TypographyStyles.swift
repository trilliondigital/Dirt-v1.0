import SwiftUI

/// Comprehensive typography system with semantic text styles and accessibility support
struct TypographyStyles {
    
    // MARK: - Text Style Definitions
    enum TextStyle: String, CaseIterable {
        case largeTitle = "largeTitle"
        case title1 = "title1"
        case title2 = "title2"
        case title3 = "title3"
        case headline = "headline"
        case body = "body"
        case callout = "callout"
        case subheadline = "subheadline"
        case footnote = "footnote"
        case caption1 = "caption1"
        case caption2 = "caption2"
        
        var font: Font {
            switch self {
            case .largeTitle:
                return DesignTokens.Typography.largeTitle
            case .title1:
                return DesignTokens.Typography.title1
            case .title2:
                return DesignTokens.Typography.title2
            case .title3:
                return DesignTokens.Typography.title3
            case .headline:
                return DesignTokens.Typography.headline
            case .body:
                return DesignTokens.Typography.body
            case .callout:
                return DesignTokens.Typography.callout
            case .subheadline:
                return DesignTokens.Typography.subheadline
            case .footnote:
                return DesignTokens.Typography.footnote
            case .caption1:
                return DesignTokens.Typography.caption
            case .caption2:
                return DesignTokens.Typography.caption2
            }
        }
        
        var displayName: String {
            switch self {
            case .largeTitle:
                return "Large Title"
            case .title1:
                return "Title 1"
            case .title2:
                return "Title 2"
            case .title3:
                return "Title 3"
            case .headline:
                return "Headline"
            case .body:
                return "Body"
            case .callout:
                return "Callout"
            case .subheadline:
                return "Subheadline"
            case .footnote:
                return "Footnote"
            case .caption1:
                return "Caption 1"
            case .caption2:
                return "Caption 2"
            }
        }
        
        var usage: String {
            switch self {
            case .largeTitle:
                return "Main screen titles, hero text"
            case .title1:
                return "Section headers, page titles"
            case .title2:
                return "Card titles, important labels"
            case .title3:
                return "Subsection headers"
            case .headline:
                return "Post titles, button labels"
            case .body:
                return "Main content text, paragraphs"
            case .callout:
                return "Secondary content, descriptions"
            case .subheadline:
                return "Metadata, timestamps, subtitles"
            case .footnote:
                return "Fine print, disclaimers"
            case .caption1:
                return "Image captions, small labels"
            case .caption2:
                return "Smallest text elements"
            }
        }
    }
    
    // MARK: - Semantic Text Styles
    enum SemanticStyle {
        case primary
        case secondary
        case tertiary
        case success
        case warning
        case error
        case link
        case placeholder
        
        var color: Color {
            switch self {
            case .primary:
                return DesignTokens.Colors.textPrimary
            case .secondary:
                return DesignTokens.Colors.textSecondary
            case .tertiary:
                return DesignTokens.Colors.textTertiary
            case .success:
                return Color.adaptiveSuccess
            case .warning:
                return Color.adaptiveWarning
            case .error:
                return Color.adaptiveError
            case .link:
                return Color.adaptivePrimary
            case .placeholder:
                return DesignTokens.Colors.textTertiary
            }
        }
    }
    
    // MARK: - Text Weight Variants
    enum FontWeight: String, CaseIterable {
        case ultraLight = "ultraLight"
        case thin = "thin"
        case light = "light"
        case regular = "regular"
        case medium = "medium"
        case semibold = "semibold"
        case bold = "bold"
        case heavy = "heavy"
        case black = "black"
        
        var swiftUIWeight: Font.Weight {
            switch self {
            case .ultraLight:
                return .ultraLight
            case .thin:
                return .thin
            case .light:
                return .light
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
            case .heavy:
                return .heavy
            case .black:
                return .black
            }
        }
    }
    
    // MARK: - Line Height Multipliers
    enum LineHeight: CGFloat {
        case tight = 1.1
        case normal = 1.2
        case relaxed = 1.4
        case loose = 1.6
    }
    
    // MARK: - Letter Spacing
    enum LetterSpacing: CGFloat {
        case tight = -0.5
        case normal = 0
        case wide = 0.5
        case wider = 1.0
    }
}

// MARK: - Typography Text View
struct TypographyText: View {
    let text: String
    let style: TypographyStyles.TextStyle
    let semanticStyle: TypographyStyles.SemanticStyle
    let weight: TypographyStyles.FontWeight?
    let lineHeight: TypographyStyles.LineHeight
    let letterSpacing: TypographyStyles.LetterSpacing
    let alignment: TextAlignment
    let lineLimit: Int?
    
    init(
        _ text: String,
        style: TypographyStyles.TextStyle = .body,
        semanticStyle: TypographyStyles.SemanticStyle = .primary,
        weight: TypographyStyles.FontWeight? = nil,
        lineHeight: TypographyStyles.LineHeight = .normal,
        letterSpacing: TypographyStyles.LetterSpacing = .normal,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) {
        self.text = text
        self.style = style
        self.semanticStyle = semanticStyle
        self.weight = weight
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.alignment = alignment
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        Text(text)
            .font(effectiveFont)
            .foregroundColor(semanticStyle.color)
            .tracking(letterSpacing.rawValue)
            .lineSpacing(effectiveLineSpacing)
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
    }
    
    private var effectiveFont: Font {
        if let weight = weight {
            return style.font.weight(weight.swiftUIWeight)
        }
        return style.font
    }
    
    private var effectiveLineSpacing: CGFloat {
        // Calculate line spacing based on font size and line height multiplier
        let baseFontSize: CGFloat = 17 // Default body font size
        return baseFontSize * (lineHeight.rawValue - 1.0)
    }
}

// MARK: - Typography Showcase View
struct TypographyShowcase: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Text Styles
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Text Styles", style: .title1, weight: .bold)
                    
                    ForEach(TypographyStyles.TextStyle.allCases, id: \.self) { textStyle in
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            TypographyText(
                                textStyle.displayName,
                                style: textStyle
                            )
                            TypographyText(
                                textStyle.usage,
                                style: .caption1,
                                semanticStyle: .secondary
                            )
                        }
                        .padding(.vertical, DesignTokens.Spacing.xs)
                    }
                }
                
                Divider()
                
                // Semantic Styles
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Semantic Colors", style: .title2, weight: .bold)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        TypographyText("Primary text color", semanticStyle: .primary)
                        TypographyText("Secondary text color", semanticStyle: .secondary)
                        TypographyText("Tertiary text color", semanticStyle: .tertiary)
                        TypographyText("Success message", semanticStyle: .success)
                        TypographyText("Warning message", semanticStyle: .warning)
                        TypographyText("Error message", semanticStyle: .error)
                        TypographyText("Link text", semanticStyle: .link)
                        TypographyText("Placeholder text", semanticStyle: .placeholder)
                    }
                }
                
                Divider()
                
                // Font Weights
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Font Weights", style: .title2, weight: .bold)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        ForEach(TypographyStyles.FontWeight.allCases, id: \.self) { fontWeight in
                            TypographyText(
                                "Font weight: \(fontWeight.rawValue)",
                                style: .body,
                                weight: fontWeight
                            )
                        }
                    }
                }
                
                Divider()
                
                // Line Heights and Spacing
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Line Heights", style: .title2, weight: .bold)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        TypographyText(
                            "Tight line height: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                            lineHeight: .tight
                        )
                        
                        TypographyText(
                            "Normal line height: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                            lineHeight: .normal
                        )
                        
                        TypographyText(
                            "Relaxed line height: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                            lineHeight: .relaxed
                        )
                        
                        TypographyText(
                            "Loose line height: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                            lineHeight: .loose
                        )
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.background)
    }
}

// MARK: - View Extensions for Typography
extension View {
    /// Apply typography style to any text view
    func typography(
        _ style: TypographyStyles.TextStyle,
        semanticStyle: TypographyStyles.SemanticStyle = .primary,
        weight: TypographyStyles.FontWeight? = nil
    ) -> some View {
        self
            .font(weight != nil ? style.font.weight(weight!.swiftUIWeight) : style.font)
            .foregroundColor(semanticStyle.color)
    }
}

// MARK: - Text Extensions
extension Text {
    /// Apply semantic color to text
    func semanticColor(_ style: TypographyStyles.SemanticStyle) -> Text {
        self.foregroundColor(style.color)
    }
    
    /// Apply typography style
    func typographyStyle(
        _ style: TypographyStyles.TextStyle,
        weight: TypographyStyles.FontWeight? = nil
    ) -> Text {
        let font = weight != nil ? style.font.weight(weight!.swiftUIWeight) : style.font
        return self.font(font)
    }
}

// MARK: - Preview
#Preview("Typography System") {
    TypographyShowcase()
}