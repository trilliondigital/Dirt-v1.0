import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private let client: SupabaseClient
    
    @Published private(set) var session: Session?
    @Published var todos: [Todo] = []
    
    private init() {
        let supabaseURL = URL(string: "https://xruvwnrxatkgmncefozs.supabase.co")!
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhydXZ3bnJ4YXRrZ21uY2Vmb3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNzk0NTEsImV4cCI6MjA2OTc1NTQ1MX0.Ux7QgWRAcDviV5niUtDztu3PQ0m2_Fw3gwiTRlA_fPY"
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
        
        Task {
            await setupAuthListener()
            await fetchTodos()
        }
    }
    
    private func setupAuthListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn, .tokenRefreshed:
                        self.session = session
                        Task { await self.fetchTodos() }
                    case .signedOut, .userDeleted, .userUpdated:
                        self.session = nil
                        self.todos = []
                    @unknown default:
                        self.session = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Auth Methods
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        await MainActor.run {
            self.session = session
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let session = try await client.auth.signUp(
            email: email,
            password: password
        )
        await MainActor.run {
            self.session = session
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.session = nil
            self.todos = []
        }
    }
    
    // MARK: - Todo Methods
    
    func fetchTodos() async {
        guard let userId = session?.user.id else { return }
        
        do {
            let todos: [Todo] = try await client
                .from("todos")
                .select()
                .eq("user_id", value: userId)
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
        guard let userId = session?.user.id else { return }
        
        let newTodo = Todo(
            title: title,
            isComplete: false,
            userId: userId
        )
        
        let _: Todo = try await client
            .from("todos")
            .insert(newTodo)
            .select()
            .single()
            .execute()
            .value
        
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
        
        let _: Todo = try await client
            .from("todos")
            .update(updatedTodo)
            .eq("id", value: todoId)
            .select()
            .single()
            .execute()
            .value
        
        await fetchTodos()
    }
    
    func deleteTodo(_ todo: Todo) async throws {
        guard let todoId = todo.id else { return }
        
        try await client
            .from("todos")
            .delete()
            .eq("id", value: todoId)
            .execute()
        
        await fetchTodos()
    }
}
