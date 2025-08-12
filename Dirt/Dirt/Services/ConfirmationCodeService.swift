import Foundation
import Combine

@MainActor
class ConfirmationCodeService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canResend = true
    @Published var resendCountdown = 0
    @Published var attemptsRemaining = 3
    
    private var resendTimer: Timer?
    private let resendCooldown = 60 // seconds
    
    func sendConfirmationCode(to email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.signInWithEmailMagicLink(email: email)
            startResendCooldown()
        } catch {
            errorMessage = "Failed to send confirmation code: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func resendConfirmationCode(to email: String) async {
        guard canResend else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await SupabaseManager.shared.signInWithEmailMagicLink(email: email)
            startResendCooldown()
        } catch {
            errorMessage = "Failed to resend confirmation code: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func verifyConfirmationCode(_ code: String, for email: String) async -> Bool {
        guard attemptsRemaining > 0 else {
            errorMessage = "Too many failed attempts. Please request a new code."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Note: In a real implementation, you would verify the OTP code here
        // For now, we'll simulate the verification process
        
        do {
            // Simulate verification delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // In a real app, you would call the Supabase OTP verification
            // let session = try await SupabaseManager.shared.client.auth.verifyOTP(
            //     email: email,
            //     token: code,
            //     type: .email
            // )
            
            isLoading = false
            return true
        } catch {
            attemptsRemaining -= 1
            errorMessage = "Invalid confirmation code. \(attemptsRemaining) attempts remaining."
            isLoading = false
            return false
        }
    }
    
    private func startResendCooldown() {
        canResend = false
        resendCountdown = resendCooldown
        
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.resendCountdown -= 1
                
                if self.resendCountdown <= 0 {
                    self.canResend = true
                    self.resendTimer?.invalidate()
                    self.resendTimer = nil
                }
            }
        }
    }
    
    func resetAttempts() {
        attemptsRemaining = 3
        errorMessage = nil
    }
    
    deinit {
        resendTimer?.invalidate()
    }
}

// MARK: - SwiftUI Components

import SwiftUI

struct ConfirmationCodeView: View {
    @StateObject private var codeService = ConfirmationCodeService()
    @State private var code = ""
    @State private var email: String
    
    let onVerified: () -> Void
    
    init(email: String, onVerified: @escaping () -> Void) {
        self._email = State(initialValue: email)
        self.onVerified = onVerified
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                
                Text("Check your email")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We sent a confirmation code to")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 16) {
                // Code input field
                TextField("Enter confirmation code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .disabled(codeService.isLoading)
                
                // Error message
                if let errorMessage = codeService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // Verify button
                Button(action: verifyCode) {
                    if codeService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify Code")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(code.isEmpty || codeService.isLoading)
                
                // Resend button
                Button(action: resendCode) {
                    if codeService.canResend {
                        Text("Resend Code")
                    } else {
                        Text("Resend in \(codeService.resendCountdown)s")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(!codeService.canResend || codeService.isLoading)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await codeService.sendConfirmationCode(to: email)
            }
        }
    }
    
    private func verifyCode() {
        Task {
            let success = await codeService.verifyConfirmationCode(code, for: email)
            if success {
                onVerified()
            }
        }
    }
    
    private func resendCode() {
        Task {
            await codeService.resendConfirmationCode(to: email)
        }
    }
}
