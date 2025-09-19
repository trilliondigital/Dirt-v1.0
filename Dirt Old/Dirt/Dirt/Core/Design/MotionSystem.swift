import SwiftUI

// MARK: - Material Motion System
/// Consistent animation and transition system for Material Glass components
/// Provides standardized timing, easing, and motion patterns
struct MaterialMotion {
    
    // MARK: - Duration Constants
    
    /// Animation durations following Material Design guidelines
    struct Duration {
        /// Quick interactions (75ms)
        static let quick: TimeInterval = 0.075
        
        /// Standard interactions (150ms)
        static let standard: TimeInterval = 0.15
        
        /// Emphasized interactions (300ms)
        static let emphasized: TimeInterval = 0.3
        
        /// Slow transitions (500ms)
        static let slow: TimeInterval = 0.5
        
        /// Extra slow for complex animations (750ms)
        static let extraSlow: TimeInterval = 0.75
    }
    
    // MARK: - Easing Curves
    
    /// Standard easing animations
    struct Easing {
        /// Quick ease for micro-interactions
        static let quick = Animation.easeInOut(duration: Duration.quick)
        
        /// Standard ease for most interactions
        static let standard = Animation.easeInOut(duration: Duration.standard)
        
        /// Emphasized ease for important transitions
        static let emphasized = Animation.easeInOut(duration: Duration.emphasized)
        
        /// Slow ease for complex transitions
        static let slow = Animation.easeInOut(duration: Duration.slow)
        
        /// Extra slow for modal presentations
        static let extraSlow = Animation.easeInOut(duration: Duration.extraSlow)
    }
    
    // MARK: - Spring Animations
    
    /// Spring-based animations for natural motion
    struct Spring {
        /// Quick spring for button presses
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
        
        /// Standard spring for card interactions
        static let standard = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
        
        /// Bouncy spring for playful interactions
        static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
        
        /// Gentle spring for modal presentations
        static let gentle = Animation.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)
        
        /// Smooth spring for glass effects
        static let glass = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }
    
    // MARK: - Transition Animations
    
    /// Pre-configured transitions for common UI patterns
    struct Transition {
        /// Slide in from bottom (for modals)
        static let slideUp = AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
            .animation(.spring(response: 0.6, dampingFraction: 0.8))
        
        /// Slide in from top (for notifications)
        static let slideDown = AnyTransition.move(edge: .top)
            .combined(with: .opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.7))
        
        /// Scale and fade (for cards)
        static let scaleAndFade = AnyTransition.scale(scale: 0.9)
            .combined(with: .opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.8))
        
        /// Glass appearance (for glass components)
        static let glassAppear = AnyTransition.scale(scale: 0.95)
            .combined(with: .opacity)
            .animation(.spring(response: 0.6, dampingFraction: 0.8))
        
        /// Push from right (for navigation)
        static let pushFromRight = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
        .animation(.easeInOut(duration: 0.3))
    }
    
    // MARK: - Interactive Animations
    
    /// Animations for interactive elements
    struct Interactive {
        /// Button press animation
        static func buttonPress(isPressed: Bool) -> Animation {
            isPressed ? .easeInOut(duration: 0.1) : .spring(response: 0.3, dampingFraction: 0.6)
        }
        
        /// Card hover/selection animation
        static func cardSelection(isSelected: Bool) -> Animation {
            isSelected ? .spring(response: 0.4, dampingFraction: 0.7) : .easeOut(duration: 0.2)
        }
        
        /// Tab selection animation
        static func tabSelection() -> Animation {
            .spring(response: 0.4, dampingFraction: 0.8)
        }
        
        /// Search focus animation
        static func searchFocus(isFocused: Bool) -> Animation {
            isFocused ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.15)
        }
    }
    
    // MARK: - Glass-Specific Animations
    
    /// Animations specifically designed for Material Glass effects
    struct Glass {
        /// Glass card appearance
        static let cardAppear = Animation.spring(response: 0.6, dampingFraction: 0.8)
        
        /// Glass modal presentation
        static let modalPresent = Animation.spring(response: 0.7, dampingFraction: 0.8)
        
        /// Glass toast notification
        static let toastAppear = Animation.spring(response: 0.5, dampingFraction: 0.7)
        
        /// Glass navigation transition
        static let navigationTransition = Animation.easeInOut(duration: 0.3)
        
        /// Glass blur effect transition
        static let blurTransition = Animation.easeInOut(duration: 0.4)
    }
    
    // MARK: - Loading Animations
    
    /// Animations for loading states
    struct Loading {
        /// Pulse animation for loading placeholders
        static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        
        /// Rotation animation for spinners
        static let rotation = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
        
        /// Shimmer animation for skeleton loading
        static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        
        /// Breathing animation for subtle loading indicators
        static let breathing = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }
}

