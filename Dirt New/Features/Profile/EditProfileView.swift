import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var username: String = ""
    @State private var selectedCategories: Set<PostCategory> = []
    @State private var isAnonymous: Bool = true
    @State private var allowDirectMessages: Bool = false
    @State private var showOnlineStatus: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Settings
                Section("Profile") {
                    HStack {
                        Text("Profile Picture")
                        Spacer()
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            )
                        Button("Change") {
                            // TODO: Implement image picker
                        }
                        .font(.caption)
                    }
                    
                    HStack {
                        Text("Username")
                        TextField("Optional", text: $username)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("Stay Anonymous", isOn: $isAnonymous)
                }
                
                // Privacy Settings
                Section("Privacy") {
                    Toggle("Allow Direct Messages", isOn: $allowDirectMessages)
                        .disabled(isAnonymous)
                    
                    Toggle("Show Online Status", isOn: $showOnlineStatus)
                        .disabled(isAnonymous)
                }
                
                // Interests
                Section("Interests") {
                    Text("Select topics you're interested in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            CategoryToggle(
                                category: category,
                                isSelected: selectedCategories.contains(category),
                                onToggle: {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Account Actions
                Section("Account") {
                    Button("Export My Data") {
                        // TODO: Implement data export
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        // TODO: Implement account deletion
                    }
                }
            }
            .navigationTitle("Edit Profile")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .trailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Saving...")
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        )
                }
            }
        }
    }
    
    private func loadCurrentProfile() {
        guard let user = authService.currentUser else { return }
        
        username = user.username ?? ""
        selectedCategories = Set(user.preferredCategories)
        isAnonymous = user.isAnonymous
        allowDirectMessages = user.allowDirectMessages
        showOnlineStatus = user.showOnlineStatus
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            await authService.updateUserProfile(
                username: username.isEmpty ? nil : username,
                preferences: Array(selectedCategories)
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

struct CategoryToggle: View {
    let category: PostCategory
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthenticationService())
}