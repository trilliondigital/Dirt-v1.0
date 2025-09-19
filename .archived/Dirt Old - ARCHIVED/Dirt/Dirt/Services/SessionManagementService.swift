import Foundation
import Combine
import CryptoKit

@MainActor
class SessionManagementService: ObservableObject {
    static let shared = SessionManagementService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AuthenticatedUser?
    @Published var sessionStatus: SessionStatus = .unauthenticated
    @Published var errorMessage: String?
    
    private var sessionToken: String?
    private var refreshToken: String?
    private var tokenExpirationDate: Date?
    private var refreshTimer: Timer?
    private var sessionValidationTimer: Timer?
    
    private let keychain = KeychainService.shared
    private let supabaseManager = SupabaseManager.shared
    
    // Session configuration
    private let sessionTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
    private let refreshThreshold: TimeInterval = 5 * 60 // Refresh 5 minutes before expiry
    private let sessionValidationInterval: TimeInterval = 60 // Check session every minute
    
    private init() {
        setupSessionValidation()
        restoreSession()
    }
    
    deinit {
        refreshTimer?.invalidate()
        sessionValidationTimer?.invalidate()
    }
    
    // MARK: - Session Management
    
    func createSession(phoneNumberHash: String, username: String, ageVerified: Bool) async throws {
        do {
            // Generate secure session tokens
            let sessionData = generateSessionTokens()
            
            // Create user session in backend (mock implementation)
            let user = try await createUserSession(
                phoneNumberHash: phoneNumberHash,
                username: username,
                ageVerified: ageVerified,
                sessionToken: sessionData.sessionToken
            )
            
            // Store session data securely
            try storeSessionData(sessionData)
            
            // Update local state
            await MainActor.run {
                self.sessionToken = sessionData.sessionToken
                self.refreshToken = sessionData.refreshToken
                self.tokenExpirationDate = sessionData.expirationDate
                self.currentUser = user
                self.isAuthenticated = true
                self.sessionStatus = .authenticated
                self.errorMessage = nil
            }
            
            // Start automatic refresh
            scheduleTokenRefresh()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create session: \(error.localizedDescription)"
                self.sessionStatus = .error
            }
            throw error
        }
    }
    
    func refreshSession() async throws {
        guard let refreshToken = refreshToken else {
            throw SessionError.noRefreshToken
        }
        
        do {
            // Refresh tokens with backend
            let newSessionData = try await refreshSessionTokens(refreshToken: refreshToken)
            
            // Update stored session data
            try storeSessionData(newSessionData)
            
            // Update local state
            await MainActor.run {
                self.sessionToken = newSessionData.sessionToken
                self.refreshToken = newSessionData.refreshToken
                self.tokenExpirationDate = newSessionData.expirationDate
                self.sessionStatus = .authenticated
            }
            
            // Reschedule refresh
            scheduleTokenRefresh()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to refresh session: \(error.localizedDescription)"
            }
            
            // If refresh fails, logout user
            await logout()
            throw error
        }
    }
    
    func validateSession() async -> Bool {
        guard let sessionToken = sessionToken,
              let expirationDate = tokenExpirationDate else {
            await logout()
            return false
        }
        
        // Check if token is expired
        if Date() >= expirationDate {
            // Try to refresh if we have a refresh token
            if refreshToken != nil {
                do {
                    try await refreshSession()
                    return true
                } catch {
                    await logout()
                    return false
                }
            } else {
                await logout()
                return false
            }
        }
        
        // Validate token with backend (mock implementation)
        do {
            let isValid = try await validateSessionToken(sessionToken)
            if !isValid {
                await logout()
                return false
            }
            return true
        } catch {
            await logout()
            return false
        }
    }
    
    func logout() async {
        // Invalidate session on backend
        if let sessionToken = sessionToken {
            try? await invalidateSessionToken(sessionToken)
        }
        
        // Clear local session data
        clearSessionData()
        
        // Update state
        await MainActor.run {
            self.sessionToken = nil
            self.refreshToken = nil
            self.tokenExpirationDate = nil
            self.currentUser = nil
            self.isAuthenticated = false
            self.sessionStatus = .unauthenticated
            self.errorMessage = nil
        }
        
        // Stop timers
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw SessionError.notAuthenticated
        }
        
        do {
            // Delete user account on backend
            try await deleteUserAccount(userId: user.id)
            
            // Logout and clear all data
            await logout()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func generateSessionTokens() -> SessionTokenData {
        let sessionToken = generateSecureToken()
        let refreshToken = generateSecureToken()
        let expirationDate = Date().addingTimeInterval(sessionTimeout)
        
        return SessionTokenData(
            sessionToken: sessionToken,
            refreshToken: refreshToken,
            expirationDate: expirationDate
        )
    }
    
    private func generateSecureToken() -> String {
        let tokenData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return tokenData.base64EncodedString()
    }
    
    private func storeSessionData(_ sessionData: SessionTokenData) throws {
        try keychain.store(sessionData.sessionToken, forKey: "session_token")
        try keychain.store(sessionData.refreshToken, forKey: "refresh_token")
        try keychain.store(sessionData.expirationDate.timeIntervalSince1970.description, forKey: "token_expiration")
    }
    
    private func restoreSession() {
        guard let sessionToken = try? keychain.retrieve(forKey: "session_token"),
              let refreshToken = try? keychain.retrieve(forKey: "refresh_token"),
              let expirationString = try? keychain.retrieve(forKey: "token_expiration"),
              let expirationInterval = TimeInterval(expirationString) else {
            return
        }
        
        let expirationDate = Date(timeIntervalSince1970: expirationInterval)
        
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.tokenExpirationDate = expirationDate
        
        // Validate restored session
        Task {
            let isValid = await validateSession()
            if isValid {
                await MainActor.run {
                    self.isAuthenticated = true
                    self.sessionStatus = .authenticated
                }
                scheduleTokenRefresh()
            }
        }
    }
    
    private func clearSessionData() {
        try? keychain.delete(forKey: "session_token")
        try? keychain.delete(forKey: "refresh_token")
        try? keychain.delete(forKey: "token_expiration")
        try? keychain.delete(forKey: "user_data")
    }
    
    private func scheduleTokenRefresh() {
        refreshTimer?.invalidate()
        
        guard let expirationDate = tokenExpirationDate else { return }
        
        let refreshDate = expirationDate.addingTimeInterval(-refreshThreshold)
        let timeUntilRefresh = refreshDate.timeIntervalSinceNow
        
        if timeUntilRefresh > 0 {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    try? await self?.refreshSession()
                }
            }
        }
    }
    
    private func setupSessionValidation() {
        sessionValidationTimer = Timer.scheduledTimer(withTimeInterval: sessionValidationInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isAuthenticated == true {
                    _ = await self?.validateSession()
                }
            }
        }
    }
    
    // MARK: - Backend Integration (Mock Implementation)
    
    private func createUserSession(phoneNumberHash: String, username: String, ageVerified: Bool, sessionToken: String) async throws -> AuthenticatedUser {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock user creation
        let user = AuthenticatedUser(
            id: UUID().uuidString,
            username: username,
            phoneNumberHash: phoneNumberHash,
            isAgeVerified: ageVerified,
            createdAt: Date(),
            reputation: 0,
            isVerified: true
        )
        
        return user
    }
    
    private func refreshSessionTokens(refreshToken: String) async throws -> SessionTokenData {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock token refresh
        return generateSessionTokens()
    }
    
    private func validateSessionToken(_ token: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Mock validation - in real implementation, this would validate with backend
        return !token.isEmpty
    }
    
    private func invalidateSessionToken(_ token: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Mock invalidation
    }
    
    private func deleteUserAccount(userId: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Mock account deletion
        // In real implementation, this would delete user data from backend
    }
}

// MARK: - Supporting Types

struct SessionTokenData {
    let sessionToken: String
    let refreshToken: String
    let expirationDate: Date
}

struct AuthenticatedUser: Codable {
    let id: String
    let username: String
    let phoneNumberHash: String
    let isAgeVerified: Bool
    let createdAt: Date
    let reputation: Int
    let isVerified: Bool
}

enum SessionStatus {
    case unauthenticated
    case authenticating
    case authenticated
    case refreshing
    case error
}

enum SessionError: LocalizedError {
    case notAuthenticated
    case noRefreshToken
    case tokenExpired
    case invalidToken
    case networkError(String)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenExpired:
            return "Session token has expired"
        case .invalidToken:
            return "Invalid session token"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}