import SwiftUI

@main
struct DirtApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var supabaseManager = SupabaseManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(supabaseManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize core services
        supabaseManager.initialize()
        
        // Initialize notification system
        Task {
            await notificationManager.initialize()
        }
        
        // Check authentication state
        Task {
            await authService.checkAuthenticationState()
        }
    }
}