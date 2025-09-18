import XCTest
@testable import Dirt

@MainActor
final class PhoneVerificationServiceTests: XCTestCase {
    var phoneVerificationService: PhoneVerificationService!
    
    override func setUp() {
        super.setUp()
        phoneVerificationService = PhoneVerificationService.shared
        phoneVerificationService.reset()
    }
    
    override func tearDown() {
        phoneVerificationService.reset()
        phoneVerificationService = nil
        super.tearDown()
    }
    
    // MARK: - Phone Number Validation Tests
    
    func testValidatePhoneNumber_ValidUSNumber() {
        let result = phoneVerificationService.validatePhoneNumber("5551234567")
        
        switch result {
        case .valid(let formatted):
            XCTAssertEqual(formatted, "+15551234567")
        case .invalid:
            XCTFail("Expected valid phone number")
        }
    }
    
    func testValidatePhoneNumber_ValidUSNumberWithCountryCode() {
        let result = phoneVerificationService.validatePhoneNumber("15551234567")
        
        switch result {
        case .valid(let formatted):
            XCTAssertEqual(formatted, "+15551234567")
        case .invalid:
            XCTFail("Expected valid phone number")
        }
    }
    
    func testValidatePhoneNumber_ValidInternationalNumber() {
        let result = phoneVerificationService.validatePhoneNumber("447911123456")
        
        switch result {
        case .valid(let formatted):
            XCTAssertEqual(formatted, "+447911123456")
        case .invalid:
            XCTFail("Expected valid phone number")
        }
    }
    
