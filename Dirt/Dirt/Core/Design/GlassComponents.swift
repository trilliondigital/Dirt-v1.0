import SwiftUI

// MARK: - Glass Card Component

/// A reusable card component with Material Glass background
struct GlassCard<Content: View>: View {
    let content: Content
    let material: Material
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(
        material: Material = MaterialDesignSystem.Context.card,
        cornerRadius: CGFloat = UICornerRadius.lg,
        padding: CGFloat = UISpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassCard(material: material, cornerRadius: cornerRadius)
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
    
    @State private var isPressed = false
    
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
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.style = style
        self.material = material ?? style.material
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: UISpacing.xs) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, UISpacing.md)
            .padding(.vertical, UISpacing.sm)
            .frame(minHeight: 44) // Accessibility minimum touch target
        }
        .buttonStyle(PlainButtonStyle())
        .glassButton(material: material, cornerRadius: cornerRadius, isPressed: isPressed)
        .overlay(
            // Add color overlay for primary and destructive styles
            Group {
                if let overlay = style.overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(overlay)
                }
            }
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
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
    
    init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            leading
                .frame(width: 44, height: 44)
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(UIColors.label)
            
            Spacer()
            
            trailing
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, UISpacing.md)
        .padding(.vertical, UISpacing.sm)
        .background(MaterialDesignSystem.Context.navigation, in: Rectangle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MaterialDesignSystem.GlassBorders.subtle)
                .frame(maxHeight: .infinity, alignment: .bottom)
        )
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
        
        init(title: String, systemImage: String, selectedSystemImage: String? = nil) {
            self.title = title
            self.systemImage = systemImage
            self.selectedSystemImage = selectedSystemImage
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                    
                    // Haptic feedback
                    let selectionFeedback = UISelectionFeedbackGenerator()
                    selectionFeedback.selectionChanged()
                }) {
                    VStack(spacing: UISpacing.xxs) {
                        Image(systemName: selectedTab == index ? (tab.selectedSystemImage ?? tab.systemImage) : tab.systemImage)
                            .font(.system(size: 20, weight: selectedTab == index ? .semibold : .medium))
                            .foregroundColor(selectedTab == index ? UIColors.accentPrimary : UIColors.secondaryLabel)
                        
                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundColor(selectedTab == index ? UIColors.accentPrimary : UIColors.secondaryLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UISpacing.xs)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, UISpacing.sm)
        .padding(.top, UISpacing.xs)
        .padding(.bottom, UISpacing.sm)
        .background(MaterialDesignSystem.Context.tabBar, in: Rectangle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MaterialDesignSystem.GlassBorders.subtle)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }
}

// MARK: - Glass Modal Container

/// A Material Glass modal container with backdrop
struct GlassModal<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    let cornerRadius: CGFloat
    
    init(
        isPresented: Binding<Bool>,
        cornerRadius: CGFloat = UICornerRadius.xl,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.content = content()
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Modal content
            content
                .padding(UISpacing.lg)
                .background(MaterialDesignSystem.Context.modal, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                )
                .shadow(color: MaterialDesignSystem.GlassShadows.strong, radius: 20, x: 0, y: 10)
                .padding(UISpacing.lg)
                .scaleEffect(isPresented ? 1.0 : 0.9)
                .opacity(isPresented ? 1.0 : 0.0)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Glass Toast Notification

/// A Material Glass toast notification component
struct GlassToast: View {
    let message: String
    let type: ToastType
    @State private var isVisible = false
    
    enum ToastType {
        case success
        case warning
        case error
        case info
        
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
    }
    
    init(message: String, type: ToastType = .info) {
        self.message = message
        self.type = type
    }
    
    var body: some View {
        HStack(spacing: UISpacing.sm) {
            Image(systemName: type.systemImage)
                .foregroundColor(type.color)
                .font(.system(size: 16, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(UIColors.label)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(UISpacing.md)
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Glass Search Bar

/// A Material Glass search bar component
struct GlassSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    var body: some View {
        HStack(spacing: UISpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(UIColors.secondaryLabel)
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .foregroundColor(UIColors.label)
                .onSubmit {
                    onSearchButtonClicked?()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(UIColors.secondaryLabel)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, UISpacing.md)
        .padding(.vertical, UISpacing.sm)
        .background(MaterialDesignSystem.Glass.thin, in: RoundedRectangle(cornerRadius: UICornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .stroke(
                    isFocused ? MaterialDesignSystem.GlassBorders.accent : MaterialDesignSystem.GlassBorders.subtle,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}