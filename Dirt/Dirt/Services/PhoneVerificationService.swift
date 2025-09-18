import Foundation
import Combine
import CryptoKit

@MainActor
class PhoneVerificationService: ObservableObject {
    static let shared = PhoneVerificationService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var canResend = true
    @Published var resendCountdown = 0
    @Published var attemptsRemaining = 3
    @Published var verificationId: String?
    
    private var resendTimer: Timer?
    private let resendCooldown = 60 // seconds
    private let maxAttempts = 3
    
    private init() {}
    
    // MARK: - Phone Number Validation
    
    func validatePhoneNumber(_ phoneNumber: String) -> PhoneValidationResult {
        let cleanedNumber = cleanPhoneNumber(phoneNumber)
        
        // Basic validation - must be 10-15 digits
        guard cleanedNumber.count >= 10 && cleanedNumber.count <= 15 else {
            return .invalid("Phone number must be between 10-15 digits")
        }
        
        // Check if all characters are digits
        guard cleanedNumber.allSatisfy({ $0.isNumber }) else {
            return .invalid("Phone number can only contain digits")
        }
        
        // US phone number validation (can be extended for international)
        if cleanedNumber.count == 10 {
            // US format without country code
            return .valid("+1\(cleanedNumber)")
        } else if cleanedNumber.count == 11 && cleanedNumber.hasPrefix("1") {
            // US format with country code
            return .valid("+\(cleanedNumber)")
        } else {
            // International format - assume it's valid if it has country code
            return .valid("+\(cleanedNumber)")
        }
    }
    
    private func cleanPhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    // MARK: - Phone Number Hashing
    
    func hashPhoneNumber(_ phoneNumber: String) -> String {
        let data = Data(phoneNumber.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - SMS Verification
    
    func sendVerificationCode(to phoneNumber: String) async throws {
        let validationResult = validatePhoneNumber(phoneNumber)
        
        switch validationResult {
        case .invalid(let message):
            throw PhoneVerificationError.invalidPhoneNumber(message)
        case .valid(let formattedNumber):
            await performSendVerificationCode(to: formattedNumber)
        }
    }
    
    private func performSendVerificationCode(to phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real implementation, this would call a backend service
            // For now, we'll simulate the API call
            try await simulateSMSService(phoneNumber: phoneNumber)
            
            // Generate a verification ID for tracking
            verificationId = UUID().uuidString
            
            startResendCooldown()
            resetAttempts()
            
        } catch {
            errorMessage = "Failed to send verification code: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func resendVerificationCode(to phoneNumber: String) async throws {
        guard canResend else {
            throw PhoneVerificationError.resendNotAllowed
        }
        
        try await sendVerificationCode(to: phoneNumber)
    }
    
    func verifyCode(_ code: String, for phoneNumber: String) async throws -> VerificationResult {
        guard attemptsRemaining > 0 else {
            throw PhoneVerificationError.tooManyAttempts
        }
        
        guard let verificationId = verificationId else {
            throw PhoneVerificationError.noVerificationInProgress
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real implementation, this would verify with the backend
            let isValid = try await simulateCodeVerification(code: code, verificationId: verificationId)
            
            if isValid {
                let hashedPhone = hashPhoneNumber(phoneNumber)
                isLoading = false
                return VerificationResult(
                    isVerified: true,
                    phoneNumberHash: hashedPhone,
                    verificationId: verificationId
                )
            } else {
                attemptsRemaining -= 1
                let message = "Invalid verification code. \(attemptsRemaining) attempts remaining."
                errorMessage = message
                isLoading = false
                
                if attemptsRemaining == 0 {
                    throw PhoneVerificationError.tooManyAttempts
                }
                
                return VerificationResult(
                    isVerified: false,
                    phoneNumberHash: nil,
                    verificationId: verificationId
                )
            }
        } catch {
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Simulation Methods (Replace with real API calls)
    
    private func simulateSMSService(phoneNumber: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Simulate potential failures
        if phoneNumber.contains("0000") {
            throw PhoneVerificationError.serviceUnavailable
        }
        
        print("📱 SMS sent to \(phoneNumber): Your verification code is 123456")
    }
    
    private func simulateCodeVerification(code: String, verificationId: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // For testing purposes, accept "123456" as valid code
        return code == "123456"
    }
    
    // MARK: - Helper Methods
    
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
    
    private func resetAttempts() {
        attemptsRemaining = maxAttempts
        errorMessage = nil
    }
    
    func reset() {
        verificationId = nil
        attemptsRemaining = maxAttempts
        errorMessage = nil
        canResend = true
        resendCountdown = 0
        resendTimer?.invalidate()
        resendTimer = nil
    }
    
    deinit {
        resendTimer?.invalidate()
    }
}

// MARK: - Supporting Types

enum PhoneValidationResult {
    case valid(String) // Returns formatted phone number
    case invalid(String) // Returns error message
}

struct VerificationResult {
    let isVerified: Bool
    let phoneNumberHash: String?
    let verificationId: String
}

enum PhoneVerificationError: LocalizedError {
    case invalidPhoneNumber(String)
    case serviceUnavailable
    case resendNotAllowed
    case tooManyAttempts
    case noVerificationInProgress
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber(let message):
            return message
        case .serviceUnavailable:
            return "SMS service is currently unavailable. Please try again later."
        case .resendNotAllowed:
            return "Please wait before requesting another verification code."
        case .tooManyAttempts:
            return "Too many failed attempts. Please request a new verification code."
        case .noVerificationInProgress:
            return "No verification in progress. Please request a verification code first."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}