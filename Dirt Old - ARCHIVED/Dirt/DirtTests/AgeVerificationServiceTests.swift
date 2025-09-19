import XCTest
@testable import Dirt

@MainActor
final class AgeVerificationServiceTests: XCTestCase {
    var ageVerificationService: AgeVerificationService!
    
    override func setUp() {
        super.setUp()
        ageVerificationService = AgeVerificationService.shared
    }
    
    override func tearDown() {
        ageVerificationService = nil
        super.tearDown()
    }
    
    // MARK: - Age Verification Tests
    
    func testVerifyAge_ValidAdult() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
        
        let result = ageVerificationService.verifyAge(birthDate: birthDate)
        
        switch result {
        case .verified(let age):
            XCTAssertEqual(age, 25)
        default:
            XCTFail("Expected verified result for valid adult age")
        }
    }
    
    func testVerifyAge_ExactlyEighteen() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -18, to: Date())!
        
        let result = ageVerificationService.verifyAge(birthDate: birthDate)
        
        switch result {
        case .verified(let age):
            XCTAssertEqual(age, 18)
        default:
            XCTFail("Expected verified result for exactly 18 years old")
        }
    }
    
    func testVerifyAge_TooYoung() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -17, to: Date())!
        
        let result = ageVerificationService.verifyAge(birthDate: birthDate)
        
        switch result {
        case .tooYoung(let message):
            XCTAssertTrue(message.contains("18"))
        default:
            XCTFail("Expected tooYoung result for underage user")
        }
    }
    
    func testVerifyAge_FutureBirthDate() {
        let calendar = Calendar.current
        let futureBirthDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        let result = ageVerificationService.verifyAge(birthDate: futureBirthDate)
        
        switch result {
        case .invalid(let message):
            XCTAssertTrue(message.contains("future"))
        default:
            XCTFail("Expected invalid result for future birth date")
        }
    }
    
    func testVerifyAge_TooOld() {
        let calendar = Calendar.current
        let veryOldBirthDate = calendar.date(byAdding: .year, value: -150, to: Date())!
        
        let result = ageVerificationService.verifyAge(birthDate: veryOldBirthDate)
        
        switch result {
        case .invalid(let message):
            XCTAssertTrue(message.contains("valid"))
        default:
            XCTFail("Expected invalid result for unreasonably old birth date")
        }
    }
    
    // MARK: - Age Calculation Tests
    
    func testCalculateAge_ValidDate() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -30, to: Date())!
        
        let age = ageVerificationService.calculateAge(from: birthDate)
        
        XCTAssertEqual(age, 30)
    }
    
    func testCalculateAge_InvalidDate() {
        let futureBirthDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        let age = ageVerificationService.calculateAge(from: futureBirthDate)
        
        // Should still calculate age even if negative
        XCTAssertNotNil(age)
        XCTAssertLessThan(age!, 0)
    }
    
    // MARK: - Birth Date Validation Tests
    
    func testIsValidBirthDate_ValidDate() {
        let calendar = Calendar.current
        let validBirthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
        
        let isValid = ageVerificationService.isValidBirthDate(validBirthDate)
        
        XCTAssertTrue(isValid)
    }
    
    func testIsValidBirthDate_FutureDate() {
        let futureBirthDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let isValid = ageVerificationService.isValidBirthDate(futureBirthDate)
        
        XCTAssertFalse(isValid)
    }
    
    func testIsValidBirthDate_TooOld() {
        let calendar = Calendar.current
        let tooOldBirthDate = calendar.date(byAdding: .year, value: -150, to: Date())!
        
        let isValid = ageVerificationService.isValidBirthDate(tooOldBirthDate)
        
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Secure Verification Tests
    
    func testPerformSecureAgeVerification_ValidAge() async {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
        
        let result = await ageVerificationService.performSecureAgeVerification(birthDate: birthDate)
        
        switch result {
        case .verified(let age, let token):
            XCTAssertEqual(age, 25)
            XCTAssertFalse(token.isEmpty)
        default:
            XCTFail("Expected verified result for valid age")
        }
    }
    
    func testPerformSecureAgeVerification_TooYoung() async {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -16, to: Date())!
        
        let result = await ageVerificationService.performSecureAgeVerification(birthDate: birthDate)
        
        switch result {
        case .failed(let message):
            XCTAssertTrue(message.contains("18"))
        default:
            XCTFail("Expected failed result for underage user")
        }
    }
    
    // MARK: - Privacy Protection Tests
    
    func testHashBirthDate() {
        let calendar = Calendar.current
        let birthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
        
        let hash1 = ageVerificationService.hashBirthDate(birthDate)
        let hash2 = ageVerificationService.hashBirthDate(birthDate)
        
        XCTAssertEqual(hash1, hash2, "Hash should be consistent for the same date")
        XCTAssertFalse(hash1.isEmpty, "Hash should not be empty")
    }
    
    func testHashBirthDate_DifferentDates() {
        let calendar = Calendar.current
        let birthDate1 = calendar.date(byAdding: .year, value: -25, to: Date())!
        let birthDate2 = calendar.date(byAdding: .year, value: -30, to: Date())!
        
        let hash1 = ageVerificationService.hashBirthDate(birthDate1)
        let hash2 = ageVerificationService.hashBirthDate(birthDate2)
        
        XCTAssertNotEqual(hash1, hash2, "Different dates should produce different hashes")
    }
    
    func testShouldStoreBirthDate() {
        let shouldStore = ageVerificationService.shouldStoreBirthDate()
        
        XCTAssertFalse(shouldStore, "Birth date should not be stored for privacy reasons")
    }
}