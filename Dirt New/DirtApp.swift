import SwiftUI

@main
struct DirtApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var supabaseManager = SupabaseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(supabaseManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize core services
        supabaseManager.initialize()
        
        // Check authentication state
        Task {
            await authService.checkAuthenticationState()
        }
    }
}