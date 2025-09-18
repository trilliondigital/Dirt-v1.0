import SwiftUI

// MARK: - Glass Card Component

/// A reusable card component with Material Glass background
struct GlassCard<Content: View>: View {
    let content: Content
    let material: Material
    let cornerRadius: CGFloat
    let padding: CGFloat
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let isInteractive: Bool
    
    @StateObject private var performanceService = PerformanceOptimizationService.shared
    @FocusState private var isFocused: Bool
    
    init(
        material: Material = MaterialDesignSystem.Context.card,
        cornerRadius: CGFloat = UICornerRadius.lg,
        padding: CGFloat = UISpacing.md,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isInteractive = isInteractive
    }
    
    var body: some View {
        content
            .padding(AccessibilitySystem.DynamicType.scaledSpacing(padding))
            .performanceOptimizedGlass(
                material: material,
                cornerRadius: cornerRadius,
                shadowRadius: 8
            )
            .focused($isFocused)
            .glassFocusRing(isFocused: isFocused && isInteractive, cornerRadius: cornerRadius)
            .glassAccessible(
                label: accessibilityLabel ?? "Card",
                hint: accessibilityHint,
                traits: isInteractive ? .isButton : .isStaticText,
                isButton: isInteractive,
                minimumTouchTarget: isInteractive
            )
            .glassHighContrast()
    }
}

// MARK: - Glass Button Component

/// A Material Glass button with haptic feedback and animations
struct GlassButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let style: ButtonStyle
    let material: Material
    let cornerRadius: CGFloat
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @State private var isPressed = false
    @FocusState private var isFocused: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case subtle
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return UIColors.accentPrimary
            case .destructive: return .white
            case .subtle: return UIColors.label
            }
        }
        
        var material: Material {
            switch self {
            case .primary: return MaterialDesignSystem.Glass.regular
            case .secondary: return MaterialDesignSystem.Glass.thin
            case .destructive: return MaterialDesignSystem.Glass.regular
            case .subtle: return MaterialDesignSystem.Glass.ultraThin
            }
        }
        
        var overlay: Color? {
            switch self {
            case .primary: return MaterialDesignSystem.GlassColors.primary
            case .secondary: return nil
            case .destructive: return MaterialDesignSystem.GlassColors.danger
            case .subtle: return nil
            }
        }
    }
    
    init(
        _ title: String,
        systemImage: String? = nil,
        style: ButtonStyle = .primary,
        material: Material? = nil,
        cornerRadius: CGFloat = UICornerRadius.md,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.style = style
        self.material = material ?? style.material
        self.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback (respecting accessibility settings)
            if !UIAccessibility.isReduceMotionEnabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            action()
        }) {
            HStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.xs)) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .medium))
                        .foregroundColor(style.foregroundColor)
                }
                
                Text(title)
                    .font(AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .medium))
                    .foregroundColor(style.foregroundColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.md))
            .padding(.vertical, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
            .accessibleTouchTarget() // Ensure minimum 44x44 touch target
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .performanceOptimizedGlass(material: material, cornerRadius: cornerRadius, shadowRadius: isPressed ? 4 : 6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .overlay(
            // Add color overlay for primary and destructive styles
            Group {
                if let overlay = style.overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(overlay)
                }
            }
        )
        .glassFocusRing(isFocused: isFocused, cornerRadius: cornerRadius)
        .glassAccessible(
            label: accessibilityLabel ?? title,
            hint: accessibilityHint ?? AccessibilitySystem.VoiceOver.hint(for: "activate"),
            traits: .isButton,
            isButton: true
        )
        .glassHighContrast()
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            let duration = PerformanceOptimizationService.shared.optimizedAnimationDuration(for: 0.1)
            let animation = AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: duration))
            withAnimation(animation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Glass Navigation Bar

/// A Material Glass navigation bar component
struct GlassNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing
    let accessibilityLabel: String?
    
    init(
        title: String,
        accessibilityLabel: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            leading
                .accessibleTouchTarget()
            
            Spacer()
            
            Text(title)
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 17, weight: .semibold))
                .foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(accessibilityLabel ?? title)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Spacer()
            
            trailing
                .accessibleTouchTarget()
        }
        .padding(.horizontal, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.md))
        .padding(.vertical, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
        .frame(minHeight: AccessibilitySystem.TouchTarget.minimum.height)
        .background(MaterialDesignSystem.Context.navigation, in: Rectangle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MaterialDesignSystem.GlassBorders.subtle)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
        .accessibilityElement(children: .contain)
        .glassHighContrast()
    }
}

// MARK: - Glass Tab Bar

