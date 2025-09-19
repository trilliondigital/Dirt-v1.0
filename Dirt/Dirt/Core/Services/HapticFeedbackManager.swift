import UIKit
import SwiftUI
import Combine

class HapticFeedbackManager: ObservableObject {
    static let shared = HapticFeedbackManager()
    
    @Published var isEnabled: Bool = true
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators for better performance
        prepareGenerators()
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Public Methods
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        case .rigid:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
    }
    
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Convenience Methods
    
    func buttonTap() {
        impact(.light)
    }
    
    func cardTap() {
        impact(.light)
    }
    
    func swipeAction() {
        impact(.medium)
    }
    
    func pullToRefresh() {
        impact(.medium)
    }
    
    func likeAction() {
        impact(.light)
    }
    
    func saveAction() {
        impact(.light)
    }
    
    func errorOccurred() {
        notification(.error)
    }
    
    func successAction() {
        notification(.success)
    }
    
    func warningAction() {
        notification(.warning)
    }
    
    func filterSelection() {
        selection()
    }
}

// MARK: - SwiftUI Integration

struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        HapticFeedbackManager.shared.impact(style)
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        HapticFeedbackManager.shared.notification(type)
    }
    
    static func selection() {
        HapticFeedbackManager.shared.selection()
    }
    
    static func buttonTap() {
        HapticFeedbackManager.shared.buttonTap()
    }
    
    static func cardTap() {
        HapticFeedbackManager.shared.cardTap()
    }
    
    static func swipeAction() {
        HapticFeedbackManager.shared.swipeAction()
    }
    
    static func pullToRefresh() {
        HapticFeedbackManager.shared.pullToRefresh()
    }
    
    static func likeAction() {
        HapticFeedbackManager.shared.likeAction()
    }
    
    static func saveAction() {
        HapticFeedbackManager.shared.saveAction()
    }
    
    static func errorOccurred() {
        HapticFeedbackManager.shared.errorOccurred()
    }
    
    static func successAction() {
        HapticFeedbackManager.shared.successAction()
    }
    
    static func warningAction() {
        HapticFeedbackManager.shared.warningAction()
    }
    
    static func filterSelection() {
        HapticFeedbackManager.shared.filterSelection()
    }
}

// MARK: - View Modifier

struct HapticFeedbackModifier: ViewModifier {
    let feedbackType: HapticFeedbackType
    
    enum HapticFeedbackType {
        case buttonTap
        case cardTap
        case swipeAction
        case selection
        case success
        case error
        case warning
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                switch feedbackType {
                case .buttonTap:
                    HapticFeedback.buttonTap()
                case .cardTap:
                    HapticFeedback.cardTap()
                case .swipeAction:
                    HapticFeedback.swipeAction()
                case .selection:
                    HapticFeedback.selection()
                case .success:
                    HapticFeedback.successAction()
                case .error:
                    HapticFeedback.errorOccurred()
                case .warning:
                    HapticFeedback.warningAction()
                }
            }
    }
}

extension View {
    func hapticFeedback(_ type: HapticFeedbackModifier.HapticFeedbackType) -> some View {
        modifier(HapticFeedbackModifier(feedbackType: type))
    }
}