import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    let onContinue: () -> Void
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Join the Community")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose how you'd like to sign in. You can always stay anonymous.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.email]
                    },
                    onCompletion: { result in
                        Task {
                            await handleAppleSignIn(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                
                // Anonymous Sign In Button
                Button(action: {
                    Task {
                        await authService.signInAnonymously()
                        if authService.isAuthenticated {
                            onContinue()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                        Text("Continue Anonymously")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.gray)
                    .cornerRadius(12)
                }
                
                // Privacy Notice
                VStack(spacing: 8) {
                    Text("Privacy Notice")
                        .font(.headline)
                    
                    Text("We never store personal information without your consent. Anonymous users have full access to all features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
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
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(authService.error?.localizedDescription ?? "An unknown error occurred")
        }
        .onChange(of: authService.error) { _, error in
            showingError = error != nil
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onContinue()
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await authService.signInWithApple()
                }
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error)")
        }
    }
}

#Preview {
    AuthenticationView(onContinue: {})
        .environmentObject(AuthenticationService())
}