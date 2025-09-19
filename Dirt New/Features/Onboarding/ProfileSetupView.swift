import SwiftUI

struct ProfileSetupView: View {
    @Binding var username: String
    let selectedCategories: Set<PostCategory>
    let onComplete: () -> Void
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSkipAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Almost Done!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Set up your profile. Remember, you can always stay anonymous.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Profile Image Placeholder
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                    
                    Text("Profile Picture (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Username Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username (Optional)")
                        .font(.headline)
                    
                    TextField("Enter username or stay anonymous", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Text("Leave blank to remain completely anonymous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Selected Interests Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Interests")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedCategories), id: \.self) { category in
                                Text(category.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Text("Complete Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    showingSkipAlert = true
                }) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .disabled(authService.isLoading)
        .overlay {
            if authService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("Skip Profile Setup?", isPresented: $showingSkipAlert) {
            Button("Skip", role: .destructive) {
                onComplete()
            }
            Button("Continue Setup", role: .cancel) { }
        } message: {
            Text("You can always set up your profile later in settings.")
        }
    }
}

#Preview {
    ProfileSetupView(
        username: .constant(""),
        selectedCategories: [.advice, .experience, .question],
        onComplete: {}
    )
    .environmentObject(AuthenticationService())
}