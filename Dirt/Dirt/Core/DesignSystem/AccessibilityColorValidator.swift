import SwiftUI
import UIKit

/// Accessibility color validation utilities for WCAG compliance
struct AccessibilityColorValidator {
    
    // MARK: - WCAG Contrast Levels
    enum ContrastLevel: String, CaseIterable {
        case AA = "AA"
        case AAA = "AAA"
        
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
        
        var displayName: String {
            switch self {
            case .AA: return "WCAG AA"
            case .AAA: return "WCAG AAA"
            }
        }
    }
    
    // MARK: - Text Size Categories
    enum TextSize {
        case normal
        case large
        
        var minimumRatio: Double {
            switch self {
            case .normal: return 4.5  // WCAG AA for normal text
            case .large: return 3.0   // WCAG AA for large text
            }
        }
    }
    
    // MARK: - Contrast Calculation
    
    /// Calculate contrast ratio between two colors
    static func contrastRatio(foreground: Color, background: Color) -> Double {
        let foregroundLuminance = relativeLuminance(of: foreground)
        let backgroundLuminance = relativeLuminance(of: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of a color
    private static func relativeLuminance(of color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let sRGBToLinear = { (component: CGFloat) -> Double in
            let c = Double(component)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        
        let linearRed = sRGBToLinear(red)
        let linearGreen = sRGBToLinear(green)
        let linearBlue = sRGBToLinear(blue)
        
        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }
    
    // MARK: - Validation Methods
    
    /// Check if color combination meets WCAG requirements
    static func meetsContrastRequirements(
        foreground: Color,
        background: Color,
        level: ContrastLevel = .AA,
        textSize: TextSize = .normal
    ) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        let requiredRatio = textSize == .normal ? level.normalTextRatio : level.largeTextRatio
        return ratio >= requiredRatio
    }
    
    /// Get contrast validation result with details
    static func validateContrast(
        foreground: Color,
        background: Color,
        textSize: TextSize = .normal
    ) -> ContrastValidationResult {
        let ratio = contrastRatio(foreground: foreground, background: background)
        
        let aaCompliant = ratio >= (textSize == .normal ? ContrastLevel.AA.normalTextRatio : ContrastLevel.AA.largeTextRatio)
        let aaaCompliant = ratio >= (textSize == .normal ? ContrastLevel.AAA.normalTextRatio : ContrastLevel.AAA.largeTextRatio)
        
        return ContrastValidationResult(
            ratio: ratio,
            isAACompliant: aaCompliant,
            isAAACompliant: aaaCompliant,
            textSize: textSize
        )
    }
    
    /// Find accessible color variants
    static func findAccessibleVariants(
        baseColor: Color,
        background: Color,
        level: ContrastLevel = .AA,
        textSize: TextSize = .normal
    ) -> AccessibleColorVariants {
        let originalRatio = contrastRatio(foreground: baseColor, background: background)
        let requiredRatio = textSize == .normal ? level.normalTextRatio : level.largeTextRatio
        
        var lighterVariant: Color?
        var darkerVariant: Color?
        
        // Try to find lighter variant
        if originalRatio < requiredRatio {
            for adjustment in stride(from: 0.1, through: 1.0, by: 0.1) {
                let candidate = baseColor.adjustBrightness(by: adjustment)
                if contrastRatio(foreground: candidate, background: background) >= requiredRatio {
                    lighterVariant = candidate
                    break
                }
            }
            
            // Try to find darker variant
            for adjustment in stride(from: -0.1, through: -1.0, by: -0.1) {
                let candidate = baseColor.adjustBrightness(by: adjustment)
                if contrastRatio(foreground: candidate, background: background) >= requiredRatio {
                    darkerVariant = candidate
                    break
                }
            }
        }
        
        return AccessibleColorVariants(
            original: baseColor,
            originalRatio: originalRatio,
            lighterVariant: lighterVariant,
            darkerVariant: darkerVariant,
            requiredRatio: requiredRatio
        )
    }
}

// MARK: - Validation Result Types
struct ContrastValidationResult {
    let ratio: Double
    let isAACompliant: Bool
    let isAAACompliant: Bool
    let textSize: AccessibilityColorValidator.TextSize
    
    var complianceLevel: String {
        if isAAACompliant {
            return "WCAG AAA"
        } else if isAACompliant {
            return "WCAG AA"
        } else {
            return "Non-compliant"
        }
    }
    
    var statusColor: Color {
        if isAAACompliant {
            return Color.dynamicSuccess
        } else if isAACompliant {
            return Color.dynamicWarning
        } else {
            return Color.dynamicError
        }
    }
}

struct AccessibleColorVariants {
    let original: Color
    let originalRatio: Double
    let lighterVariant: Color?
    let darkerVariant: Color?
    let requiredRatio: Double
    
    var hasAccessibleVariants: Bool {
        return lighterVariant != nil || darkerVariant != nil
    }
}

// MARK: - Color Brightness Adjustment Extension
extension Color {
    func adjustBrightness(by amount: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = max(0, min(1, brightness + amount))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha))
    }
}

// MARK: - Accessibility Validation Showcase
struct AccessibilityValidationShowcase: View {
    @State private var selectedForeground = Color.dynamicPrimary
    @State private var selectedBackground = Color.dynamicBackground
    @State private var selectedTextSize: AccessibilityColorValidator.TextSize = .normal
    
    private var validationResult: ContrastValidationResult {
        AccessibilityColorValidator.validateContrast(
            foreground: selectedForeground,
            background: selectedBackground,
            textSize: selectedTextSize
        )
    }
    
