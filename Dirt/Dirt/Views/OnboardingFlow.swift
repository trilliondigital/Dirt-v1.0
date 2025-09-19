import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedInterests: Set<InterestCategory> = []
    @State private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.adaptivePrimary.opacity(0.1),
                    DesignTokens.Colors.background,
                    Color.adaptiveSuccess.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep != .welcome {
                    OnboardingProgressView(currentStep: currentStep)
                        .padding(.top, DesignTokens.Spacing.md)
                        .transition(animationPreferences.slideTransition(from: .top))
                }
                
                // Main content
                TabView(selection: $currentStep) {
                    EnhancedWelcomeView(
                        onNext: { 
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .authentication
                            }
                        },
                        onSkip: {
                            // Check if user has completed onboarding before
                            if UserDefaults.standard.bool(forKey: "has_completed_onboarding") {
                                withAnimation(animationPreferences.standardSpring) {
                                    currentStep = .authentication
                                }
                            }
                        }
                    )
                    .tag(OnboardingStep.welcome)
                    
                    EnhancedAuthenticationView(
                        onNext: {
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .interests
                            }
                        },
                        onBack: {
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .welcome
                            }
                        }
                    )
                    .tag(OnboardingStep.authentication)
                    
                    InterestSelectionView(
                        selectedInterests: $selectedInterests,
                        onNext: {
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .guidelines
                            }
                        },
                        onBack: {
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .authentication
                            }
                        }
                    )
                    .tag(OnboardingStep.interests)
                    
                    CommunityGuidelinesView(
                        onComplete: {
                            // Mark onboarding as complete
                            UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                            // This will be handled by the parent view to transition to main app
                        },
                        onBack: {
                            withAnimation(animationPreferences.standardSpring) {
                                currentStep = .interests
                            }
                        }
                    )
                    .tag(OnboardingStep.guidelines)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(animationPreferences.standardSpring, value: currentStep)
            }
        }
        .onAppear {
            // Check if user has seen onboarding before
            hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_completed_onboarding")
        }
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case authentication = 1
    case interests = 2
    case guidelines = 3
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .authentication:
            return "Sign In"
        case .interests:
            return "Interests"
        case .guidelines:
            return "Guidelines"
        }
    }
    
    var progress: Double {
        return Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}

// MARK: - Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: OnboardingStep
    @Environment(\.animationPreferences) private var animationPreferences
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Step indicators
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? 
                              Color.adaptivePrimary : 
                              DesignTokens.Colors.border)
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(animationPreferences.standardSpring, value: currentStep)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignTokens.Colors.border)
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color.adaptivePrimary)
                        .frame(width: geometry.size.width * currentStep.progress, height: 2)
                        .animation(animationPreferences.standardEasing, value: currentStep)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}

// MARK: - Enhanced Welcome View
struct EnhancedWelcomeView: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var showContent = false
    @State private var currentFeatureIndex = 0
    
    private let features = [
        OnboardingFeature(
            icon: "heart.text.square",
            title: "Share Your Story",
            description: "Tell your dating experiences and help others learn from your journey"
        ),
        OnboardingFeature(
            icon: "person.2.circle",
            title: "Get Real Advice",
            description: "Connect with a supportive community that understands your experiences"
        ),
        OnboardingFeature(
            icon: "shield.checkered",
            title: "Stay Anonymous",
            description: "Share safely with privacy controls and anonymous posting options"
        )
    ]
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            // Hero section
            VStack(spacing: DesignTokens.Spacing.lg) {
                // App icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.adaptivePrimary, Color.adaptiveSuccess],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)
                    
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1.0 : 0.0)
                }
                .animation(animationPreferences.bouncySpring.delay(0.2), value: showContent)
                
                // Title and subtitle
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Welcome to Dirt")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(animationPreferences.standardEasing.delay(0.4), value: showContent)
                    
                    Text("The honest dating feedback community")
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(animationPreferences.standardEasing.delay(0.6), value: showContent)
                }
            }
            
            // Feature carousel
            VStack(spacing: DesignTokens.Spacing.lg) {
                TabView(selection: $currentFeatureIndex) {
                    ForEach(features.indices, id: \.self) { index in
                        FeatureCard(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 200)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 30)
                .animation(animationPreferences.standardEasing.delay(0.8), value: showContent)
                
                // Feature indicators
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(features.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentFeatureIndex ? 
                                  Color.adaptivePrimary : 
                                  DesignTokens.Colors.border)
                            .frame(width: 6, height: 6)
                            .animation(animationPreferences.quickEasing, value: currentFeatureIndex)
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(animationPreferences.standardEasing.delay(1.0), value: showContent)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: DesignTokens.Spacing.md) {
                ActionButton.primary(
                    "Get Started",
                    systemImage: "arrow.right",
                    size: .large
                ) {
                    animationPreferences.mediumHaptic()
                    onNext()
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(animationPreferences.standardEasing.delay(1.2), value: showContent)
                
                if UserDefaults.standard.bool(forKey: "has_completed_onboarding") {
                    ActionButton.ghost(
                        "Skip Introduction",
                        size: .medium
                    ) {
                        animationPreferences.lightHaptic()
                        onSkip()
                    }
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(animationPreferences.standardEasing.delay(1.4), value: showContent)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(DesignTokens.Spacing.lg)
        .onAppear {
            withAnimation {
                showContent = true
            }
            
            // Auto-advance feature carousel
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(animationPreferences.standardEasing) {
                    currentFeatureIndex = (currentFeatureIndex + 1) % features.count
                }
            }
        }
    }
}

// MARK: - Feature Models and Views
struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
}

