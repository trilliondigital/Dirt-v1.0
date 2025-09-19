import SwiftUI
import UIKit
import Combine

/// Animation preferences and utilities for consistent motion design throughout the app
@MainActor
class AnimationPreferences: ObservableObject {
    
    // MARK: - Animation Settings
    @Published var animationsEnabled: Bool {
        didSet {
            saveAnimationPreference()
        }
    }
    
    @Published var reducedMotion: Bool {
        didSet {
            updateAnimationDurations()
        }
    }
    
    @Published var hapticsEnabled: Bool {
        didSet {
            saveHapticsPreference()
        }
    }
    
    // MARK: - Dynamic Animation Durations
    @Published var quickDuration: Double = DesignTokens.Animation.quick
    @Published var standardDuration: Double = DesignTokens.Animation.standard
    @Published var slowDuration: Double = DesignTokens.Animation.slow
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let animationsKey = "animations_enabled"
    private let hapticsKey = "haptics_enabled"
    
    // MARK: - Initialization
    init() {
        // Load saved preferences
        self.animationsEnabled = userDefaults.bool(forKey: animationsKey)
        self.hapticsEnabled = userDefaults.bool(forKey: hapticsKey)
        
        // Check system reduced motion setting
        self.reducedMotion = UIAccessibility.isReduceMotionEnabled
        
        // Set default values if first launch
        if !userDefaults.bool(forKey: "has_launched_before") {
            self.animationsEnabled = true
            self.hapticsEnabled = true
            userDefaults.set(true, forKey: "has_launched_before")
        }
        
        updateAnimationDurations()
        setupAccessibilityNotifications()
    }
    
    // MARK: - Animation Factories
    
    /// Standard easing animation
    var standardEasing: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .easeInOut(duration: standardDuration)
    }
    
    /// Quick easing animation for immediate feedback
    var quickEasing: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .easeInOut(duration: quickDuration)
    }
    
    /// Slow easing animation for dramatic effects
    var slowEasing: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .easeInOut(duration: slowDuration)
    }
    
    /// Spring animation with consistent parameters
    var standardSpring: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .spring(
            response: DesignTokens.Animation.springResponse,
            dampingFraction: DesignTokens.Animation.springDamping
        )
    }
    
    /// Bouncy spring animation for playful interactions
    var bouncySpring: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .spring(
            response: DesignTokens.Animation.springResponse * 0.8,
            dampingFraction: DesignTokens.Animation.springDamping * 0.7
        )
    }
    
    /// Gentle spring animation for subtle effects
    var gentleSpring: Animation {
        guard animationsEnabled && !reducedMotion else { return .easeInOut(duration: 0) }
        return .spring(
            response: DesignTokens.Animation.springResponse * 1.2,
            dampingFraction: DesignTokens.Animation.springDamping * 1.1
        )
    }
    
    // MARK: - Transition Factories
    
    /// Slide transition with direction
    func slideTransition(from edge: Edge) -> AnyTransition {
        guard animationsEnabled && !reducedMotion else { return .identity }
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge.opposite).combined(with: .opacity)
        )
    }
    
    /// Scale transition with fade
    var scaleTransition: AnyTransition {
        guard animationsEnabled && !reducedMotion else { return .identity }
        return .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    /// Push transition for navigation
    var pushTransition: AnyTransition {
        guard animationsEnabled && !reducedMotion else { return .identity }
        return .asymmetric(
            insertion: slideTransition(from: .trailing),
            removal: slideTransition(from: .leading)
        )
    }
    
    /// Modal presentation transition
    var modalTransition: AnyTransition {
        guard animationsEnabled && !reducedMotion else { return .identity }
        return .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    // MARK: - Haptic Feedback
    
    /// Trigger light haptic feedback
    func lightHaptic() {
        guard hapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Trigger medium haptic feedback
    func mediumHaptic() {
        guard hapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Trigger heavy haptic feedback
    func heavyHaptic() {
        guard hapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    /// Trigger success haptic feedback
    func successHaptic() {
        guard hapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Trigger warning haptic feedback
    func warningHaptic() {
        guard hapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Trigger error haptic feedback
    func errorHaptic() {
        guard hapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Trigger selection haptic feedback
    func selectionHaptic() {
        guard hapticsEnabled else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Public Methods
    
    /// Toggle animations on/off
    func toggleAnimations() {
        animationsEnabled.toggle()
    }
    
    /// Toggle haptics on/off
    func toggleHaptics() {
        hapticsEnabled.toggle()
    }
    
    // MARK: - Private Methods
    
    private func saveAnimationPreference() {
        userDefaults.set(animationsEnabled, forKey: animationsKey)
    }
    
    private func saveHapticsPreference() {
        userDefaults.set(hapticsEnabled, forKey: hapticsKey)
    }
    
    private func updateAnimationDurations() {
        if reducedMotion {
            quickDuration = DesignTokens.Animation.quick * 0.5
            standardDuration = DesignTokens.Animation.standard * 0.5
            slowDuration = DesignTokens.Animation.slow * 0.5
        } else {
            quickDuration = DesignTokens.Animation.quick
            standardDuration = DesignTokens.Animation.standard
            slowDuration = DesignTokens.Animation.slow
        }
    }
    
    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reducedMotion = UIAccessibility.isReduceMotionEnabled
            }
        }
    }
}

// MARK: - Edge Extension
extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

// MARK: - Animation Environment Key
struct AnimationPreferencesEnvironmentKey: EnvironmentKey {
    static let defaultValue = AnimationPreferences()
}

extension EnvironmentValues {
    var animationPreferences: AnimationPreferences {
        get { self[AnimationPreferencesEnvironmentKey.self] }
        set { self[AnimationPreferencesEnvironmentKey.self] = newValue }
    }
}

// MARK: - Animation Modifier
struct AnimationPreferencesModifier: ViewModifier {
    @StateObject private var animationPreferences = AnimationPreferences()
    
    func body(content: Content) -> some View {
        content
            .environment(\.animationPreferences, animationPreferences)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply animation preferences to the view hierarchy
    func withAnimationPreferences() -> some View {
        self.modifier(AnimationPreferencesModifier())
    }
    
    /// Animate with standard easing
    func animateWithStandardEasing<V: Equatable>(
        _ value: V,
        _ animationPreferences: AnimationPreferences
    ) -> some View {
        self.animation(animationPreferences.standardEasing, value: value)
    }
    
    /// Animate with quick easing
    func animateWithQuickEasing<V: Equatable>(
        _ value: V,
        _ animationPreferences: AnimationPreferences
    ) -> some View {
        self.animation(animationPreferences.quickEasing, value: value)
    }
    
    /// Animate with spring
    func animateWithSpring<V: Equatable>(
        _ value: V,
        _ animationPreferences: AnimationPreferences
    ) -> some View {
        self.animation(animationPreferences.standardSpring, value: value)
    }
}