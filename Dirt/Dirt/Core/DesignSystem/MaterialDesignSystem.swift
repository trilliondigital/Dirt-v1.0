import SwiftUI

/// Material design system providing glassmorphism effects and material components
struct MaterialDesignSystem {
    
    // MARK: - Material Types
    enum MaterialType {
        case ultraThin
        case thin
        case regular
        case thick
        case ultraThick
        
        var material: Material {
            switch self {
            case .ultraThin:
                return .ultraThinMaterial
            case .thin:
                return .thinMaterial
            case .regular:
                return .regularMaterial
            case .thick:
                return .thickMaterial
            case .ultraThick:
                return .ultraThickMaterial
            }
        }
    }
    
    // MARK: - Glass Effect Styles
    enum GlassStyle {
        case card
        case overlay
        case navigation
        case modal
        
        var materialType: MaterialType {
            switch self {
            case .card:
                return .thin
            case .overlay:
                return .regular
            case .navigation:
                return .thick
            case .modal:
                return .ultraThick
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .card:
                return DesignTokens.CornerRadius.md
            case .overlay:
                return DesignTokens.CornerRadius.lg
            case .navigation:
                return DesignTokens.CornerRadius.sm
            case .modal:
                return DesignTokens.CornerRadius.xl
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .card:
                return DesignTokens.Shadow.medium.radius
            case .overlay:
                return DesignTokens.Shadow.large.radius
            case .navigation:
                return DesignTokens.Shadow.small.radius
            case .modal:
                return DesignTokens.Shadow.large.radius
            }
        }
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffect: ViewModifier {
    let style: MaterialDesignSystem.GlassStyle
    let isPressed: Bool
    
    init(style: MaterialDesignSystem.GlassStyle, isPressed: Bool = false) {
        self.style = style
        self.isPressed = isPressed
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(style.materialType.material)
                    .shadow(
                        color: DesignTokens.Shadow.medium.color,
                        radius: isPressed ? style.shadowRadius * 0.5 : style.shadowRadius,
                        x: DesignTokens.Shadow.medium.x,
                        y: isPressed ? DesignTokens.Shadow.medium.y * 0.5 : DesignTokens.Shadow.medium.y
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.Animation.quick), value: isPressed)
    }
}

// MARK: - Material Card Component
struct MaterialCard<Content: View>: View {
    let style: MaterialDesignSystem.GlassStyle
    let content: Content
    @State private var isPressed = false
    
    init(style: MaterialDesignSystem.GlassStyle = .card, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignTokens.Spacing.md)
            .modifier(GlassEffect(style: style, isPressed: isPressed))
            .onTapGesture {
                // Haptic feedback will be added in ActionButton component
            }
            .pressEvents {
                withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                    isPressed = true
                }
            } onRelease: {
                withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                    isPressed = false
                }
            }
    }
}

// MARK: - Material Background Modifier
struct MaterialBackground: ViewModifier {
    let materialType: MaterialDesignSystem.MaterialType
    let cornerRadius: CGFloat
    
    init(
        materialType: MaterialDesignSystem.MaterialType = .regular,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.md
    ) {
        self.materialType = materialType
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(materialType.material)
            )
    }
}

// MARK: - Press Events Helper
struct PressEvents: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Apply glass effect to any view
    func glassEffect(style: MaterialDesignSystem.GlassStyle = .card) -> some View {
        self.modifier(GlassEffect(style: style))
    }
    
    /// Apply material background to any view
    func materialBackground(
        _ materialType: MaterialDesignSystem.MaterialType = .regular,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.md
    ) -> some View {
        self.modifier(MaterialBackground(materialType: materialType, cornerRadius: cornerRadius))
    }
    
    /// Add press event handlers
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Glassmorphism Utilities
extension MaterialDesignSystem {
    
    /// Create a glassmorphism overlay for modals and sheets
    static func createGlassOverlay() -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
    }
    
    /// Create a frosted glass navigation bar background
    static func createNavigationBackground() -> some View {
        Rectangle()
            .fill(.regularMaterial)
            .ignoresSafeArea(edges: .top)
    }
    
    /// Create a floating glass panel
    static func createFloatingPanel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                    .fill(.thickMaterial)
                    .shadow(
                        color: DesignTokens.Shadow.large.color,
                        radius: DesignTokens.Shadow.large.radius,
                        x: DesignTokens.Shadow.large.x,
                        y: DesignTokens.Shadow.large.y
                    )
            )
    }
}