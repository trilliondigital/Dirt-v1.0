import UIKit
import SwiftUI

// MARK: - Legacy HapticFeedback Compatibility

enum HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let feedbackType: HapticFeedbackType
        switch style {
        case .light: feedbackType = .light
        case .medium: feedbackType = .medium
        case .heavy: feedbackType = .heavy
        case .soft: feedbackType = .soft
        case .rigid: feedbackType = .rigid
        @unknown default: feedbackType = .medium
        }
        EnhancedHapticFeedback.shared.trigger(feedbackType)
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let feedbackType: HapticFeedbackType
        switch type {
        case .success: feedbackType = .success
        case .warning: feedbackType = .warning
        case .error: feedbackType = .error
        @unknown default: feedbackType = .error
        }
        EnhancedHapticFeedback.shared.trigger(feedbackType)
    }
    
     // Compatibility aliases used across the app
     static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
         notify(type)
     }
     
     static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
         notify(type)
     }
}

// MARK: - Haptic Feedback Types

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
}

// MARK: - Enhanced Haptic Feedback Service

@MainActor
class EnhancedHapticFeedback: ObservableObject {
    static let shared = EnhancedHapticFeedback()
    
    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        prepareGenerators()
    }
    
    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        notification.prepare()
        selection.prepare()
    }
    
    func trigger(_ type: HapticFeedbackType) {
        guard isEnabled else { return }
        
        switch type {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        case .success:
            notification.notificationOccurred(.success)
        case .warning:
            notification.notificationOccurred(.warning)
        case .error:
            notification.notificationOccurred(.error)
        case .selection:
            selection.selectionChanged()
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        case .notification(let type):
            notification.notificationOccurred(type)
        }
    }
    
    // MARK: - Convenience Methods
    
    func buttonTap() {
        trigger(.light)
    }
    
    func cardTap() {
        trigger(.medium)
    }
    
    func swipeAction() {
        trigger(.medium)
    }
    
    func pullToRefresh() {
        trigger(.light)
    }
    
    func longPress() {
        trigger(.heavy)
    }
    
    func toggleSwitch() {
        trigger(.selection)
    }
    
    func actionSuccess() {
        trigger(.success)
    }
    
    func actionError() {
        trigger(.error)
    }
    
    func actionWarning() {
        trigger(.warning)
    }
    
    func tabSelection() {
        trigger(.selection)
    }
    
    func modalPresent() {
        trigger(.medium)
    }
    
    func modalDismiss() {
        trigger(.light)
    }
    
    func keyboardTap() {
        trigger(.light)
    }
    
    func scrollBoundary() {
        trigger(.light)
    }
    
    func dragStart() {
        trigger(.medium)
    }
    
    func dragEnd() {
        trigger(.light)
    }
    
    func contextMenu() {
        trigger(.heavy)
    }
}

// MARK: - SwiftUI View Modifiers

struct HapticFeedbackModifier: ViewModifier {
    let type: HapticFeedbackType
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                EnhancedHapticFeedback.shared.trigger(type)
            }
    }
}

struct ButtonHapticModifier: ViewModifier {
    let feedbackType: HapticFeedbackType
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        EnhancedHapticFeedback.shared.trigger(feedbackType)
                    }
            )
    }
}

extension View {
    func hapticFeedback(_ type: HapticFeedbackType, trigger: Bool) -> some View {
        modifier(HapticFeedbackModifier(type: type, trigger: trigger))
    }
    
    func buttonHaptic(_ type: HapticFeedbackType = .light) -> some View {
        modifier(ButtonHapticModifier(feedbackType: type))
    }
}

// MARK: - Haptic Button Component

struct HapticButton<Label: View>: View {
    let action: () -> Void
    let hapticType: HapticFeedbackType
    let label: Label
    
    init(
        hapticType: HapticFeedbackType = .light,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.hapticType = hapticType
        self.label = label()
    }
    
    var body: some View {
        Button(action: {
            EnhancedHapticFeedback.shared.trigger(hapticType)
            action()
        }) {
            label
        }
    }
}

// MARK: - Haptic Settings View

struct HapticSettingsView: View {
    @StateObject private var hapticService = EnhancedHapticFeedback.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Haptic Feedback")
                .font(.headline)
            
