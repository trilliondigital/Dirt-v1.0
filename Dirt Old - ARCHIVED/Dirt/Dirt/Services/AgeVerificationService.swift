import Foundation

@MainActor
class AgeVerificationService: ObservableObject {
    static let shared = AgeVerificationService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let minimumAge = 18
    
    private init() {}
    
    // MARK: - Age Verification
    
    func verifyAge(birthDate: Date) -> AgeVerificationResult {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate age
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        guard let age = ageComponents.year else {
            return .invalid("Invalid birth date")
        }
        
        // Check if user is old enough
        if age < minimumAge {
            return .tooYoung("You must be \(minimumAge) or older to use this app")
        }
        
        // Check if birth date is not in the future
        if birthDate > now {
            return .invalid("Birth date cannot be in the future")
        }
        
        // Check if birth date is reasonable (not too old)
        if age > 120 {
            return .invalid("Please enter a valid birth date")
        }
        
        return .verified(age: age)
    }
    
    func calculateAge(from birthDate: Date) -> Int? {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year
    }
    
    func isValidBirthDate(_ birthDate: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if date is not in the future
        guard birthDate <= now else { return false }
        
        // Check if age is reasonable (between 0 and 120 years)
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        guard let age = ageComponents.year, age >= 0 && age <= 120 else { return false }
        
        return true
    }
    
    // MARK: - Secure Age Verification (Mock Implementation)
    
    func performSecureAgeVerification(birthDate: Date) async -> SecureVerificationResult {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        // Simulate network delay for secure verification
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // First, perform basic age verification
        let basicResult = verifyAge(birthDate: birthDate)
        
        switch basicResult {
        case .verified(let age):
            // In a real implementation, this might involve:
            // - Document verification
            // - Third-party age verification services
            // - Government ID verification
            
            // For now, we'll simulate a successful verification
            let verificationToken = generateVerificationToken()
            return .verified(age: age, token: verificationToken)
            
        case .tooYoung(let message):
            errorMessage = message
            return .failed(message)
            
        case .invalid(let message):
            errorMessage = message
            return .failed(message)
        }
    }
    
    private func generateVerificationToken() -> String {
        // Generate a secure token for age verification
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<32).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Privacy Protection
    
    func hashBirthDate(_ birthDate: Date) -> String {
        // Create a hash of the birth date for privacy
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: birthDate)
        
        // In a real implementation, you'd use a proper cryptographic hash
        return dateString.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
    func shouldStoreBirthDate() -> Bool {
        // In most cases, you shouldn't store the actual birth date
        // Only store the verification status and age if necessary
        return false
    }
}

// MARK: - Supporting Types

enum AgeVerificationResult {
    case verified(age: Int)
    case tooYoung(String)
    case invalid(String)
}

enum SecureVerificationResult {
    case verified(age: Int, token: String)
    case failed(String)
    case pending
}

struct AgeVerificationData {
    let isVerified: Bool
    let verificationDate: Date
    let verificationToken: String?
    let minimumAgeConfirmed: Bool
    
    // Note: We don't store the actual birth date for privacy
}