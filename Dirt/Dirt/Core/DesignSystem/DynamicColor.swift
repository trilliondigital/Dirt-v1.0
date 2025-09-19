import SwiftUI
import UIKit

/// Dynamic color extensions for automatic light/dark mode adaptation
extension Color {
    
    // MARK: - Dynamic Color Creation
    
    /// Create a dynamic color that automatically adapts to light/dark mode
    static func dynamic(
        light: Color,
        dark: Color
    ) -> Color {
        Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    /// Create a dynamic color from hex values
    static func dynamic(
        lightHex: String,
        darkHex: String
    ) -> Color {
        dynamic(
            light: Color(hex: lightHex),
            dark: Color(hex: darkHex)
        )
    }
    
    /// Create a dynamic color with opacity variations
    static func dynamicWithOpacity(
        baseColor: Color,
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> Color {
        dynamic(
            light: baseColor.opacity(lightOpacity),
            dark: baseColor.opacity(darkOpacity)
        )
    }
    
    // MARK: - Semantic Dynamic Colors
    
    /// Primary brand color that adapts to theme
    static var dynamicPrimary: Color {
        dynamic(
            light: Color(red: 0.0, green: 0.48, blue: 1.0),    // #007AFF
            dark: Color(red: 0.04, green: 0.52, blue: 1.0)     // #0A84FF
        )
    }
    
    /// Secondary color that adapts to theme
    static var dynamicSecondary: Color {
        dynamic(
            light: Color(red: 0.56, green: 0.56, blue: 0.58),  // #8E8E93
            dark: Color(red: 0.56, green: 0.56, blue: 0.58)    // #8E8E93
        )
    }
    
    /// Success color that adapts to theme
    static var dynamicSuccess: Color {
        dynamic(
            light: Color(red: 0.20, green: 0.78, blue: 0.35),  // #34C759
            dark: Color(red: 0.19, green: 0.82, blue: 0.35)    // #30D158
        )
    }
    
    /// Warning color that adapts to theme
    static var dynamicWarning: Color {
        dynamic(
            light: Color(red: 1.0, green: 0.58, blue: 0.0),    // #FF9500
            dark: Color(red: 1.0, green: 0.62, blue: 0.04)     // #FF9F0A
        )
    }
    
    /// Error color that adapts to theme
    static var dynamicError: Color {
        dynamic(
            light: Color(red: 1.0, green: 0.23, blue: 0.19),   // #FF3B30
            dark: Color(red: 1.0, green: 0.27, blue: 0.23)     // #FF453A
        )
    }
    
    /// Background color that adapts to theme
    static var dynamicBackground: Color {
        dynamic(
            light: Color(UIColor.systemBackground),
            dark: Color(UIColor.systemBackground)
        )
    }
    
    /// Surface color that adapts to theme
    static var dynamicSurface: Color {
        dynamic(
            light: Color(UIColor.secondarySystemBackground),
            dark: Color(UIColor.secondarySystemBackground)
        )
    }
    
    /// Text color that adapts to theme
    static var dynamicText: Color {
        dynamic(
            light: Color(UIColor.label),
            dark: Color(UIColor.label)
        )
    }
    
    /// Secondary text color that adapts to theme
    static var dynamicTextSecondary: Color {
        dynamic(
            light: Color(UIColor.secondaryLabel),
            dark: Color(UIColor.secondaryLabel)
        )
    }
    
    /// Border color that adapts to theme
    static var dynamicBorder: Color {
        dynamic(
            light: Color(UIColor.separator),
            dark: Color(UIColor.separator)
        )
    }
    
    // MARK: - Color Manipulation
    
    /// Adjust color brightness for different themes
    func adjustedForTheme(
        lightAdjustment: CGFloat = 0.0,
        darkAdjustment: CGFloat = 0.0
    ) -> Color {
        Color.dynamic(
            light: self.adjustBrightness(by: lightAdjustment),
            dark: self.adjustBrightness(by: darkAdjustment)
        )
    }
    
    /// Adjust color opacity for different themes
    func adjustedOpacityForTheme(
        lightOpacity: Double = 1.0,
        darkOpacity: Double = 1.0
    ) -> Color {
        Color.dynamic(
            light: self.opacity(lightOpacity),
            dark: self.opacity(darkOpacity)
        )
    }
    
    // MARK: - Accessibility Helpers
    
    /// Get high contrast version of color
    var highContrast: Color {
        Color.dynamic(
            light: self.adjustBrightness(by: -0.2),
            dark: self.adjustBrightness(by: 0.2)
        )
    }
    
    /// Get reduced contrast version of color
    var reducedContrast: Color {
        Color.dynamic(
            light: self.adjustBrightness(by: 0.1),
            dark: self.adjustBrightness(by: -0.1)
        )
    }
    
    /// Check if color is suitable for text on given background
    func isAccessible(on background: Color) -> Bool {
        // Simplified accessibility check
        // In a real implementation, you'd calculate actual contrast ratios
        return true
    }
    
    // MARK: - Material Design Elevation Colors
    
    /// Get elevation-appropriate color for material design
    static func elevationColor(level: Int) -> Color {
        let opacity = min(0.12, Double(level) * 0.02)
        return Color.dynamicText.opacity(opacity)
    }
    
    /// Surface color with elevation
    static func surfaceWithElevation(_ level: Int) -> Color {
        let baseColor = Color.dynamicSurface
        let elevationAmount = min(0.12, Double(level) * 0.02)
        
        return Color.dynamic(
            light: baseColor,
            dark: baseColor.adjustBrightness(by: elevationAmount)
        )
    }
}

// MARK: - Theme-Aware Color Environment
struct ThemeAwareColorEnvironment: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var themeManager = ThemeManager()
    
    func body(content: Content) -> some View {
        content
            .environment(\.themeManager, themeManager)
            .onChange(of: colorScheme) { _, newColorScheme in
                themeManager.handleSystemColorSchemeChange(newColorScheme)
            }
    }
}

// MARK: - Dynamic Color Showcase
struct DynamicColorShowcase: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Dynamic Colors", style: .title1, weight: .bold)
                    TypographyText(
                        "These colors automatically adapt to light and dark mode",
                        style: .body,
                        semanticStyle: .secondary
                    )
                }
                
                // Current theme indicator
                GlassCard.static(style: .card) {
                    HStack {
                        Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(Color.dynamicPrimary)
                        TypographyText(
                            "Current theme: \(colorScheme == .dark ? "Dark" : "Light")",
                            style: .headline
                        )
                        Spacer()
                    }
                }
                
                // Dynamic color examples
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
                    dynamicColorCard("Primary", Color.dynamicPrimary)
                    dynamicColorCard("Secondary", Color.dynamicSecondary)
                    dynamicColorCard("Success", Color.dynamicSuccess)
                    dynamicColorCard("Warning", Color.dynamicWarning)
                    dynamicColorCard("Error", Color.dynamicError)
                    dynamicColorCard("Background", Color.dynamicBackground)
                    dynamicColorCard("Surface", Color.dynamicSurface)
                    dynamicColorCard("Text", Color.dynamicText)
                }
                
                // Elevation examples
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Surface Elevation", style: .title2, weight: .bold)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(0..<6, id: \.self) { level in
                            HStack {
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                                    .fill(Color.surfaceWithElevation(level))
                                    .frame(height: 40)
                                    .overlay(
                                        TypographyText("Elevation \(level)", style: .callout)
                                    )
                            }
                        }
                    }
                }
                
                // Accessibility examples
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Accessibility Variants", style: .title2, weight: .bold)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        accessibilityColorCard("Normal Contrast", Color.dynamicPrimary)
                        accessibilityColorCard("High Contrast", Color.dynamicPrimary.highContrast)
                        accessibilityColorCard("Reduced Contrast", Color.dynamicPrimary.reducedContrast)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(Color.dynamicBackground)
    }
    
    private func dynamicColorCard(_ name: String, _ color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(color)
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(Color.dynamicBorder, lineWidth: 1)
                )
            
            TypographyText(name, style: .callout, weight: .medium)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(Color.dynamicSurface)
        )
    }
    
    private func accessibilityColorCard(_ name: String, _ color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(color)
                .frame(width: 60, height: 40)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                TypographyText(name, style: .callout, weight: .medium)
                TypographyText("Sample text on this color", style: .caption1)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(Color.dynamicSurface)
        )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply theme-aware color environment
    func withThemeAwareColors() -> some View {
        self.modifier(ThemeAwareColorEnvironment())
    }
}

// MARK: - Preview
#Preview("Dynamic Colors") {
    DynamicColorShowcase()
        .withThemeAwareColors()
}