import SwiftUI
import Supabase

@main
struct DirtApp: App {
    // Configure Supabase client once for the entire app
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var toastCenter = ToastCenter()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(supabaseManager)
            .withToasts(toastCenter)
        }
    }
}
