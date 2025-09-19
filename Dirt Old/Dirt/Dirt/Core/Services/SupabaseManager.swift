import Foundation
import Supabase
import Combine

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    private let supabaseURL: URL
    private let supabaseAnonKey: String
    private var authStateChangeTask: Task<Void, Never>?
    
    @Published private(set) var session: Session?
    @Published var todos: [Todo] = []
    @Published var errorMessage: String?
    @Published var userId: String?
    @Published var isAuthenticated: Bool = false
    
    private init() {
        let info = Bundle.main.infoDictionary ?? [:]
        let urlString = (info["SUPABASE_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyString = (info["SUPABASE_ANON_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackURL = "https://xruvwnrxatkgmncefozs.supabase.co"
        let fallbackKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhydXZ3bnJ4YXRrZ21uY2Vmb3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNzk0NTEsImV4cCI6MjA2OTc1NTQ1MX0.Ux7QgWRAcDviV5niUtDztu3PQ0m2_Fw3gwiTRlA_fPY"

        self.supabaseURL = URL(string: urlString?.isEmpty == false ? urlString! : fallbackURL)!
        self.supabaseAnonKey = (keyString?.isEmpty == false ? keyString! : fallbackKey)

        // Initialize the Supabase client with URL and key
        client = SupabaseClient(supabaseURL: self.supabaseURL, supabaseKey: self.supabaseAnonKey)
        
        // Setup auth state change listener
        authStateChangeTask = Task {
            setupAuthListener()
        }
        
        // Try to restore session on init
        Task {
            await restoreSession()
        }
    }
    
    deinit {
        authStateChangeTask?.cancel()
    }
    
    private func setupAuthListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .initialSession, .signedIn, .tokenRefreshed:
                        self.session = session
                        Task { await self.fetchTodos() }
                    case .signedOut:
                        self.session = nil
                        self.todos = []
                    case .userUpdated:
                        self.session = session
                    case .passwordRecovery:
                        break
                    case .mfaChallengeVerified:
                        break
                    case .userDeleted:
                        self.session = nil
                        self.todos = []
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Auth Methods
    
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.session = session
                self.errorMessage = nil
            }
            await fetchTodos()
        } catch {
            await MainActor.run {
                self.session = nil
                self.todos = []
                self.errorMessage = "Failed to restore session: \(error.localizedDescription)"
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.session = session
                self.errorMessage = nil
            }
            
            await fetchTodos()
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            if let session = response.session {
                await MainActor.run {
                    self.session = session
                    self.errorMessage = nil
                }
                await fetchTodos()
            } else {
                // Email confirmation required
                await MainActor.run {
                    self.errorMessage = "Please check your email to confirm your account."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            
            await MainActor.run {
                self.session = nil
                self.todos = []
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign out failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Todo Methods
    
    func fetchTodos() async {
        guard let userId = session?.user.id else { return }
        
        do {
            let todos: [Todo] = try await client
                .from("todos")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.todos = todos
            }
        } catch {
            print("Error fetching todos: \(error)")
        }
    }
    
    func addTodo(title: String) async throws {
        guard let userId = session?.user.id else { throw NSError(domain: "com.yourapp.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]) }
        
        let newTodo = Todo(
            title: title,
            isComplete: false,
            userId: userId
        )
        
        _ = try await client
            .from("todos")
            .insert(newTodo)
            .select()
            .single()
            .execute()
            .value as Todo
        
        await fetchTodos()
    }
    
    func toggleTodoComplete(_ todo: Todo) async throws {
        guard let todoId = todo.id else { return }
        
        let updatedTodo = Todo(
            id: todo.id,
            title: todo.title,
            isComplete: !todo.isComplete,
            userId: todo.userId,
            createdAt: todo.createdAt,
            updatedAt: todo.updatedAt
        )
        
        _ = try await client
            .from("todos")
            .update(updatedTodo)
            .eq("id", value: todoId)
            .select()
            .single()
            .execute()
            .value as Todo
        
        await fetchTodos()
    }
    // (duplicate Todo methods removed)

    func deleteTodo(_ todo: Todo) async throws {
        guard let todoId = todo.id else { return }
        _ = try await client
            .from("todos")
            .delete()
            .eq("id", value: todoId)
            .execute()
            .value
        await fetchTodos()
    }

    // MARK: - Additional Auth Helpers
    @MainActor
    func signInWithApple(idToken: String, nonce: String? = nil) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        self.session = session
        self.userId = session.user.id.uuidString
        self.isAuthenticated = true
    }

    @MainActor
    func signInWithEmailMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
    }

    // MARK: - Edge Functions
    func callEdgeFunction(name: String, json: [String: Any]) async throws -> Data {
        let url = supabaseURL.appendingPathComponent("functions/v1/\(name)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let accessToken = session?.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseFunction", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return data
    }
}