struct FeatureCard: View {
    let feature: OnboardingFeature
    
    var body: some View {
        GlassCard.static(style: .card, padding: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: feature.icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color.adaptivePrimary)
                
                Text(feature.title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - Enhanced Authentication View
struct EnhancedAuthenticationView: View {
    let onNext: () -> Void
    let onBack: () -> Void
    
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var showContent = false
    @State private var selectedAuthMethod: AuthMethod? = nil
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Header
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Join the Community")
                    .font(DesignTokens.Typography.title1)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.2), value: showContent)
                
                Text("Choose how you'd like to participate in our dating feedback community")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.4), value: showContent)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            Spacer()
            
            // Authentication options
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Apple Sign In
                AuthOptionCard(
                    method: .apple,
                    isSelected: selectedAuthMethod == .apple,
                    isLoading: authService.isLoading && selectedAuthMethod == .apple,
                    onTap: {
                        selectedAuthMethod = .apple
                        animationPreferences.mediumHaptic()
                        Task {
                            await authService.signInWithApple()
                            if authService.isAuthenticated {
                                onNext()
                            }
                        }
                    }
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(x: showContent ? 0 : -50)
                .animation(animationPreferences.standardEasing.delay(0.6), value: showContent)
                
                // Anonymous option
                AuthOptionCard(
                    method: .anonymous,
                    isSelected: selectedAuthMethod == .anonymous,
                    isLoading: authService.isLoading && selectedAuthMethod == .anonymous,
                    onTap: {
                        selectedAuthMethod = .anonymous
                        animationPreferences.mediumHaptic()
                        Task {
                            await authService.signInAnonymously()
                            if authService.isAuthenticated {
                                onNext()
                            }
                        }
                    }
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(x: showContent ? 0 : 50)
                .animation(animationPreferences.standardEasing.delay(0.8), value: showContent)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            Spacer()
            
            // Privacy notice
            GlassCard.static(style: .overlay, padding: DesignTokens.Spacing.md) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(Color.adaptivePrimary)
                        Text("Privacy First")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                    }
                    
                    Text("We prioritize your privacy and never share personal information. Your dating experiences remain confidential.")
                        .font(DesignTokens.Typography.callout)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 30)
            .animation(animationPreferences.standardEasing.delay(1.0), value: showContent)
            
            // Navigation
            HStack {
                ActionButton.ghost(
                    "Back",
                    systemImage: "chevron.left",
                    size: .medium
                ) {
                    animationPreferences.lightHaptic()
                    onBack()
                }
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(animationPreferences.standardEasing.delay(1.2), value: showContent)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
        .disabled(authService.isLoading)
    }
}

// MARK: - Authentication Method
enum AuthMethod {
    case apple
    case anonymous
    
    var title: String {
        switch self {
        case .apple:
            return "Continue with Apple"
        case .anonymous:
            return "Continue Anonymously"
        }
    }
    
