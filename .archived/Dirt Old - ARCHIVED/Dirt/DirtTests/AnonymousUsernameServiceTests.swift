import XCTest
@testable import Dirt

@MainActor
final class AnonymousUsernameServiceTests: XCTestCase {
    var usernameService: AnonymousUsernameService!
    
    override func setUp() {
        super.setUp()
        usernameService = AnonymousUsernameService.shared
    }
    
    override func tearDown() {
        usernameService = nil
        super.tearDown()
    }
    
    // MARK: - Username Generation Tests
    
    func testGenerateUsername() {
        let username = usernameService.generateUsername()
        
        XCTAssertFalse(username.isEmpty, "Generated username should not be empty")
        XCTAssertTrue(username.count >= 3, "Username should be at least 3 characters")
        XCTAssertTrue(username.count <= 50, "Username should be at most 50 characters")
    }
    
    func testGenerateUsername_Uniqueness() {
        let username1 = usernameService.generateUsername()
        let username2 = usernameService.generateUsername()
        
        // While not guaranteed to be different due to randomness,
        // they should be different most of the time
        XCTAssertNotEqual(username1, username2, "Generated usernames should typically be unique")
    }
    
    func testGenerateUsername_Format() {
        let username = usernameService.generateUsername()
        
        // Should contain only alphanumeric characters
        let allowedCharacters = CharacterSet.alphanumerics
        let usernameCharacterSet = CharacterSet(charactersIn: username)
        
        XCTAssertTrue(allowedCharacters.isSuperset(of: usernameCharacterSet),
                     "Username should only contain alphanumeric characters")
    }
    
    func testGenerateMultipleUsernames() {
        let usernames = usernameService.generateMultipleUsernames(count: 3)
        
        XCTAssertEqual(usernames.count, 3, "Should generate exactly 3 usernames")
        
        // Check that all usernames are unique
        let uniqueUsernames = Set(usernames)
        XCTAssertEqual(uniqueUsernames.count, 3, "All generated usernames should be unique")
        
        // Check that all usernames are valid
        for username in usernames {
            XCTAssertFalse(username.isEmpty, "Each username should not be empty")
            XCTAssertTrue(usernameService.isValidUsername(username), "Each username should be valid")
        }
    }
    
    func testGenerateMultipleUsernames_DefaultCount() {
        let usernames = usernameService.generateMultipleUsernames()
        
        XCTAssertEqual(usernames.count, 3, "Should generate 3 usernames by default")
    }
    
    // MARK: - Username Validation Tests
    
    func testIsValidUsername_ValidUsername() {
        let validUsernames = [
            "SwiftWolf123",
            "BoldEagle456",
            "Test123",
            "User1"
        ]
        
        for username in validUsernames {
            XCTAssertTrue(usernameService.isValidUsername(username),
                         "Username '\(username)' should be valid")
        }
    }
    
    func testIsValidUsername_InvalidUsername() {
        let invalidUsernames = [
            "", // Empty
            "ab", // Too short
            String(repeating: "a", count: 51), // Too long
            "user@name", // Contains special characters
            "user name", // Contains space
            "user-name", // Contains hyphen
            "user.name" // Contains period
        ]
        
        for username in invalidUsernames {
            XCTAssertFalse(usernameService.isValidUsername(username),
                          "Username '\(username)' should be invalid")
        }
    }
    
    func testValidateUsernameFormat_ValidUsername() {
        let result = usernameService.validateUsernameFormat("SwiftWolf123")
        
        switch result {
        case .valid:
            // Expected result
            break
        case .invalid(let message):
            XCTFail("Expected valid result, got invalid with message: \(message)")
        }
    }
    
