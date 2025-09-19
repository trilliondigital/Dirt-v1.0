import SwiftUI
import Combine
import AuthenticationServices

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for authentication state changes
        supabaseManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
    }
    
    func checkAuthenticationState() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            await supabaseManager.checkAuthenticationState()
        } catch {
            self.error = AuthError.sessionCheckFailed
        }
    }
    
    func signInWithApple() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email]
            
            // This would typically use ASAuthorizationController
            // For now, we'll simulate the flow
            try await supabaseManager.signInWithApple(identityToken: "mock_token", nonce: "mock_nonce")
        } catch {
            self.error = AuthError.appleSignInFailed
        }
    }
    
    func signInAnonymously() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabaseManager.signInAnonymously()
        } catch {
            self.error = AuthError.anonymousSignInFailed
        }
    }
    
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabaseManager.signOut()
        } catch {
            self.error = AuthError.signOutFailed
        }
    }
    
    func updateUserProfile(username: String?, preferences: [PostCategory]) async {
        guard var user = currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            user.username = username
            user.preferredCategories = preferences
            try await supabaseManager.updateUserProfile(user)
        } catch {
            self.error = AuthError.profileUpdateFailed
        }
    }
}

enum AuthError: LocalizedError {
    case sessionCheckFailed
    case appleSignInFailed
    case anonymousSignInFailed
    case signOutFailed
    case profileUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .sessionCheckFailed:
            return "Failed to check authentication state"
        case .appleSignInFailed:
            return "Apple Sign In failed"
        case .anonymousSignInFailed:
            return "Anonymous sign in failed"
        case .signOutFailed:
            return "Sign out failed"
        case .profileUpdateFailed:
            return "Failed to update profile"
        }
    }
}