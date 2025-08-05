import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isSignUp = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private let supabaseManager = SupabaseManager.shared
    
    init() {
        // Subscribe to error messages from SupabaseManager
        supabaseManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.showAlert(message: message)
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn() async {
        guard validateInputs() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseManager.signIn(email: email, password: password)
            // Clear sensitive data
            password = ""
            confirmPassword = ""
        } catch {
            showAlert(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard validateInputs() else { return }
        
        if isSignUp && password != confirmPassword {
            showAlert(message: "Passwords do not match")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseManager.signUp(email: email, password: password)
            // Clear sensitive data
            password = ""
            confirmPassword = ""
            
            // Show success message
            showAlert(message: "Account created successfully! Please check your email to verify your account.")
        } catch {
            showAlert(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func validateInputs() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            showAlert(message: "Email and password cannot be empty")
            return false
        }
        
        guard email.isValidEmail else {
            showAlert(message: "Please enter a valid email address")
            return false
        }
        
        guard password.count >= 6 else {
            showAlert(message: "Password must be at least 6 characters")
            return false
        }
        
        return true
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
        }
    }
}

// MARK: - Extensions

extension String {
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}