/// A Material Glass tab bar component
struct GlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    struct TabItem {
        let title: String
        let systemImage: String
        let selectedSystemImage: String?
        let accessibilityLabel: String?
        let accessibilityHint: String?
        
        init(
            title: String, 
            systemImage: String, 
            selectedSystemImage: String? = nil,
            accessibilityLabel: String? = nil,
            accessibilityHint: String? = nil
        ) {
            self.title = title
            self.systemImage = systemImage
            self.selectedSystemImage = selectedSystemImage
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityHint = accessibilityHint
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    let animation = AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.2))
                    withAnimation(animation) {
                        selectedTab = index
                    }
                    
                    // Haptic feedback (respecting accessibility settings)
                    if !UIAccessibility.isReduceMotionEnabled {
                        let selectionFeedback = UISelectionFeedbackGenerator()
                        selectionFeedback.selectionChanged()
                    }
                    
                    // Announce selection to VoiceOver
                    UIAccessibility.post(notification: .screenChanged, argument: "\(tab.title) selected")
                }) {
                    VStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.xxs)) {
                        Image(systemName: selectedTab == index ? (tab.selectedSystemImage ?? tab.systemImage) : tab.systemImage)
                            .font(AccessibilitySystem.DynamicType.scaledFont(
                                size: 20, 
                                weight: selectedTab == index ? .semibold : .medium
                            ))
                            .foregroundColor(selectedTab == index ? 
                                AccessibilitySystem.AccessibleColors.accessibleBlue : 
                                AccessibilitySystem.AccessibleColors.secondaryText
                            )
                        
                        Text(tab.title)
                            .font(AccessibilitySystem.DynamicType.scaledFont(size: 10, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? 
                                AccessibilitySystem.AccessibleColors.accessibleBlue : 
                                AccessibilitySystem.AccessibleColors.secondaryText
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.xs))
                    .accessibleTouchTarget()
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(tab.accessibilityLabel ?? tab.title)
                .accessibilityHint(tab.accessibilityHint ?? "Tab \(index + 1) of \(tabs.count)")
                .accessibilityAddTraits(selectedTab == index ? [.isButton, .isSelected] : .isButton)
                .accessibilityValue(selectedTab == index ? "Selected" : "")
            }
        }
        .padding(.horizontal, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
        .padding(.top, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.xs))
        .padding(.bottom, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
        .frame(minHeight: AccessibilitySystem.TouchTarget.minimum.height)
        .background(MaterialDesignSystem.Context.tabBar, in: Rectangle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MaterialDesignSystem.GlassBorders.subtle)
                .frame(maxHeight: .infinity, alignment: .top)
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
        .glassHighContrast()
    }
}

// MARK: - Glass Modal Container

/// A Material Glass modal container with backdrop
struct GlassModal<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    let cornerRadius: CGFloat
    let accessibilityLabel: String?
    let isDismissible: Bool
    
    init(
        isPresented: Binding<Bool>,
        cornerRadius: CGFloat = UICornerRadius.xl,
        accessibilityLabel: String? = nil,
        isDismissible: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content()
        self.cornerRadius = cornerRadius
        self.accessibilityLabel = accessibilityLabel
        self.isDismissible = isDismissible
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .accessibilityLabel("Modal backdrop")
                .accessibilityHint(isDismissible ? "Double tap to dismiss modal" : "")
                .accessibilityAddTraits(isDismissible ? .isButton : [])
                .onTapGesture {
                    if isDismissible {
                        let animation = AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.3))
                        withAnimation(animation) {
                            isPresented = false
                        }
                    }
                }
            
            // Modal content
            content
                .padding(AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.lg))
                .background(MaterialDesignSystem.Context.modal, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                )
                .shadow(color: MaterialDesignSystem.GlassShadows.strong, radius: 20, x: 0, y: 10)
                .padding(AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.lg))
                .scaleEffect(isPresented ? 1.0 : 0.9)
                .opacity(isPresented ? 1.0 : 0.0)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(accessibilityLabel ?? "Modal")
                .accessibilityAddTraits(.isModal)
                .glassHighContrast()
        }
        .animation(
            AccessibilitySystem.ReducedMotion.animation(.spring(response: 0.6, dampingFraction: 0.8)),
            value: isPresented
        )
        .onAppear {
            if isPresented {
                // Announce modal appearance to VoiceOver
                UIAccessibility.post(notification: .screenChanged, argument: accessibilityLabel ?? "Modal opened")
            }
        }
        .onDisappear {
            if !isPresented {
                // Announce modal dismissal to VoiceOver
                UIAccessibility.post(notification: .screenChanged, argument: "Modal closed")
            }
        }
    }
}

// MARK: - Glass Toast Notification

