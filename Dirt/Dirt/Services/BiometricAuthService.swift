import Foundation
import LocalAuthentication
import Combine

@MainActor
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    @Published var isAvailable = false
    @Published var biometricType: LABiometryType = .none
    @Published var isEnabled = false
    
    private let context = LAContext()
    
    private init() {
        checkBiometricAvailability()
        loadBiometricPreference()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        guard isAvailable else {
            throw BiometricError.notAvailable
        }
        
        let reason = "Authenticate to access your account"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed(error.localizedDescription)
        }
    }
    
    func enableBiometricAuth() {
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "biometricAuthEnabled")
    }
    
    func disableBiometricAuth() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
    }
    
    private func loadBiometricPreference() {
        isEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        }
    }
}
