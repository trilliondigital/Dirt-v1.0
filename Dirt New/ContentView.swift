import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationService())
        .environmentObject(SupabaseManager())
}