    private var colorVariants: AccessibleColorVariants {
        AccessibilityColorValidator.findAccessibleVariants(
            baseColor: selectedForeground,
            background: selectedBackground,
            level: .AA,
            textSize: selectedTextSize
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Accessibility Color Validation", style: .title1, weight: .bold)
                    TypographyText(
                        "Test color combinations for WCAG compliance",
                        style: .body,
                        semanticStyle: .secondary
                    )
                }
                
                // Color Selection
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Color Selection", style: .title2, weight: .bold)
                    
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            TypographyText("Foreground", style: .callout, weight: .medium)
                            colorPicker(color: $selectedForeground)
                        }
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            TypographyText("Background", style: .callout, weight: .medium)
                            colorPicker(color: $selectedBackground)
                        }
                    }
                    
                    // Text Size Selection
                    Picker("Text Size", selection: $selectedTextSize) {
                        Text("Normal Text").tag(AccessibilityColorValidator.TextSize.normal)
                        Text("Large Text").tag(AccessibilityColorValidator.TextSize.large)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Validation Results
                GlassCard.static(style: .card) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            TypographyText("Validation Results", style: .headline, weight: .bold)
                            Spacer()
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Circle()
                                    .fill(validationResult.statusColor)
                                    .frame(width: 8, height: 8)
                                TypographyText(
                                    validationResult.complianceLevel,
                                    style: .callout,
                                    weight: .medium
                                )
                                .foregroundColor(validationResult.statusColor)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            HStack {
                                TypographyText("Contrast Ratio:", style: .callout)
                                Spacer()
                                TypographyText(
                                    String(format: "%.2f:1", validationResult.ratio),
                                    style: .callout,
                                    weight: .medium
                                )
                            }
                            
                            HStack {
                                TypographyText("WCAG AA:", style: .callout)
                                Spacer()
                                Image(systemName: validationResult.isAACompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(validationResult.isAACompliant ? Color.dynamicSuccess : Color.dynamicError)
                            }
                            
                            HStack {
                                TypographyText("WCAG AAA:", style: .callout)
                                Spacer()
                                Image(systemName: validationResult.isAAACompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(validationResult.isAAACompliant ? Color.dynamicSuccess : Color.dynamicError)
                            }
                        }
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Preview", style: .title2, weight: .bold)
                    
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .fill(selectedBackground)
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Text("Sample Text")
                                    .font(selectedTextSize == .normal ? DesignTokens.Typography.body : DesignTokens.Typography.title2)
                                    .foregroundColor(selectedForeground)
                                
                                Text("This is how your text will look")
                                    .font(DesignTokens.Typography.callout)
                                    .foregroundColor(selectedForeground)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .stroke(Color.dynamicBorder, lineWidth: 1)
                        )
                }
                
                // Accessible Variants
                if colorVariants.hasAccessibleVariants {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        TypographyText("Accessible Alternatives", style: .title2, weight: .bold)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            if let lighterVariant = colorVariants.lighterVariant {
                                accessibleVariantCard("Lighter Variant", lighterVariant)
                            }
                            
                            if let darkerVariant = colorVariants.darkerVariant {
                                accessibleVariantCard("Darker Variant", darkerVariant)
                            }
                        }
                    }
                }
                
                // Predefined Color Tests
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    TypographyText("Common Color Combinations", style: .title2, weight: .bold)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        colorCombinationTest("Primary on Background", Color.dynamicPrimary, Color.dynamicBackground)
                        colorCombinationTest("Success on Background", Color.dynamicSuccess, Color.dynamicBackground)
                        colorCombinationTest("Error on Background", Color.dynamicError, Color.dynamicBackground)
                        colorCombinationTest("Text on Surface", Color.dynamicText, Color.dynamicSurface)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(Color.dynamicBackground)
    }
    
    private func colorPicker(color: Binding<Color>) -> some View {
        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
            .fill(color.wrappedValue)
            .frame(width: 60, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .stroke(Color.dynamicBorder, lineWidth: 1)
            )
            .onTapGesture {
                // In a real implementation, you'd show a color picker
            }
    }
    
    private func accessibleVariantCard(_ title: String, _ color: Color) -> some View {
        let ratio = AccessibilityColorValidator.contrastRatio(foreground: color, background: selectedBackground)
        
        return HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                TypographyText(title, style: .callout, weight: .medium)
                TypographyText(
                    String(format: "Ratio: %.2f:1", ratio),
                    style: .caption1,
                    semanticStyle: .secondary
                )
            }
            
            Spacer()
            
            Button("Use") {
                selectedForeground = color
            }
            .buttonStyle(.bordered)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(Color.dynamicSurface)
        )
    }
    
    private func colorCombinationTest(_ title: String, _ foreground: Color, _ background: Color) -> some View {
        let validation = AccessibilityColorValidator.validateContrast(
            foreground: foreground,
            background: background,
            textSize: selectedTextSize
        )
        
        return HStack(spacing: DesignTokens.Spacing.md) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(background)
                .frame(width: 60, height: 40)
                .overlay(
                    Text("Aa")
                        .font(DesignTokens.Typography.callout.weight(.medium))
                        .foregroundColor(foreground)
                )
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                TypographyText(title, style: .callout)
                TypographyText(
                    String(format: "%.2f:1 - %@", validation.ratio, validation.complianceLevel),
                    style: .caption1
                )
                .foregroundColor(validation.statusColor)
            }
            
            Spacer()
            
            Image(systemName: validation.isAACompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(validation.statusColor)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(Color.dynamicSurface)
        )
    }
}

// MARK: - Preview
#Preview("Accessibility Validation") {
    AccessibilityValidationShowcase()
}