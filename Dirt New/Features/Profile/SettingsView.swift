import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    NavigationLink(destination: EditProfileView()) {
                        SettingsRow(
                            icon: "person.circle",
                            title: "Edit Profile",
                            subtitle: "Update your profile information"
                        )
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(
                            icon: "bell",
                            title: "Notifications",
                            subtitle: "Manage notification preferences"
                        )
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "shield",
                            title: "Privacy & Safety",
                            subtitle: "Control your privacy settings"
                        )
                    }
                }
                
                // App Settings
                Section("App Settings") {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(
                            icon: "paintbrush",
                            title: "Appearance",
                            subtitle: "Theme and display options"
                        )
                    }
                    
                    NavigationLink(destination: ContentSettingsView()) {
                        SettingsRow(
                            icon: "doc.text",
                            title: "Content Preferences",
                            subtitle: "Customize your feed"
                        )
                    }
                }
                
                // Support
                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help and contact support"
                        )
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About Dirt",
                            subtitle: "Version info and credits"
                        )
                    }
                    
                    Button(action: {
                        // TODO: Implement feedback
                    }) {
                        SettingsRow(
                            icon: "envelope",
                            title: "Send Feedback",
                            subtitle: "Help us improve the app"
                        )
                    }
                    .foregroundColor(.primary)
                }
                
                // Legal
                Section("Legal") {
                    NavigationLink(destination: TermsView()) {
                        SettingsRow(
                            icon: "doc.text",
                            title: "Terms of Service",
                            subtitle: "Read our terms"
                        )
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            subtitle: "How we handle your data"
                        )
                    }
                }
                
                // Account Actions
                Section("Account Actions") {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        SettingsRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            subtitle: "Sign out of your account",
                            titleColor: .blue
                        )
                    }
                    
                    Button(action: {
                        showingDeleteAccountAlert = true
                    }) {
                        SettingsRow(
                            icon: "trash",
                            title: "Delete Account",
                            subtitle: "Permanently delete your account",
                            titleColor: .red
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            
            .toolbar {
                ToolbarItem(placement: .trailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authService.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can always sign back in later.")
            }
            .alert("Delete Account?", isPresented: $showingDeleteAccountAlert) {
                Button("Delete", role: .destructive) {
                    // TODO: Implement account deletion
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone. All your posts and data will be permanently deleted.")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var titleColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(titleColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Placeholder Views for Navigation

// NotificationSettingsView is defined in Features/Notifications/NotificationSettingsView.swift

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy & Safety")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .navigationTitle("Appearance")
    }
}

struct ContentSettingsView: View {
    var body: some View {
        Text("Content Settings")
            .navigationTitle("Content Preferences")
    }
}

struct HelpView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Dirt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("The honest dating feedback community")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("By using Dirt, you agree to these terms...")
                    .font(.body)
                
                // Add more terms content here
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us...")
                    .font(.body)
                
                // Add more privacy policy content here
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationService())
        .environmentObject(AppState())
}