import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Replace with your actual Supabase credentials or load from Secrets
    private let supabaseURL = URL(string: "https://YOUR_PROJECT_ID.supabase.co")!
    private let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    let client: SupabaseClient
    @Published private(set) var session: Session?

    private init() {
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
        
        // Start listening to auth state changes
        Task {
            await listenToAuthState()
        }
    }
    
    private func listenToAuthState() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        self.session = session
                    case .signedOut, .userDeleted, .userUpdated:
                        self.session = nil
                    @unknown default:
                        self.session = nil
                    }
                }
            }
        }
    }

    // MARK: - Auth helpers
    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(
            email: email,
            password: password
        )
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}