    func testValidatePhoneNumber_InvalidTooShort() {
        let result = phoneVerificationService.validatePhoneNumber("123456789")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid phone number")
        case .invalid(let message):
            XCTAssertEqual(message, "Phone number must be between 10-15 digits")
        }
    }
    
    func testValidatePhoneNumber_InvalidTooLong() {
        let result = phoneVerificationService.validatePhoneNumber("1234567890123456")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid phone number")
        case .invalid(let message):
            XCTAssertEqual(message, "Phone number must be between 10-15 digits")
        }
    }
    
    func testValidatePhoneNumber_InvalidContainsLetters() {
        let result = phoneVerificationService.validatePhoneNumber("555123abc7")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid phone number")
        case .invalid(let message):
            XCTAssertEqual(message, "Phone number can only contain digits")
        }
    }
    
    func testValidatePhoneNumber_FormattedInput() {
        let result = phoneVerificationService.validatePhoneNumber("(555) 123-4567")
        
        switch result {
        case .valid(let formatted):
            XCTAssertEqual(formatted, "+15551234567")
        case .invalid:
            XCTFail("Expected valid phone number")
        }
    }
    
    // MARK: - Phone Number Hashing Tests
    
    func testHashPhoneNumber_ConsistentHashing() {
        let phoneNumber = "+15551234567"
        let hash1 = phoneVerificationService.hashPhoneNumber(phoneNumber)
        let hash2 = phoneVerificationService.hashPhoneNumber(phoneNumber)
        
        XCTAssertEqual(hash1, hash2, "Hash should be consistent for the same input")
        XCTAssertFalse(hash1.isEmpty, "Hash should not be empty")
    }
    
    func testHashPhoneNumber_DifferentNumbers() {
        let phoneNumber1 = "+15551234567"
        let phoneNumber2 = "+15551234568"
        let hash1 = phoneVerificationService.hashPhoneNumber(phoneNumber1)
        let hash2 = phoneVerificationService.hashPhoneNumber(phoneNumber2)
        
        XCTAssertNotEqual(hash1, hash2, "Different phone numbers should produce different hashes")
    }
    
    func testHashPhoneNumber_ValidFormat() {
        let phoneNumber = "+15551234567"
        let hash = phoneVerificationService.hashPhoneNumber(phoneNumber)
        
        // SHA256 hash should be 64 characters long (32 bytes * 2 hex chars per byte)
        XCTAssertEqual(hash.count, 64, "SHA256 hash should be 64 characters long")
        
        // Should only contain hex characters
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(hash.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) },
                     "Hash should only contain hex characters")
    }
    
    // MARK: - SMS Verification Tests
    
    func testSendVerificationCode_ValidNumber() async throws {
        let phoneNumber = "5551234567"
        
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        XCTAssertNotNil(phoneVerificationService.verificationId, "Verification ID should be set")
        XCTAssertFalse(phoneVerificationService.canResend, "Should not be able to resend immediately")
        XCTAssertEqual(phoneVerificationService.attemptsRemaining, 3, "Should reset attempts to 3")
        XCTAssertNil(phoneVerificationService.errorMessage, "Should not have error message")
    }
    
    func testSendVerificationCode_InvalidNumber() async {
        let phoneNumber = "123"
        
        do {
            try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
            XCTFail("Should throw error for invalid phone number")
        } catch PhoneVerificationError.invalidPhoneNumber(let message) {
            XCTAssertEqual(message, "Phone number must be between 10-15 digits")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSendVerificationCode_ServiceUnavailable() async {
        let phoneNumber = "5550000000" // Special number that triggers service unavailable
        
        do {
            try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
            XCTFail("Should throw error for service unavailable")
        } catch PhoneVerificationError.serviceUnavailable {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testResendVerificationCode_WhenAllowed() async throws {
        let phoneNumber = "5551234567"
        
        // First send
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Manually allow resend for testing
        phoneVerificationService.canResend = true
        
        // Resend should work
        try await phoneVerificationService.resendVerificationCode(to: phoneNumber)
        
        XCTAssertNotNil(phoneVerificationService.verificationId)
    }
    
    func testResendVerificationCode_WhenNotAllowed() async {
        let phoneNumber = "5551234567"
        
        // First send
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Resend should fail because cooldown is active
        do {
            try await phoneVerificationService.resendVerificationCode(to: phoneNumber)
            XCTFail("Should throw error when resend not allowed")
        } catch PhoneVerificationError.resendNotAllowed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Code Verification Tests
    
    func testVerifyCode_ValidCode() async throws {
        let phoneNumber = "5551234567"
        let validCode = "123456"
        
        // First send verification code
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Verify with valid code
        let result = try await phoneVerificationService.verifyCode(validCode, for: phoneNumber)
        
        XCTAssertTrue(result.isVerified, "Should be verified with valid code")
        XCTAssertNotNil(result.phoneNumberHash, "Should have phone number hash")
        XCTAssertEqual(result.verificationId, phoneVerificationService.verificationId)
    }
    
    func testVerifyCode_InvalidCode() async throws {
        let phoneNumber = "5551234567"
        let invalidCode = "000000"
        
        // First send verification code
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Verify with invalid code
        let result = try await phoneVerificationService.verifyCode(invalidCode, for: phoneNumber)
        
        XCTAssertFalse(result.isVerified, "Should not be verified with invalid code")
        XCTAssertNil(result.phoneNumberHash, "Should not have phone number hash")
        XCTAssertEqual(phoneVerificationService.attemptsRemaining, 2, "Should decrement attempts")
        XCTAssertNotNil(phoneVerificationService.errorMessage, "Should have error message")
    }
    
    func testVerifyCode_TooManyAttempts() async throws {
        let phoneNumber = "5551234567"
        let invalidCode = "000000"
        
        // First send verification code
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Use up all attempts
        _ = try await phoneVerificationService.verifyCode(invalidCode, for: phoneNumber) // Attempt 1
        _ = try await phoneVerificationService.verifyCode(invalidCode, for: phoneNumber) // Attempt 2
        
        // Third attempt should throw error
        do {
            _ = try await phoneVerificationService.verifyCode(invalidCode, for: phoneNumber) // Attempt 3
            XCTFail("Should throw error after too many attempts")
        } catch PhoneVerificationError.tooManyAttempts {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testVerifyCode_NoVerificationInProgress() async {
        let phoneNumber = "5551234567"
        let code = "123456"
        
        // Try to verify without sending code first
        do {
            _ = try await phoneVerificationService.verifyCode(code, for: phoneNumber)
            XCTFail("Should throw error when no verification in progress")
        } catch PhoneVerificationError.noVerificationInProgress {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - State Management Tests
    
    func testReset() async throws {
        let phoneNumber = "5551234567"
        
        // Set up some state
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        phoneVerificationService.attemptsRemaining = 1
        phoneVerificationService.errorMessage = "Some error"
        
        // Reset
        phoneVerificationService.reset()
        
        // Verify state is reset
        XCTAssertNil(phoneVerificationService.verificationId)
        XCTAssertEqual(phoneVerificationService.attemptsRemaining, 3)
        XCTAssertNil(phoneVerificationService.errorMessage)
        XCTAssertTrue(phoneVerificationService.canResend)
        XCTAssertEqual(phoneVerificationService.resendCountdown, 0)
    }
    
    func testResendCooldown() async throws {
        let phoneNumber = "5551234567"
        
        // Send verification code
        try await phoneVerificationService.sendVerificationCode(to: phoneNumber)
        
        // Should not be able to resend immediately
        XCTAssertFalse(phoneVerificationService.canResend)
        XCTAssertEqual(phoneVerificationService.resendCountdown, 60)
        
        // Wait a bit and check countdown decreases
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        XCTAssertLessThan(phoneVerificationService.resendCountdown, 60)
    }
}