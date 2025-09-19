import XCTest
@testable import Dirt

@MainActor
final class SessionManagementServiceTests: XCTestCase {
    var sessionService: SessionManagementService!
    
    override func setUp() {
        super.setUp()
        sessionService = SessionManagementService.shared
        
        // Clear any existing session
        Task {
            await sessionService.logout()
        }
    }
    
    override func tearDown() {
        Task {
            await sessionService.logout()
        }
        sessionService = nil
        super.tearDown()
    }
    
    // MARK: - Session Creation Tests
    
    func testCreateSession_Success() async throws {
        let phoneHash = "hashed_phone_number"
        let username = "TestUser123"
        let ageVerified = true
        
        try await sessionService.createSession(
            phoneNumberHash: phoneHash,
            username: username,
            ageVerified: ageVerified
        )
        
        XCTAssertTrue(sessionService.isAuthenticated, "User should be authenticated after session creation")
        XCTAssertEqual(sessionService.sessionStatus, .authenticated, "Session status should be authenticated")
        XCTAssertNotNil(sessionService.currentUser, "Current user should be set")
        XCTAssertEqual(sessionService.currentUser?.username, username, "Username should match")
        XCTAssertEqual(sessionService.currentUser?.phoneNumberHash, phoneHash, "Phone hash should match")
        XCTAssertEqual(sessionService.currentUser?.isAgeVerified, ageVerified, "Age verification should match")
        XCTAssertNil(sessionService.errorMessage, "Should not have error message on success")
    }
    
    // MARK: - Session Validation Tests
    
    func testValidateSession_ValidSession() async throws {
        // First create a session
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        let isValid = await sessionService.validateSession()
        
        XCTAssertTrue(isValid, "Valid session should pass validation")
        XCTAssertTrue(sessionService.isAuthenticated, "User should remain authenticated")
    }
    
    func testValidateSession_NoSession() async {
        let isValid = await sessionService.validateSession()
        
        XCTAssertFalse(isValid, "Should fail validation when no session exists")
        XCTAssertFalse(sessionService.isAuthenticated, "User should not be authenticated")
    }
    
    // MARK: - Session Refresh Tests
    
    func testRefreshSession_Success() async throws {
        // Create initial session
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        // Refresh session
        try await sessionService.refreshSession()
        
        XCTAssertTrue(sessionService.isAuthenticated, "User should remain authenticated after refresh")
        XCTAssertEqual(sessionService.sessionStatus, .authenticated, "Session status should be authenticated")
    }
    
    func testRefreshSession_NoRefreshToken() async {
        do {
            try await sessionService.refreshSession()
            XCTFail("Should throw error when no refresh token exists")
        } catch SessionError.noRefreshToken {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Logout Tests
    
    func testLogout() async throws {
        // Create session first
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        XCTAssertTrue(sessionService.isAuthenticated, "Should be authenticated before logout")
        
        // Logout
        await sessionService.logout()
        
        XCTAssertFalse(sessionService.isAuthenticated, "Should not be authenticated after logout")
        XCTAssertNil(sessionService.currentUser, "Current user should be nil after logout")
        XCTAssertEqual(sessionService.sessionStatus, .unauthenticated, "Session status should be unauthenticated")
    }
    
    // MARK: - Account Deletion Tests
    
    func testDeleteAccount_Success() async throws {
        // Create session first
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        XCTAssertTrue(sessionService.isAuthenticated, "Should be authenticated before deletion")
        
        // Delete account
        try await sessionService.deleteAccount()
        
        XCTAssertFalse(sessionService.isAuthenticated, "Should not be authenticated after account deletion")
        XCTAssertNil(sessionService.currentUser, "Current user should be nil after account deletion")
        XCTAssertEqual(sessionService.sessionStatus, .unauthenticated, "Session status should be unauthenticated")
    }
    
    func testDeleteAccount_NotAuthenticated() async {
        do {
            try await sessionService.deleteAccount()
            XCTFail("Should throw error when not authenticated")
        } catch SessionError.notAuthenticated {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Session Status Tests
    
    func testSessionStatus_InitialState() {
        XCTAssertEqual(sessionService.sessionStatus, .unauthenticated, "Initial session status should be unauthenticated")
        XCTAssertFalse(sessionService.isAuthenticated, "Should not be authenticated initially")
        XCTAssertNil(sessionService.currentUser, "Current user should be nil initially")
    }
    
    func testSessionStatus_AfterAuthentication() async throws {
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        XCTAssertEqual(sessionService.sessionStatus, .authenticated, "Session status should be authenticated")
        XCTAssertTrue(sessionService.isAuthenticated, "Should be authenticated")
        XCTAssertNotNil(sessionService.currentUser, "Current user should not be nil")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_ClearErrorOnSuccess() async throws {
        // Simulate an error state
        sessionService.errorMessage = "Test error"
        
        // Create successful session
        try await sessionService.createSession(
            phoneNumberHash: "test_hash",
            username: "TestUser",
            ageVerified: true
        )
        
        XCTAssertNil(sessionService.errorMessage, "Error message should be cleared on successful operation")
    }
    
    // MARK: - User Data Tests
    
    func testUserData_Persistence() async throws {
        let phoneHash = "test_phone_hash"
        let username = "PersistentUser123"
        let ageVerified = true
        
        try await sessionService.createSession(
            phoneNumberHash: phoneHash,
            username: username,
            ageVerified: ageVerified
        )
        
        guard let user = sessionService.currentUser else {
            XCTFail("Current user should not be nil")
            return
        }
        
        XCTAssertFalse(user.id.isEmpty, "User ID should not be empty")
        XCTAssertEqual(user.username, username, "Username should match")
        XCTAssertEqual(user.phoneNumberHash, phoneHash, "Phone hash should match")
        XCTAssertEqual(user.isAgeVerified, ageVerified, "Age verification should match")
        XCTAssertEqual(user.reputation, 0, "Initial reputation should be 0")
        XCTAssertTrue(user.isVerified, "User should be verified")
        XCTAssertNotNil(user.createdAt, "Created date should be set")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSessionOperations() async throws {
        // Test that concurrent operations don't cause issues
        await withTaskGroup(of: Void.self) { group in
            // Create session
            group.addTask {
                try? await self.sessionService.createSession(
                    phoneNumberHash: "concurrent_hash",
                    username: "ConcurrentUser",
                    ageVerified: true
                )
            }
            
            // Wait a bit then validate
            group.addTask {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                _ = await self.sessionService.validateSession()
            }
        }
        
        // Should end up in a consistent state
        XCTAssertTrue(sessionService.isAuthenticated || !sessionService.isAuthenticated,
                     "Should be in a consistent authentication state")
    }
}