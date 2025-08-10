import SwiftUI

struct SettingsView: View {
    @State private var isDarkMode = true
    @State private var isNotificationsEnabled = true
    @State private var isPrivateAccount = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileSettingsView()) {
                        SettingsRow(icon: "person.fill", title: "Profile", color: .blue)
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(icon: "lock.fill", title: "Privacy", color: .green)
                    }
                }
                
                // App Settings Section
                Section(header: Text("App Settings")) {
                    Toggle(isOn: $isDarkMode) {
                        SettingsRow(icon: "moon.fill", title: "Dark Mode", color: .purple)
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(icon: "paintpalette.fill", title: "Appearance", color: .pink)
                    }
                    
                    NavigationLink(destination: LanguageSettingsView()) {
                        HStack {
                            SettingsRow(icon: "globe", title: "Language", color: .blue)
                            Spacer()
                            Text("English")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink(destination: HelpCenterView()) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: .orange)
                    }
                    
                    NavigationLink(destination: ContactUsView()) {
                        SettingsRow(icon: "envelope.fill", title: "Contact Us", color: .green)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: .gray)
                    }
                }
                
                // Legal Section
                Section {
                    NavigationLink(destination: TermsView()) {
                        Text("Terms of Service")
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                }
                
                // Account Actions Section
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .alert(isPresented: $showLogoutAlert) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out"), action: {
                                // Handle logout
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                    
                    Button(action: {
                        showDeleteAccountAlert = true
                    }) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .alert(isPresented: $showDeleteAccountAlert) {
                        Alert(
                            title: Text("Delete Account"),
                            message: Text("This action cannot be undone. All your data will be permanently deleted."),
                            primaryButton: .destructive(Text("Delete"), action: {
                                // Handle account deletion
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(6)
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// MARK: - Placeholder Views for Navigation
private struct ProfileSettingsView: View { var body: some View { Text("Profile Settings").padding() } }
private struct NotificationSettingsView: View { var body: some View { Text("Notification Settings").padding() } }
private struct PrivacySettingsView: View { var body: some View { Text("Privacy Settings").padding() } }
private struct AppearanceSettingsView: View { var body: some View { Text("Appearance Settings").padding() } }
private struct LanguageSettingsView: View { var body: some View { Text("Language Settings").padding() } }
private struct HelpCenterView: View { var body: some View { Text("Help Center").padding() } }
private struct ContactUsView: View { var body: some View { Text("Contact Us").padding() } }
private struct AboutView: View { var body: some View { Text("About").padding() } }
private struct TermsView: View { var body: some View { Text("Terms of Service").padding() } }
private struct PrivacyPolicyView: View { var body: some View { Text("Privacy Policy").padding() } }
