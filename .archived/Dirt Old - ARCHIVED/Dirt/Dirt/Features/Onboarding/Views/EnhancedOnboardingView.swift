import SwiftUI
import AuthenticationServices

struct EnhancedOnboardingView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.services) private var services
    @StateObject private var phoneVerificationService = PhoneVerificationService.shared
    @StateObject private var ageVerificationService = AgeVerificationService.shared
    @StateObject private var usernameService = AnonymousUsernameService.shared
    
    @State private var currentPage = 0
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var birthDate = Date()
    @State private var hasAcceptedGuidelines = false
    @State private var generatedUsername: String = ""
    @State private var selectedInterests: Set<ControlledTag> = []
    @State private var showDone = false
    @State private var isPhoneVerified = false
    @State private var showingAgeError = false
    
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var onComplete: (() -> Void)?
    
    private let totalPages = 6

    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentPage + 1), total: Double(totalPages))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                TabView(selection: $currentPage) {
                    welcomeView.tag(0)
                    phoneVerificationView.tag(1)
                    codeVerificationView.tag(2)
                    ageVerificationView.tag(3)
                    guidelinesView.tag(4)
                    usernameGenerationView.tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                navigationButtons
            }
            .navigationTitle("Welcome to Dirt")
            .navigationBarTitleDisplayMode(.inline)
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
            .alert("Age Requirement", isPresented: $showingAgeError) {
                Button("OK") { }
            } message: {
                Text("You must be 18 or older to use this app.")
            }
            .alert("Welcome to Dirt!", isPresented: $showDone) {
                Button("Get Started") {
                    onboardingCompleted = true
                    onComplete?()
                }
            } message: {
                Text("Your account has been created successfully. Welcome to the community!")
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(spacing: UISpacing.md) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(UIColors.accentPrimary)
                        
                        Text("Welcome to Dirt")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("The anonymous men's dating review platform")
                            .font(.title3)
                            .foregroundColor(UIColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            FeatureRow(icon: "eye.slash", title: "Anonymous Reviews", description: "Share dating experiences safely")
                            FeatureRow(icon: "shield.checkered", title: "Privacy First", description: "Your identity stays protected")
                            FeatureRow(icon: "person.2.badge.plus", title: "Community Driven", description: "Help other men navigate dating")
                            FeatureRow(icon: "flag.checkered", title: "Moderated Content", description: "Safe and respectful environment")
                        }
                        .padding(.top, UISpacing.md)
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }
    
    // MARK: - Phone Verification View
    private var phoneVerificationView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(spacing: UISpacing.md) {
                        Image(systemName: "phone.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(UIColors.accentPrimary)
                        
                        Text("Verify Your Phone")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("We need to verify your phone number to ensure authentic users and prevent spam.")
                            .font(.subheadline)
                            .foregroundColor(UIColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: UISpacing.sm) {
                            TextField("Phone Number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .padding(UISpacing.md)
                                .background(MaterialDesignSystem.Glass.ultraThin)
                                .overlay(
                                    RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                                )
                                .cornerRadius(UICornerRadius.sm)
                            
                            if let errorMessage = phoneVerificationService.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(UIColors.error)
                                    .multilineTextAlignment(.center)
                            }
                            
                            GlassButton(
                                phoneVerificationService.isLoading ? "Sending..." : "Send Verification Code",
                                style: .primary
                            ) {
                                Task {
                                    do {
                                        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
                                        withAnimation {
                                            currentPage = 2
                                        }
                                    } catch {
                                        // Error is handled by the service
                                    }
                                }
                            }
                            .disabled(phoneNumber.isEmpty || phoneVerificationService.isLoading)
                        }
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }
    
    // MARK: - Code Verification View
    private var codeVerificationView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(spacing: UISpacing.md) {
                        Image(systemName: "message.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(UIColors.accentPrimary)
                        
                        Text("Enter Verification Code")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("We sent a verification code to")
                            .font(.subheadline)
                            .foregroundColor(UIColors.secondaryLabel)
                        
                        Text(phoneNumber)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(UIColors.label)
                        
                        VStack(spacing: UISpacing.sm) {
                            TextField("Verification Code", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .multilineTextAlignment(.center)
                                .font(.title3)
                                .padding(UISpacing.md)
                                .background(MaterialDesignSystem.Glass.ultraThin)
                                .overlay(
                                    RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                        .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                                )
                                .cornerRadius(UICornerRadius.sm)
                            
                            if let errorMessage = phoneVerificationService.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(UIColors.error)
                                    .multilineTextAlignment(.center)
                            }
                            
                            GlassButton(
                                phoneVerificationService.isLoading ? "Verifying..." : "Verify Code",
                                style: .primary
                            ) {
                                Task {
                                    do {
                                        let result = try await phoneVerificationService.verifyCode(verificationCode, for: phoneNumber)
                                        if result.isVerified {
                                            isPhoneVerified = true
                                            withAnimation {
                                                currentPage = 3
                                            }
                                        }
                                    } catch {
                                        // Error is handled by the service
                                    }
                                }
                            }
                            .disabled(verificationCode.isEmpty || phoneVerificationService.isLoading)
                            
                            if phoneVerificationService.canResend {
                                Button("Resend Code") {
                                    Task {
                                        try? await phoneVerificationService.resendVerificationCode(to: phoneNumber)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(UIColors.accentPrimary)
                            } else {
                                Text("Resend in \(phoneVerificationService.resendCountdown)s")
                                    .font(.caption)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                        }
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }
    
    // MARK: - Age Verification View
    private var ageVerificationView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(spacing: UISpacing.md) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(UIColors.accentPrimary)
                        
                        Text("Age Verification")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("You must be 18 or older to use this app. Please confirm your birth date.")
                            .font(.subheadline)
                            .foregroundColor(UIColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: UISpacing.sm) {
                            DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                            
                            Text("Your birth date is used only for age verification and is not stored or shared.")
                                .font(.caption)
                                .foregroundColor(UIColors.secondaryLabel)
                                .multilineTextAlignment(.center)
                                .padding(.top, UISpacing.sm)
                        }
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }
    
    // MARK: - Guidelines View
    private var guidelinesView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(alignment: .leading, spacing: UISpacing.md) {
                        HStack {
                            Image(systemName: "doc.text.checkmark")
                                .font(.system(size: 40))
                                .foregroundColor(UIColors.accentPrimary)
                            
                            VStack(alignment: .leading) {
                                Text("Community Guidelines")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(UIColors.label)
                                
                                Text("Please read and accept our community guidelines")
                                    .font(.subheadline)
                                    .foregroundColor(UIColors.secondaryLabel)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: UISpacing.sm) {
                            GuidelineRow(icon: "shield.checkered", title: "Respect Privacy", description: "No doxxing, personal information, or real names")
                            GuidelineRow(icon: "flag", title: "Report Harmful Content", description: "Help keep the community safe by reporting violations")
                            GuidelineRow(icon: "eye.slash", title: "Anonymous by Default", description: "All content is anonymous to protect user privacy")
                            GuidelineRow(icon: "hand.thumbsup", title: "Be Honest", description: "Provide honest reviews and constructive feedback")
                            GuidelineRow(icon: "exclamationmark.triangle", title: "No Harassment", description: "Respectful discussion only, no personal attacks")
                        }
                        
                        Toggle(isOn: $hasAcceptedGuidelines) {
                            Text("I have read and agree to the community guidelines")
                                .font(.subheadline)
                                .foregroundColor(UIColors.label)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: UIColors.accentPrimary))
                        .padding(.top, UISpacing.md)
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }
    
    // MARK: - Username Generation View
    private var usernameGenerationView: some View {
        ScrollView {
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(spacing: UISpacing.md) {
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 50))
                            .foregroundColor(UIColors.accentPrimary)
                        
                        Text("Your Anonymous Identity")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("We've generated a unique anonymous username for you. This protects your privacy while allowing you to build reputation in the community.")
                            .font(.subheadline)
                            .foregroundColor(UIColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: UISpacing.sm) {
                            Text(generatedUsername)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(UIColors.accentPrimary)
                                .padding(UISpacing.md)
                                .background(MaterialDesignSystem.Glass.ultraThin)
                                .overlay(
                                    RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                        .stroke(MaterialDesignSystem.GlassBorders.accent, lineWidth: 1)
                                )
                                .cornerRadius(UICornerRadius.sm)
                            
                            GlassButton(
                                "Generate New Username",
                                style: .secondary
                            ) {
                                generateUsername()
                            }
                            
                            Text("Note: Your username cannot be changed after account creation.")
                                .font(.caption)
                                .foregroundColor(UIColors.secondaryLabel)
                                .multilineTextAlignment(.center)
                                .padding(.top, UISpacing.sm)
                        }
                    }
                }
                .glassAppear()
            }
            .padding()
        }
        .onAppear {
            if generatedUsername.isEmpty {
                generateUsername()
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack {
            if currentPage > 0 {
                GlassButton("Back", style: .secondary) {
                    withAnimation {
                        currentPage -= 1
                    }
                }
            }
            
            Spacer()
            
            GlassButton(
                currentPage == totalPages - 1 ? "Complete Setup" : "Next",
                style: .primary
            ) {
                if canProceed {
                    if currentPage == totalPages - 1 {
                        completeOnboarding()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
            }
            .disabled(!canProceed)
        }
        .padding()
    }
    
    // MARK: - Helper Properties
    private var canProceed: Bool {
        switch currentPage {
        case 0: return true // Welcome
        case 1: return !phoneNumber.isEmpty // Phone verification
        case 2: return isPhoneVerified // Code verification
        case 3: return isAgeValid // Age verification
        case 4: return hasAcceptedGuidelines // Guidelines
        case 5: return !generatedUsername.isEmpty // Username
        default: return false
        }
    }
    
    private var isAgeValid: Bool {
        let result = ageVerificationService.verifyAge(birthDate: birthDate)
        switch result {
        case .verified:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func generateUsername() {
        generatedUsername = usernameService.generateUsername()
    }
    
    private func completeOnboarding() {
        let ageResult = ageVerificationService.verifyAge(birthDate: birthDate)
        
        switch ageResult {
        case .verified(let age):
            // Age is valid, proceed with account creation
            Task {
                // Here you would typically save the user data to your backend
                // For now, we'll just complete the onboarding
                
                // In a real implementation, you would:
                // 1. Create user account with phone verification result
                // 2. Store age verification status (not the actual birth date)
                // 3. Assign the generated username
                // 4. Set up user preferences
                
                await MainActor.run {
                    showDone = true
                }
            }
            
        case .tooYoung(let message):
            showingAgeError = true
            
        case .invalid(let message):
            showingAgeError = true
        }
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: UISpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(UIColors.accentPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(UIColors.label)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            
            Spacer()
        }
    }
}

struct GuidelineRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: UISpacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(UIColors.accentPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(UIColors.label)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct EnhancedOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedOnboardingView()
    }
}