/// A Material Glass toast notification component with enhanced error handling support
struct GlassToast: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let onDismiss: (() -> Void)?
    let isDismissible: Bool
    
    @State private var isVisible = false
    @State private var dismissTimer: Timer?
    
    enum ToastType: String, CaseIterable {
        case success = "Success"
        case warning = "Warning"
        case error = "Error"
        case info = "Information"
        
        var systemImage: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return UIColors.success
            case .warning: return UIColors.warning
            case .error: return UIColors.danger
            case .info: return UIColors.accentPrimary
            }
        }
        
        var glassOverlay: Color {
            switch self {
            case .success: return MaterialDesignSystem.GlassColors.success
            case .warning: return MaterialDesignSystem.GlassColors.warning
            case .error: return MaterialDesignSystem.GlassColors.danger
            case .info: return MaterialDesignSystem.GlassColors.primary
            }
        }
        
        var defaultDuration: TimeInterval {
            switch self {
            case .success: return 3.0
            case .warning: return 5.0
            case .error: return 6.0
            case .info: return 4.0
            }
        }
        
        var hapticFeedback: UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            case .info: return nil
            }
        }
    }
    
    init(
        message: String, 
        type: ToastType = .info,
        duration: TimeInterval? = nil,
        isDismissible: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.type = type
        self.duration = duration ?? type.defaultDuration
        self.isDismissible = isDismissible
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm)) {
            Image(systemName: type.systemImage)
                .foregroundColor(type.color)
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .semibold))
                .accessibilityHidden(true) // Icon is decorative, message provides context
            
            Text(message)
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 14, weight: .medium))
                .foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(nil) // Allow full message for accessibility
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
            
            if isDismissible {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(AccessibilitySystem.DynamicType.scaledFont(size: 12, weight: .semibold))
                        .foregroundColor(AccessibilitySystem.AccessibleColors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Dismiss notification")
                .accessibilityHint("Double tap to dismiss this notification")
                .accessibleTouchTarget()
            }
        }
        .padding(AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.md))
        .background(MaterialDesignSystem.Glass.regular, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .fill(type.glassOverlay)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
        )
        .shadow(color: MaterialDesignSystem.GlassShadows.medium, radius: 12, x: 0, y: 6)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.rawValue) notification: \(message)")
        .accessibilityAddTraits(.playsSound)
        .accessibilityAction(.dismiss) {
            if isDismissible {
                dismiss()
            }
        }
        .glassHighContrast()
        .onAppear {
            // Trigger haptic feedback (respecting accessibility settings)
            if let hapticType = type.hapticFeedback, !UIAccessibility.isReduceMotionEnabled {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(hapticType)
            }
            
            // Announce to VoiceOver
            let announcement = "\(type.rawValue) notification: \(message)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
            
            // Animate appearance
            let animation = AccessibilitySystem.ReducedMotion.animation(MaterialMotion.Glass.toastAppear)
            withAnimation(animation) {
                isVisible = true
            }
            
            // Set up auto-dismiss timer
            if duration > 0 {
                dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                    dismiss()
                }
            }
        }
        .onDisappear {
            dismissTimer?.invalidate()
        }
        .onTapGesture {
            if isDismissible {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        dismissTimer?.invalidate()
        
        withAnimation(MaterialMotion.Glass.toastAppear) {
            isVisible = false
        }
        
        // Call onDismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Glass Search Bar

/// A Material Glass search bar component
struct GlassSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    var body: some View {
        HStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm)) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AccessibilitySystem.AccessibleColors.secondaryText)
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .medium))
                .accessibilityHidden(true) // Decorative icon
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 16))
                .foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)
                .accessibilityLabel(accessibilityLabel ?? "Search field")
                .accessibilityHint(accessibilityHint ?? "Enter text to search")
                .accessibilityAddTraits(.isSearchField)
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    // Announce text cleared to VoiceOver
                    UIAccessibility.post(notification: .announcement, argument: "Search text cleared")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AccessibilitySystem.AccessibleColors.secondaryText)
                        .font(AccessibilitySystem.DynamicType.scaledFont(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Clear search")
                .accessibilityHint("Double tap to clear search text")
                .accessibleTouchTarget()
            }
        }
        .padding(.horizontal, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.md))
        .padding(.vertical, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
        .accessibleTouchTarget()
        .background(MaterialDesignSystem.Glass.thin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .stroke(
                    isFocused ? AccessibilitySystem.AccessibleColors.focusRing : MaterialDesignSystem.GlassBorders.subtle,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .glassFocusRing(isFocused: isFocused, cornerRadius: UICornerRadius.md)
        .glassHighContrast()
        .animation(
            AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.2)),
            value: isFocused
        )
    }
}