// MARK: - Motion Modifiers

/// View modifier for applying consistent motion to glass components
struct GlassMotionModifier: ViewModifier {
    let motionType: MotionType
    let isActive: Bool
    
    enum MotionType {
        case appear
        case press
        case selection
        case focus
        case modal
        
        var animation: Animation {
            switch self {
            case .appear: return MaterialMotion.Glass.cardAppear
            case .press: return MaterialMotion.Spring.quick
            case .selection: return MaterialMotion.Spring.standard
            case .focus: return MaterialMotion.Easing.standard
            case .modal: return MaterialMotion.Glass.modalPresent
            }
        }
        
        var transform: (Bool) -> (scale: CGFloat, opacity: Double) {
            switch self {
            case .appear:
                return { active in (scale: active ? 1.0 : 0.95, opacity: active ? 1.0 : 0.0) }
            case .press:
                return { active in (scale: active ? 0.98 : 1.0, opacity: active ? 0.9 : 1.0) }
            case .selection:
                return { active in (scale: active ? 1.02 : 1.0, opacity: 1.0) }
            case .focus:
                return { active in (scale: active ? 1.01 : 1.0, opacity: 1.0) }
            case .modal:
                return { active in (scale: active ? 1.0 : 0.9, opacity: active ? 1.0 : 0.0) }
            }
        }
    }
    
    func body(content: Content) -> some View {
        let transform = motionType.transform(isActive)
        
        content
            .scaleEffect(transform.scale)
            .opacity(transform.opacity)
            .animation(motionType.animation, value: isActive)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass motion effects to any view
    func glassMotion(_ type: GlassMotionModifier.MotionType, isActive: Bool) -> some View {
        modifier(GlassMotionModifier(motionType: type, isActive: isActive))
    }
    
    /// Apply glass appearance animation
    func glassAppear(isVisible: Bool = true) -> some View {
        glassMotion(.appear, isActive: isVisible)
    }
    
    /// Apply glass press animation
    func glassPress(isPressed: Bool) -> some View {
        glassMotion(.press, isActive: isPressed)
    }
    
    /// Apply glass selection animation
    func glassSelection(isSelected: Bool) -> some View {
        glassMotion(.selection, isActive: isSelected)
    }
    
    /// Apply glass focus animation
    func glassFocus(isFocused: Bool) -> some View {
        glassMotion(.focus, isActive: isFocused)
    }
    
    /// Apply glass modal animation
    func glassModal(isPresented: Bool) -> some View {
        glassMotion(.modal, isActive: isPresented)
    }
}

// MARK: - Haptic Feedback Integration

/// Haptic feedback patterns that complement Material Glass animations
struct MaterialHaptics {
    /// Light haptic for subtle interactions
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium haptic for standard interactions
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy haptic for important interactions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Selection haptic for tab/option selection
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Success haptic for completed actions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning haptic for cautionary actions
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error haptic for failed actions
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Animation Utilities

extension Animation {
    /// Create a custom glass animation with specified parameters
    static func glass(
        response: Double = 0.6,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
    }
    
    /// Create a custom eased animation with specified duration
    static func eased(duration: TimeInterval) -> Animation {
        .easeInOut(duration: duration)
    }
}