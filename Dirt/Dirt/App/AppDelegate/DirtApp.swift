import SwiftUI
import Supabase

@main
struct DirtApp: App {
    // Configure Supabase client once for the entire app
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            // Using the correct path to HomeView
            HomeView()
                .environmentObject(supabaseManager)
        }
    }
}
