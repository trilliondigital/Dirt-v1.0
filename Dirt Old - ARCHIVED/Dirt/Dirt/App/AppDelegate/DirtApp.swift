import SwiftUI
import Supabase

@main
struct DirtApp: App {
    // Service container for dependency injection
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var toastCenter = ToastCenter()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    init() {
        // Initialize critical services early
        ServiceContainer.shared.initializeCriticalServices()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .serviceContainer(serviceContainer)
            .environmentObject(serviceContainer.supabaseManager)
            .withToasts(toastCenter)
        }
    }
}