    var subtitle: String {
        switch self {
        case .apple:
            return "Full features with secure Apple authentication"
        case .anonymous:
            return "Limited features but complete privacy"
        }
    }
    
    var icon: String {
        switch self {
        case .apple:
            return "applelogo"
        case .anonymous:
            return "person.fill.questionmark"
        }
    }
    
    var benefits: [String] {
        switch self {
        case .apple:
            return [
                "Create and save posts",
                "Build reputation",
                "Access all features",
                "Secure authentication"
            ]
        case .anonymous:
            return [
                "Read all content",
                "Post anonymously",
                "Complete privacy",
                "No account required"
            ]
        }
    }
}

// MARK: - Auth Option Card
struct AuthOptionCard: View {
    let method: AuthMethod
    let isSelected: Bool
    let isLoading: Bool
    let onTap: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    
    var body: some View {
        GlassCard.interactive(
            style: .card,
            padding: DesignTokens.Spacing.lg,
            onTap: onTap
        ) {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(method == .apple ? Color.black : DesignTokens.Colors.secondaryBackground)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: method.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(method == .apple ? .white : DesignTokens.Colors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(method.title)
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text(method.subtitle)
                            .font(DesignTokens.Typography.callout)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        LoadingSpinner(size: .small)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(method.benefits, id: \.self) { benefit in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.adaptiveSuccess)
                                .font(.system(size: 12))
                            
                            Text(benefit)
                                .font(DesignTokens.Typography.callout)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(
                    isSelected ? Color.adaptivePrimary : Color.clear,
                    lineWidth: 2
                )
                .animation(animationPreferences.quickEasing, value: isSelected)
        )
    }
}

// MARK: - Interest Selection View
struct InterestSelectionView: View {
    @Binding var selectedInterests: Set<InterestCategory>
    let onNext: () -> Void
    let onBack: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var showContent = false
    
