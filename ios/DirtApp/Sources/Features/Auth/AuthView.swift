import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var supabaseManager: SupabaseManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                HStack {
                    Button {
                        Task { await viewModel.signIn() }
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    Button {
                        Task { await viewModel.signUp() }
                    } label: {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
                .padding(.top)

                Spacer()
            }
            .padding()
            .navigationTitle("Dirt Login")
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(SupabaseManager.shared)
}
