import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if currentStep == 0 {
                    WelcomeView(onNext: { currentStep = 1 })
                } else {
                    AuthenticationView()
                }
            }
        }
    }
}

struct WelcomeView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)
            
            Text("Welcome to Dirt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Share your dating experiences, get advice, and help others navigate their journey.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Get Started") {
                onNext()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Choose how to continue")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 15) {
                Button(action: {
                    Task {
                        await authService.signInWithApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continue with Apple")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        await authService.signInAnonymously()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                        Text("Continue Anonymously")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Text("Anonymous users can read and post but have limited features.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .disabled(authService.isLoading)
        .overlay {
            if authService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
}