    func testValidateUsernameFormat_EmptyUsername() {
        let result = usernameService.validateUsernameFormat("")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid result for empty username")
        case .invalid(let message):
            XCTAssertTrue(message.contains("empty"), "Error message should mention empty username")
        }
    }
    
    func testValidateUsernameFormat_TooShort() {
        let result = usernameService.validateUsernameFormat("ab")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid result for too short username")
        case .invalid(let message):
            XCTAssertTrue(message.contains("3 characters"), "Error message should mention minimum length")
        }
    }
    
    func testValidateUsernameFormat_TooLong() {
        let longUsername = String(repeating: "a", count: 51)
        let result = usernameService.validateUsernameFormat(longUsername)
        
        switch result {
        case .valid:
            XCTFail("Expected invalid result for too long username")
        case .invalid(let message):
            XCTAssertTrue(message.contains("50 characters"), "Error message should mention maximum length")
        }
    }
    
    func testValidateUsernameFormat_InvalidCharacters() {
        let result = usernameService.validateUsernameFormat("user@name")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid result for username with special characters")
        case .invalid(let message):
            XCTAssertTrue(message.contains("letters and numbers"), "Error message should mention allowed characters")
        }
    }
    
    func testValidateUsernameFormat_RestrictedWords() {
        let restrictedUsernames = ["admin", "moderator", "support", "help", "test"]
        
        for username in restrictedUsernames {
            let result = usernameService.validateUsernameFormat(username)
            
            switch result {
            case .valid:
                XCTFail("Expected invalid result for restricted username: \(username)")
            case .invalid(let message):
                XCTAssertTrue(message.contains("restricted"), "Error message should mention restricted words")
            }
        }
    }
    
    func testValidateUsernameFormat_RestrictedWordsInLargerUsername() {
        let result = usernameService.validateUsernameFormat("MyAdminAccount")
        
        switch result {
        case .valid:
            XCTFail("Expected invalid result for username containing restricted word")
        case .invalid(let message):
            XCTAssertTrue(message.contains("restricted"), "Error message should mention restricted words")
        }
    }
    
    // MARK: - Username Availability Tests
    
    func testCheckUsernameAvailability_Available() async {
        let result = await usernameService.checkUsernameAvailability("UniqueUsername123")
        
        // Note: This is a mock implementation, so we can't guarantee the result
        // But we can test that it returns a valid result type
        switch result {
        case .available:
            // Expected for most usernames
            break
        case .unavailable(let message):
            XCTAssertFalse(message.isEmpty, "Unavailable message should not be empty")
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }
    
    func testCheckUsernameAvailability_KnownUnavailable() async {
        let result = await usernameService.checkUsernameAvailability("admin")
        
        switch result {
        case .available:
            XCTFail("Expected unavailable result for 'admin' username")
        case .unavailable(let message):
            XCTAssertTrue(message.contains("taken"), "Message should indicate username is taken")
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }
    
    func testCheckUsernameAvailability_CaseInsensitive() async {
        let result = await usernameService.checkUsernameAvailability("ADMIN")
        
        switch result {
        case .available:
            XCTFail("Expected unavailable result for 'ADMIN' username (case insensitive)")
        case .unavailable(let message):
            XCTAssertTrue(message.contains("taken"), "Message should indicate username is taken")
        case .error(let message):
            XCTFail("Unexpected error: \(message)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testGenerateAndValidateUsername() {
        let username = usernameService.generateUsername()
        
        // Generated username should pass validation
        XCTAssertTrue(usernameService.isValidUsername(username),
                     "Generated username should be valid")
        
        let validationResult = usernameService.validateUsernameFormat(username)
        switch validationResult {
        case .valid:
            // Expected result
            break
        case .invalid(let message):
            XCTFail("Generated username should pass format validation, but got: \(message)")
        }
    }
    
    func testGenerateMultipleAndValidateAll() {
        let usernames = usernameService.generateMultipleUsernames(count: 5)
        
        for username in usernames {
            XCTAssertTrue(usernameService.isValidUsername(username),
                         "Generated username '\(username)' should be valid")
            
            let validationResult = usernameService.validateUsernameFormat(username)
            switch validationResult {
            case .valid:
                // Expected result
                break
            case .invalid(let message):
                XCTFail("Generated username '\(username)' should pass format validation, but got: \(message)")
            }
        }
    }
}