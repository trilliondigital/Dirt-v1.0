import SwiftUI

/// A reusable glass card component with material background effects
struct GlassCard<Content: View>: View {
    
    // MARK: - Properties
    let content: Content
    let style: MaterialDesignSystem.GlassStyle
    let padding: CGFloat
    let isInteractive: Bool
    let onTap: (() -> Void)?
    
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var isPressed = false
    
    // MARK: - Initialization
    init(
        style: MaterialDesignSystem.GlassStyle = .card,
        padding: CGFloat = DesignTokens.Spacing.md,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.isInteractive = isInteractive
        self.onTap = onTap
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(style.materialType.material)
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: DesignTokens.Shadow.medium.x,
                        y: shadowY
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(animationPreferences.quickEasing, value: isPressed)
            .contentShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .onTapGesture {
                if isInteractive {
                    animationPreferences.lightHaptic()
                    onTap?()
                }
            }
            .pressEvents(
                onPress: {
                    if isInteractive {
                        isPressed = true
                    }
                },
                onRelease: {
                    if isInteractive {
                        isPressed = false
                    }
                }
            )
    }
    
    // MARK: - Computed Properties
    private var shadowColor: Color {
        DesignTokens.Shadow.medium.color
    }
    
    private var shadowRadius: CGFloat {
        isPressed ? style.shadowRadius * 0.5 : style.shadowRadius
    }
    
    private var shadowY: CGFloat {
        isPressed ? DesignTokens.Shadow.medium.y * 0.5 : DesignTokens.Shadow.medium.y
    }
}

// MARK: - Convenience Initializers
extension GlassCard {
    
    /// Create an interactive glass card with tap handling
    static func interactive<Content: View>(
        style: MaterialDesignSystem.GlassStyle = .card,
        padding: CGFloat = DesignTokens.Spacing.md,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> GlassCard<Content> {
        GlassCard(
            style: style,
            padding: padding,
            isInteractive: true,
            onTap: onTap,
            content: content
        )
    }
    
    /// Create a static glass card without interaction
    static func `static`<Content: View>(
        style: MaterialDesignSystem.GlassStyle = .card,
        padding: CGFloat = DesignTokens.Spacing.md,
        @ViewBuilder content: () -> Content
    ) -> GlassCard<Content> {
        GlassCard(
            style: style,
            padding: padding,
            isInteractive: false,
            onTap: nil,
            content: content
        )
    }
}

// MARK: - Preview
#Preview("Glass Card Styles") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Static Cards
            GlassCard.static(style: .card) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Card Style")
                        .font(DesignTokens.Typography.headline)
                    Text("This is a static glass card with card styling.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            GlassCard.static(style: .overlay) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Overlay Style")
                        .font(DesignTokens.Typography.headline)
                    Text("This is a static glass card with overlay styling.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // Interactive Cards
            GlassCard.interactive(style: .card, onTap: {
                print("Card tapped!")
            }) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Interactive Card")
                        .font(DesignTokens.Typography.headline)
                    Text("Tap me to see the interaction effect!")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            GlassCard.interactive(style: .navigation, onTap: {
                print("Navigation card tapped!")
            }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(DesignTokens.Colors.primary)
                    Text("Settings")
                        .font(DesignTokens.Typography.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(DesignTokens.Colors.background)
    .withAnimationPreferences()
}