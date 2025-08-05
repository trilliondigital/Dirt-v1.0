import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and welcome text
                    VStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(viewModel.isSignUp ? "Create an account" : "Welcome back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(viewModel.isSignUp 
                             ? "Join our community today" 
                             : "Sign in to continue to Dirt")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("your.email@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("••••••••", text: $viewModel.password)
                                .textContentType(.password)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                        }
                        
                        // Confirm password field (only for sign up)
                        if viewModel.isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("••••••••", text: $viewModel.confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Forgot password (only for sign in)
                        if !viewModel.isSignUp {
                            Button("Forgot password?") {
                                // Handle forgot password
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .foregroundColor(.blue)
                            .padding(.top, -8)
                        }
                        
                        // Sign in/up button
                        Button {
                            Task {
                                if viewModel.isSignUp {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(viewModel.isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top, 8)
                        
                        // Toggle between sign in and sign up
                        HStack {
                            Text(viewModel.isSignUp 
                                 ? "Already have an account?" 
                                 : "Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button(viewModel.isSignUp ? "Sign In" : "Create Account") {
                                withAnimation {
                                    viewModel.isSignUp.toggle()
                                }
                            }
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.isSignUp ? "Account Created" : "Sign In"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SupabaseManager.shared)
}
