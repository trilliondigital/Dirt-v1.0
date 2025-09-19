import SwiftUI

struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedCategories: Set<PostCategory> = []
    @State private var username: String = ""
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    switch currentStep {
                    case .welcome:
                        WelcomeView(onContinue: {
                            withAnimation(.easeInOut) {
                                currentStep = .purpose
                            }
                        })
                        
                    case .purpose:
                        PurposeView(onContinue: {
                            withAnimation(.easeInOut) {
                                currentStep = .authentication
                            }
                        })
                        
                    case .authentication:
                        AuthenticationView(onContinue: {
                            withAnimation(.easeInOut) {
                                currentStep = .interests
                            }
                        })
                        
                    case .interests:
                        InterestsView(
                            selectedCategories: $selectedCategories,
                            onContinue: {
                                withAnimation(.easeInOut) {
                                    currentStep = .profile
                                }
                            }
                        )
                        
                    case .profile:
                        ProfileSetupView(
                            username: $username,
                            selectedCategories: selectedCategories,
                            onComplete: completeOnboarding
                        )
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            await authService.updateUserProfile(
                username: username.isEmpty ? nil : username,
                preferences: Array(selectedCategories)
            )
        }
    }
}

enum OnboardingStep {
    case welcome
    case purpose
    case authentication
    case interests
    case profile
}

// MARK: - Welcome View
struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon/Logo
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text("Welcome to Dirt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("The honest dating feedback community")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Purpose View
struct PurposeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Text("Our Mission")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Dirt is a safe space for men to share honest dating experiences, get advice, and support each other.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "shield.fill",
                    title: "Privacy First",
                    description: "Anonymous by default. Your privacy is our priority."
                )
                
                FeatureRow(
                    icon: "heart.fill",
                    title: "Supportive Community",
                    description: "Get genuine advice from men who understand."
                )
                
                FeatureRow(
                    icon: "checkmark.seal.fill",
                    title: "Honest Feedback",
                    description: "Real experiences, no fake stories or bots."
                )
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AuthenticationService())
}