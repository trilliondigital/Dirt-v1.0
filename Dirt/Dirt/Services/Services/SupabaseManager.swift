import Foundation
import Supabase
import Combine

final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    // Replace with your actual Supabase credentials or load from Secrets
    private let supabaseURL = URL(string: "https://YOUR_PROJECT_ID.supabase.co")!
    private let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"

    let client: SupabaseClient
    @Published var session: Session?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)

        // Listen to auth state changes
        client.auth.authStateChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .signedIn(let session):
                    self?.session = session
                case .signedOut:
                    self?.session = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Auth helpers
    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}