    private let interests = InterestCategory.allCases
    private let minSelections = 3
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Header
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("What interests you?")
                    .font(DesignTokens.Typography.title1)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.2), value: showContent)
                
                Text("Select at least \(minSelections) topics to personalize your experience")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.4), value: showContent)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // Interest grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: DesignTokens.Spacing.md) {
                    ForEach(Array(interests.enumerated()), id: \.element) { index, interest in
                        InterestChip(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest),
                            onTap: {
                                animationPreferences.selectionHaptic()
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(
                            animationPreferences.standardEasing.delay(0.6 + Double(index) * 0.1),
                            value: showContent
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
            
            Spacer()
            
            // Navigation
            HStack {
                ActionButton.ghost(
                    "Back",
                    systemImage: "chevron.left",
                    size: .medium
                ) {
                    animationPreferences.lightHaptic()
                    onBack()
                }
                
                Spacer()
                
                ActionButton.primary(
                    "Continue",
                    systemImage: "arrow.right",
                    size: .medium,
                    isDisabled: selectedInterests.count < minSelections
                ) {
                    animationPreferences.mediumHaptic()
                    onNext()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(animationPreferences.standardEasing.delay(1.0), value: showContent)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

// MARK: - Interest Categories
enum InterestCategory: String, CaseIterable {
    case dating = "Dating Tips"
    case relationships = "Relationships"
    case communication = "Communication"
    case selfImprovement = "Self Improvement"
    case mentalHealth = "Mental Health"
    case socialSkills = "Social Skills"
    case onlineDating = "Online Dating"
    case breakups = "Breakups"
    case redFlags = "Red Flags"
    case success = "Success Stories"
    
    var icon: String {
        switch self {
        case .dating:
            return "heart.circle"
        case .relationships:
            return "person.2.circle"
        case .communication:
            return "message.circle"
        case .selfImprovement:
            return "star.circle"
        case .mentalHealth:
            return "brain.head.profile"
        case .socialSkills:
            return "person.3.circle"
        case .onlineDating:
            return "iphone.circle"
        case .breakups:
            return "heart.slash.circle"
        case .redFlags:
            return "exclamationmark.triangle"
        case .success:
            return "trophy.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .dating:
            return .pink
        case .relationships:
            return Color.adaptivePrimary
        case .communication:
            return .blue
        case .selfImprovement:
            return .purple
        case .mentalHealth:
            return .green
        case .socialSkills:
            return .orange
        case .onlineDating:
            return .cyan
        case .breakups:
            return .red
        case .redFlags:
            return .yellow
        case .success:
            return Color.adaptiveSuccess
        }
    }
}

// MARK: - Interest Chip
struct InterestChip: View {
    let interest: InterestCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    
    var body: some View {
        GlassCard.interactive(
            style: .card,
            padding: DesignTokens.Spacing.md,
            onTap: onTap
        ) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: interest.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? .white : interest.color)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(animationPreferences.bouncySpring, value: isSelected)
                
                Text(interest.rawValue)
                    .font(DesignTokens.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(isSelected ? interest.color : Color.clear)
                .animation(animationPreferences.standardEasing, value: isSelected)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .stroke(
                    isSelected ? Color.clear : interest.color.opacity(0.3),
                    lineWidth: 1
                )
                .animation(animationPreferences.standardEasing, value: isSelected)
        )
    }
}

// MARK: - Community Guidelines View
struct CommunityGuidelinesView: View {
    let onComplete: () -> Void
    let onBack: () -> Void
    
    @Environment(\.animationPreferences) private var animationPreferences
    @State private var showContent = false
    @State private var hasAcceptedGuidelines = false
    
    private let guidelines = [
        GuidelineItem(
            icon: "heart.circle.fill",
            title: "Be Respectful",
            description: "Treat all community members with kindness and respect, regardless of their experiences."
        ),
        GuidelineItem(
            icon: "shield.checkered",
            title: "Protect Privacy",
            description: "Never share personal information about yourself or others. Keep all details anonymous."
        ),
        GuidelineItem(
            icon: "checkmark.circle.fill",
            title: "Stay Honest",
            description: "Share genuine experiences and advice. Authentic stories help everyone learn and grow."
        ),
        GuidelineItem(
            icon: "exclamationmark.triangle.fill",
            title: "Report Issues",
            description: "Help keep our community safe by reporting inappropriate content or behavior."
        )
    ]
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Header
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Community Guidelines")
                    .font(DesignTokens.Typography.title1)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.2), value: showContent)
                
                Text("Help us maintain a supportive and safe environment for everyone")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : -20)
                    .animation(animationPreferences.standardEasing.delay(0.4), value: showContent)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // Guidelines list
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(Array(guidelines.enumerated()), id: \.element.title) { index, guideline in
                        GuidelineCard(guideline: guideline)
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(x: showContent ? 0 : (index % 2 == 0 ? -50 : 50))
                            .animation(
                                animationPreferences.standardEasing.delay(0.6 + Double(index) * 0.2),
                                value: showContent
                            )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
            
            Spacer()
            
            // Acceptance checkbox
            GlassCard.interactive(
                style: .card,
                padding: DesignTokens.Spacing.md,
                onTap: {
                    animationPreferences.selectionHaptic()
                    hasAcceptedGuidelines.toggle()
                }
            ) {
                HStack {
                    Image(systemName: hasAcceptedGuidelines ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasAcceptedGuidelines ? Color.adaptivePrimary : DesignTokens.Colors.textSecondary)
                        .font(.system(size: 20))
                        .animation(animationPreferences.bouncySpring, value: hasAcceptedGuidelines)
                    
                    Text("I agree to follow these community guidelines")
                        .font(DesignTokens.Typography.callout)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(animationPreferences.standardEasing.delay(1.0), value: showContent)
            
            // Navigation
            HStack {
                ActionButton.ghost(
                    "Back",
                    systemImage: "chevron.left",
                    size: .medium
                ) {
                    animationPreferences.lightHaptic()
                    onBack()
                }
                
                Spacer()
                
                ActionButton.primary(
                    "Complete Setup",
                    systemImage: "checkmark",
                    size: .medium,
                    isDisabled: !hasAcceptedGuidelines
                ) {
                    animationPreferences.successHaptic()
                    onComplete()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(animationPreferences.standardEasing.delay(1.2), value: showContent)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
    }
}

// MARK: - Guideline Models and Views
struct GuidelineItem {
    let icon: String
    let title: String
    let description: String
}

struct GuidelineCard: View {
    let guideline: GuidelineItem
    
    var body: some View {
        GlassCard.static(style: .card, padding: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: guideline.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color.adaptivePrimary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(guideline.title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(guideline.description)
                        .font(DesignTokens.Typography.callout)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
    }
}