            Toggle("Enable Haptic Feedback", isOn: $hapticService.isEnabled)
                .onChange(of: hapticService.isEnabled) { enabled in
                    if enabled {
                        hapticService.trigger(.success)
                    }
                }
            
            if hapticService.isEnabled {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Test Haptic Feedback")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        HapticTestButton("Light", type: .light)
                        HapticTestButton("Medium", type: .medium)
                        HapticTestButton("Heavy", type: .heavy)
                        HapticTestButton("Success", type: .success)
                        HapticTestButton("Warning", type: .warning)
                        HapticTestButton("Error", type: .error)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct HapticTestButton: View {
    let title: String
    let type: HapticFeedbackType
    
    init(_ title: String, type: HapticFeedbackType) {
        self.title = title
        self.type = type
    }
    
    var body: some View {
        Button(action: {
            EnhancedHapticFeedback.shared.trigger(type)
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

// MARK: - Swipe Actions with Haptics

struct HapticSwipeActions<Content: View>: View {
    let content: Content
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    
    @State private var offset: CGFloat = 0
    @State private var hasTriggeredHaptic = false
    
    init(
        leadingActions: [SwipeAction] = [],
        trailingActions: [SwipeAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Leading actions
            if !leadingActions.isEmpty {
                HStack(spacing: 0) {
                    ForEach(leadingActions.indices, id: \.self) { index in
                        SwipeActionView(action: leadingActions[index])
                    }
                }
                .frame(width: max(0, offset))
                .clipped()
            }
            
            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.x
                            
                            if translation > 0 && !leadingActions.isEmpty {
                                offset = min(translation, CGFloat(leadingActions.count * 80))
                            } else if translation < 0 && !trailingActions.isEmpty {
                                offset = max(translation, -CGFloat(trailingActions.count * 80))
                            }
                            
                            // Trigger haptic at threshold
                            let threshold: CGFloat = 80
                            if abs(offset) >= threshold && !hasTriggeredHaptic {
                                EnhancedHapticFeedback.shared.trigger(.medium)
                                hasTriggeredHaptic = true
                            } else if abs(offset) < threshold {
                                hasTriggeredHaptic = false
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if abs(offset) >= 80 {
                                    // Execute action
                                    if offset > 0 && !leadingActions.isEmpty {
                                        leadingActions[0].action()
                                        EnhancedHapticFeedback.shared.trigger(.success)
                                    } else if offset < 0 && !trailingActions.isEmpty {
                                        trailingActions[0].action()
                                        EnhancedHapticFeedback.shared.trigger(.success)
                                    }
                                }
                                offset = 0
                                hasTriggeredHaptic = false
                            }
                        }
                )
            
            // Trailing actions
            if !trailingActions.isEmpty {
                HStack(spacing: 0) {
                    ForEach(trailingActions.indices, id: \.self) { index in
                        SwipeActionView(action: trailingActions[index])
                    }
                }
                .frame(width: max(0, -offset))
                .clipped()
            }
        }
    }
}

struct SwipeAction {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
}

struct SwipeActionView: View {
    let action: SwipeAction
    
    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(.title3)
                
                Text(action.title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .background(action.color)
        }
    }
}

// MARK: - Context Menu with Haptics

struct HapticContextMenu<Content: View, Preview: View>: View {
    let content: Content
    let preview: Preview?
    let actions: [ContextMenuAction]
    
    init(
        actions: [ContextMenuAction],
        @ViewBuilder content: () -> Content,
        @ViewBuilder preview: () -> Preview
    ) {
        self.actions = actions
        self.content = content()
        self.preview = preview()
    }
    
    init(
        actions: [ContextMenuAction],
        @ViewBuilder content: () -> Content
    ) where Preview == EmptyView {
        self.actions = actions
        self.content = content()
        self.preview = nil
    }
    
    var body: some View {
        content
            .contextMenu {
                ForEach(actions.indices, id: \.self) { index in
                    Button(action: {
                        EnhancedHapticFeedback.shared.trigger(.light)
                        actions[index].action()
                    }) {
                        Label(actions[index].title, systemImage: actions[index].systemImage)
                    }
                }
            } preview: {
                preview
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                EnhancedHapticFeedback.shared.contextMenu()
            }
    }
}

struct ContextMenuAction {
    let title: String
    let systemImage: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(title: String, systemImage: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.action = action
    }
}
