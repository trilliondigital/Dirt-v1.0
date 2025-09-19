import SwiftUI

/// A versatile action button with haptic feedback, loading states, and consistent styling
struct ActionButton: View {
    
    // MARK: - Button Styles
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        case ghost
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return Color.adaptivePrimary
            case .secondary:
                return DesignTokens.Colors.surface
            case .tertiary:
                return DesignTokens.Colors.secondaryBackground
            case .destructive:
                return Color.adaptiveError
            case .ghost:
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive:
                return .white
            case .secondary, .tertiary, .ghost:
                return DesignTokens.Colors.textPrimary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .secondary, .ghost:
                return DesignTokens.Colors.border
            case .primary, .tertiary, .destructive:
                return nil
            }
        }
    }
    
    // MARK: - Button Sizes
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 44
            case .large:
                return 56
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(
                    top: DesignTokens.Spacing.xs,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.xs,
                    trailing: DesignTokens.Spacing.md
                )
            case .medium:
                return EdgeInsets(
                    top: DesignTokens.Spacing.sm,
                    leading: DesignTokens.Spacing.lg,
                    bottom: DesignTokens.Spacing.sm,
                    trailing: DesignTokens.Spacing.lg
                )
            case .large:
                return EdgeInsets(
                    top: DesignTokens.Spacing.md,
                    leading: DesignTokens.Spacing.xl,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.xl
                )
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return DesignTokens.Typography.callout
            case .medium:
                return DesignTokens.Typography.headline
            case .large:
                return DesignTokens.Typography.title3
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let systemImage: String?
    let style: ButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var isPressed = false
    
    // MARK: - Initialization
    init(
        _ title: String,
        systemImage: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if isLoading {
                    LoadingSpinner(size: .small, color: style.foregroundColor)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(size.font.weight(.medium))
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(size.font.weight(.medium))
                        .lineLimit(1)
                }
            }
            .foregroundColor(effectiveForegroundColor)
            .padding(size.padding)
            .frame(minHeight: size.height)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(effectiveBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                            .stroke(effectiveBorderColor, lineWidth: style.borderColor != nil ? 1 : 0)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(effectiveOpacity)
            .animation(animationPreferences.quickEasing, value: isPressed)
            .animation(animationPreferences.standardEasing, value: isLoading)
            .animation(animationPreferences.standardEasing, value: isDisabled)
        }
        .disabled(isDisabled || isLoading)
        .pressEvents(
            onPress: {
                if !isDisabled && !isLoading {
                    isPressed = true
                }
            },
            onRelease: {
                isPressed = false
            }
        )
    }
    
    // MARK: - Computed Properties
    private var effectiveBackgroundColor: Color {
        if isDisabled {
            return DesignTokens.Colors.tertiaryBackground
        }
        return style.backgroundColor
    }
    
    private var effectiveForegroundColor: Color {
        if isDisabled {
            return DesignTokens.Colors.textTertiary
        }
        return style.foregroundColor
    }
    
    private var effectiveBorderColor: Color {
        if isDisabled {
            return DesignTokens.Colors.border.opacity(0.5)
        }
        return style.borderColor ?? Color.clear
    }
    
    private var effectiveOpacity: Double {
        if isDisabled {
            return 0.6
        }
        return isPressed ? 0.8 : 1.0
    }
    
    // MARK: - Methods
    private func handleTap() {
        guard !isDisabled && !isLoading else { return }
        
        // Provide haptic feedback based on button style
        switch style {
        case .primary:
            animationPreferences.mediumHaptic()
        case .destructive:
            animationPreferences.warningHaptic()
        case .secondary, .tertiary, .ghost:
            animationPreferences.lightHaptic()
        }
        
        action()
    }
}

// MARK: - Convenience Initializers
extension ActionButton {
    
    /// Create a primary action button
    static func primary(
        _ title: String,
        systemImage: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title,
            systemImage: systemImage,
            style: .primary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    /// Create a secondary action button
    static func secondary(
        _ title: String,
        systemImage: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title,
            systemImage: systemImage,
            style: .secondary,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    /// Create a destructive action button
    static func destructive(
        _ title: String,
        systemImage: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title,
            systemImage: systemImage,
            style: .destructive,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    /// Create a ghost (borderless) action button
    static func ghost(
        _ title: String,
        systemImage: String? = nil,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            title,
            systemImage: systemImage,
            style: .ghost,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
    
    /// Create an icon-only button
    static func icon(
        systemImage: String,
        style: ButtonStyle = .secondary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> ActionButton {
        ActionButton(
            "",
            systemImage: systemImage,
            style: style,
            size: size,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

// MARK: - Preview
#Preview("Action Button Styles") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Button Styles")
                    .font(DesignTokens.Typography.title2)
                
                ActionButton.primary("Primary Button", systemImage: "checkmark") {
                    print("Primary tapped")
                }
                
                ActionButton.secondary("Secondary Button", systemImage: "gear") {
                    print("Secondary tapped")
                }
                
                ActionButton("Tertiary Button", systemImage: "info.circle", style: .tertiary) {
                    print("Tertiary tapped")
                }
                
                ActionButton.destructive("Delete", systemImage: "trash") {
                    print("Delete tapped")
                }
                
                ActionButton.ghost("Ghost Button", systemImage: "link") {
                    print("Ghost tapped")
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Button Sizes")
                    .font(DesignTokens.Typography.title2)
                
                ActionButton.primary("Small", size: .small) {
                    print("Small tapped")
                }
                
                ActionButton.primary("Medium", size: .medium) {
                    print("Medium tapped")
                }
                
                ActionButton.primary("Large", size: .large) {
                    print("Large tapped")
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Button States")
                    .font(DesignTokens.Typography.title2)
                
                ActionButton.primary("Loading", isLoading: true) {
                    print("Loading tapped")
                }
                
                ActionButton.primary("Disabled", isDisabled: true) {
                    print("Disabled tapped")
                }
                
                ActionButton.icon(systemImage: "heart.fill", style: .primary) {
                    print("Icon tapped")
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(DesignTokens.Colors.background)
    .withAnimationPreferences()
}