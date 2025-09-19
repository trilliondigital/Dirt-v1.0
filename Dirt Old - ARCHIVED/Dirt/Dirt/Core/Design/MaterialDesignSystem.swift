import SwiftUI

// MARK: - Material Glass Design System
/// Central design system implementing iOS 18+ Material Glass effects
/// Builds upon existing UIColors, UISpacing, and UICornerRadius tokens
struct MaterialDesignSystem {
    
    // MARK: - Material Glass Backgrounds
    
    /// Material glass backgrounds for different contexts
    struct Glass {
        /// Ultra-thin material for subtle overlays
        static let ultraThin: Material = .ultraThinMaterial
        
        /// Thin material for cards and secondary surfaces
        static let thin: Material = .thinMaterial
        
        /// Regular material for primary surfaces and navigation
        static let regular: Material = .regularMaterial
        
        /// Thick material for prominent surfaces and modals
        static let thick: Material = .thickMaterial
        
        /// Ultra-thick material for maximum prominence
        static let ultraThick: Material = .ultraThickMaterial
    }
    
    // MARK: - Glass Color Overlays
    
    /// Color overlays that work well with Material backgrounds
    struct GlassColors {
        /// Primary glass tint (subtle blue)
        static let primary = Color.blue.opacity(0.1)
        
        /// Secondary glass tint (subtle purple)
        static let secondary = Color.purple.opacity(0.08)
        
        /// Success glass tint (subtle green)
        static let success = Color.green.opacity(0.1)
        
        /// Warning glass tint (subtle orange)
        static let warning = Color.orange.opacity(0.1)
        
        /// Danger glass tint (subtle red)
        static let danger = Color.red.opacity(0.1)
        
        /// Neutral glass tint
        static let neutral = Color.gray.opacity(0.05)
    }
    
    // MARK: - Glass Borders
    
    /// Border styles for glass components
    struct GlassBorders {
        /// Subtle white border for glass components
        static let subtle = Color.white.opacity(0.2)
        
        /// Prominent white border for focused states
        static let prominent = Color.white.opacity(0.4)
        
        /// Accent border using primary color
        static let accent = UIColors.accentPrimary.opacity(0.3)
    }
    
    // MARK: - Glass Shadows
    
    /// Shadow styles optimized for glass components
    struct GlassShadows {
        /// Soft shadow for floating glass elements
        static let soft = Color.black.opacity(0.1)
        
        /// Medium shadow for elevated glass surfaces
        static let medium = Color.black.opacity(0.15)
        
        /// Strong shadow for prominent glass modals
        static let strong = Color.black.opacity(0.25)
    }
    
    // MARK: - Context-Specific Materials
    
    /// Pre-configured materials for specific UI contexts
    struct Context {
        /// Navigation bars and headers
        static let navigation: Material = .regularMaterial
        
        /// Tab bars and bottom navigation
        static let tabBar: Material = .thinMaterial
        
        /// Cards and content surfaces
        static let card: Material = .thinMaterial
        
        /// Modal backgrounds and overlays
        static let modal: Material = .thickMaterial
        
        /// Floating action buttons and prominent CTAs
        static let floatingAction: Material = .regularMaterial
        
        /// Sidebar and drawer backgrounds
        static let sidebar: Material = .regularMaterial
    }
}

// MARK: - Material Glass Modifiers

/// View modifier for applying glass card styling
struct GlassCardModifier: ViewModifier {
    let material: Material
    let cornerRadius: CGFloat
    let borderColor: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    
    init(
        material: Material = MaterialDesignSystem.Context.card,
        cornerRadius: CGFloat = UICornerRadius.lg,
        borderColor: Color = MaterialDesignSystem.GlassBorders.subtle,
        shadowColor: Color = MaterialDesignSystem.GlassShadows.soft,
        shadowRadius: CGFloat = 8
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }
}

/// View modifier for applying glass button styling
struct GlassButtonModifier: ViewModifier {
    let material: Material
    let cornerRadius: CGFloat
    let isPressed: Bool
    
    init(
        material: Material = MaterialDesignSystem.Glass.thin,
        cornerRadius: CGFloat = UICornerRadius.md,
        isPressed: Bool = false
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.isPressed = isPressed
    }
    
    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isPressed ? MaterialDesignSystem.GlassBorders.prominent : MaterialDesignSystem.GlassBorders.subtle,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: MaterialDesignSystem.GlassShadows.soft,
                radius: isPressed ? 4 : 6,
                x: 0,
                y: isPressed ? 2 : 3
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass card styling to any view
    func glassCard(
        material: Material = MaterialDesignSystem.Context.card,
        cornerRadius: CGFloat = UICornerRadius.lg,
        borderColor: Color = MaterialDesignSystem.GlassBorders.subtle,
        shadowColor: Color = MaterialDesignSystem.GlassShadows.soft,
        shadowRadius: CGFloat = 8
    ) -> some View {
        modifier(GlassCardModifier(
            material: material,
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius
        ))
    }
    
    /// Apply glass button styling to any view
    func glassButton(
        material: Material = MaterialDesignSystem.Glass.thin,
        cornerRadius: CGFloat = UICornerRadius.md,
        isPressed: Bool = false
    ) -> some View {
        modifier(GlassButtonModifier(
            material: material,
            cornerRadius: cornerRadius,
            isPressed: isPressed
        ))
    }
}