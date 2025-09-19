import SwiftUI

/// A customizable loading spinner with different sizes and styles
struct LoadingSpinner: View {
    
    // MARK: - Spinner Sizes
    enum SpinnerSize {
        case small
        case medium
        case large
        
        var diameter: CGFloat {
            switch self {
            case .small:
                return 16
            case .medium:
                return 24
            case .large:
                return 32
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small:
                return 2
            case .medium:
                return 3
            case .large:
                return 4
            }
        }
    }
    
    // MARK: - Spinner Styles
    enum SpinnerStyle {
        case circular
        case dots
        case pulse
        
        var animationDuration: Double {
            switch self {
            case .circular:
                return 1.0
            case .dots:
                return 1.2
            case .pulse:
                return 1.5
            }
        }
    }
    
    // MARK: - Properties
    let size: SpinnerSize
    let style: SpinnerStyle
    let color: Color
    
    @State private var isAnimating = false
    @Environment(\.animationPreferences) private var animationPreferences
    
    // MARK: - Initialization
    init(
        size: SpinnerSize = .medium,
        style: SpinnerStyle = .circular,
        color: Color = Color.adaptivePrimary
    ) {
        self.size = size
        self.style = style
        self.color = color
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch style {
            case .circular:
                circularSpinner
            case .dots:
                dotsSpinner
            case .pulse:
                pulseSpinner
            }
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - Circular Spinner
    private var circularSpinner: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: size.strokeWidth,
                    lineCap: .round
                )
            )
            .frame(width: size.diameter, height: size.diameter)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(
                .linear(duration: style.animationDuration)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
    }
    
    // MARK: - Dots Spinner
    private var dotsSpinner: some View {
        HStack(spacing: size.diameter * 0.2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size.diameter * 0.3, height: size.diameter * 0.3)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: style.animationDuration / 3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .frame(width: size.diameter, height: size.diameter * 0.3)
    }
    
    // MARK: - Pulse Spinner
    private var pulseSpinner: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: size.strokeWidth)
                    .frame(width: size.diameter, height: size.diameter)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 0.0 : 1.0)
                    .animation(
                        .easeInOut(duration: style.animationDuration)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }
            
            Circle()
                .fill(color)
                .frame(width: size.diameter * 0.3, height: size.diameter * 0.3)
        }
    }
    
    // MARK: - Methods
    private func startAnimation() {
        guard animationPreferences.animationsEnabled else { return }
        isAnimating = true
    }
    
    private func stopAnimation() {
        isAnimating = false
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    
    // MARK: - Progress Styles
    enum ProgressStyle {
        case linear
        case circular
        
        var height: CGFloat {
            switch self {
            case .linear:
                return 4
            case .circular:
                return 0 // Circular uses diameter instead
            }
        }
    }
    
    // MARK: - Properties
    let progress: Double // 0.0 to 1.0
    let style: ProgressStyle
    let size: LoadingSpinner.SpinnerSize
    let color: Color
    let backgroundColor: Color
    
    @Environment(\.animationPreferences) private var animationPreferences
    
    // MARK: - Initialization
    init(
        progress: Double,
        style: ProgressStyle = .linear,
        size: LoadingSpinner.SpinnerSize = .medium,
        color: Color = Color.adaptivePrimary,
        backgroundColor: Color = DesignTokens.Colors.tertiaryBackground
    ) {
        self.progress = max(0, min(1, progress))
        self.style = style
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch style {
            case .linear:
                linearProgress
            case .circular:
                circularProgress
            }
        }
    }
    
    // MARK: - Linear Progress
    private var linearProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: style.height / 2)
                    .fill(backgroundColor)
                    .frame(height: style.height)
                
                // Progress
                RoundedRectangle(cornerRadius: style.height / 2)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * progress,
                        height: style.height
                    )
                    .animation(animationPreferences.standardEasing, value: progress)
            }
        }
        .frame(height: style.height)
    }
    
    // MARK: - Circular Progress
    private var circularProgress: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(backgroundColor, lineWidth: size.strokeWidth)
                .frame(width: size.diameter, height: size.diameter)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: size.strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.diameter, height: size.diameter)
                .rotationEffect(.degrees(-90))
                .animation(animationPreferences.standardEasing, value: progress)
            
            // Progress Text (optional)
            if progress > 0 {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size.diameter * 0.25, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String?
    let isVisible: Bool
    
    @Environment(\.animationPreferences) private var animationPreferences
    
    init(message: String? = nil, isVisible: Bool = true) {
        self.message = message
        self.isVisible = isVisible
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background Overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                // Loading Content
                VStack(spacing: DesignTokens.Spacing.md) {
                    LoadingSpinner(size: .large)
                    
                    if let message = message {
                        Text(message)
                            .font(DesignTokens.Typography.callout)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(DesignTokens.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                        .fill(.regularMaterial)
                        .shadow(
                            color: DesignTokens.Shadow.large.color,
                            radius: DesignTokens.Shadow.large.radius,
                            x: DesignTokens.Shadow.large.x,
                            y: DesignTokens.Shadow.large.y
                        )
                )
            }
            .transition(animationPreferences.scaleTransition)
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Add a loading overlay to any view
    func loadingOverlay(
        message: String? = nil,
        isVisible: Bool
    ) -> some View {
        self.overlay(
            LoadingOverlay(message: message, isVisible: isVisible)
        )
    }
}

// MARK: - Preview
#Preview("Loading Components") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.xl) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Loading Spinners")
                    .font(DesignTokens.Typography.title2)
                
                HStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(size: .small, style: .circular)
                        Text("Small")
                            .font(DesignTokens.Typography.caption)
                    }
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(size: .medium, style: .circular)
                        Text("Medium")
                            .font(DesignTokens.Typography.caption)
                    }
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(size: .large, style: .circular)
                        Text("Large")
                            .font(DesignTokens.Typography.caption)
                    }
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Spinner Styles")
                    .font(DesignTokens.Typography.title2)
                
                HStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(style: .circular)
                        Text("Circular")
                            .font(DesignTokens.Typography.caption)
                    }
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(style: .dots)
                        Text("Dots")
                            .font(DesignTokens.Typography.caption)
                    }
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        LoadingSpinner(style: .pulse)
                        Text("Pulse")
                            .font(DesignTokens.Typography.caption)
                    }
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Progress Indicators")
                    .font(DesignTokens.Typography.title2)
                
                VStack(spacing: DesignTokens.Spacing.lg) {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("Linear Progress")
                            .font(DesignTokens.Typography.callout)
                        ProgressIndicator(progress: 0.7, style: .linear)
                            .frame(height: 4)
                    }
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("Circular Progress")
                            .font(DesignTokens.Typography.callout)
                        ProgressIndicator(progress: 0.65, style: .circular, size: .large)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(DesignTokens.Colors.background)
    .withAnimationPreferences()
}