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
                        SettingsRow(icon: "person.fill", title: "Profile", color: UIColors.accentPrimary)
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: UIColors.danger)
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(icon: "lock.fill", title: "Privacy", color: UIColors.success)
                    }
                }
                
                // App Settings Section
                Section(header: Text("App Settings")) {
                    Toggle(isOn: $isDarkMode) {
                        SettingsRow(icon: "moon.fill", title: "Dark Mode", color: UIColors.accentSecondary)
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(icon: "paintpalette.fill", title: "Appearance", color: Color.pink)
                    }
                    
                    NavigationLink(destination: LanguageSettingsView()) {
                        HStack {
                            SettingsRow(icon: "globe", title: "Language", color: UIColors.accentPrimary)
                            Spacer()
                            Text("English")
                                .foregroundColor(UIColors.secondaryLabel)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Support Section
                Section(header: Text("Support")) {
                    NavigationLink(destination: HelpCenterView()) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: UIColors.warning)
                    }
                    
                    NavigationLink(destination: InviteView()) {
                        SettingsRow(icon: "person.2.fill", title: "Invite Friends", color: UIColors.accentPrimary)
                    }
                    
                    NavigationLink(destination: ContactUsView()) {
                        SettingsRow(icon: "envelope.fill", title: "Contact Us", color: UIColors.success)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: UIColors.secondaryLabel)
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
                            .foregroundColor(UIColors.danger)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 16, weight: .medium))
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
                            .foregroundColor(UIColors.danger)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 16, weight: .medium))
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
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: UISpacing.sm) {
            // Glass icon container
            ZStack {
                RoundedRectangle(cornerRadius: UICornerRadius.xs)
                    .fill(MaterialDesignSystem.Glass.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: UICornerRadius.xs)
                            .fill(color.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: UICornerRadius.xs)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(UIColors.label)
        }
        .padding(.vertical, UISpacing.xxs)
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
