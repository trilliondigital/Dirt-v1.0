import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let user = authService.currentUser {
                                Text(user.reputationLevel.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: Text("Privacy Settings")) {
                        Label("Privacy", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }
                
                Section("Activity") {
                    NavigationLink(destination: Text("My Posts")) {
                        Label("My Posts", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: Text("Saved Posts")) {
                        Label("Saved Posts", systemImage: "bookmark")
                    }
                    
                    NavigationLink(destination: Text("Activity History")) {
                        Label("Activity", systemImage: "clock")
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        Task {
                            await authService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Preferences") {
                NavigationLink(destination: Text("Notification Settings")) {
                    Label("Notifications", systemImage: "bell")
                }
                
                NavigationLink(destination: Text("Theme Settings")) {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }
            
            Section("Content") {
                NavigationLink(destination: Text("Content Filters")) {
                    Label("Content Filters", systemImage: "eye.slash")
                }
                
                NavigationLink(destination: Text("Blocked Users")) {
                    Label("Blocked Users", systemImage: "person.slash")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}