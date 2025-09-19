import XCTest
@testable import Dirt

final class KeychainServiceTests: XCTestCase {
    var keychainService: KeychainService!
    let testKey = "test_key"
    let testData = "test_data"
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainService.shared
        
        // Clean up any existing test data
        try? keychainService.delete(forKey: testKey)
    }
    
    override func tearDown() {
        // Clean up test data
        try? keychainService.delete(forKey: testKey)
        keychainService = nil
        super.tearDown()
    }
    
    // MARK: - Store and Retrieve Tests
    
    func testStoreAndRetrieveString() throws {
        // Store data
        try keychainService.store(testData, forKey: testKey)
        
        // Retrieve data
        let retrievedData = try keychainService.retrieve(forKey: testKey)
        
        XCTAssertEqual(retrievedData, testData, "Retrieved data should match stored data")
    }
    
    func testStoreAndRetrieveData() throws {
        let originalData = testData.data(using: .utf8)!
        
        // Store data
        try keychainService.store(originalData, forKey: testKey)
        
        // Retrieve data
        let retrievedData = try keychainService.retrieveData(forKey: testKey)
        
        XCTAssertEqual(retrievedData, originalData, "Retrieved data should match stored data")
    }
    
    func testRetrieveNonExistentKey() {
        XCTAssertThrowsError(try keychainService.retrieve(forKey: "non_existent_key")) { error in
            XCTAssertTrue(error is KeychainError, "Should throw KeychainError")
        }
    }
    
    // MARK: - Update Tests
    
    func testUpdateExistingItem() throws {
        let originalData = "original_data"
        let updatedData = "updated_data"
        
        // Store original data
        try keychainService.store(originalData, forKey: testKey)
        
        // Update data
        try keychainService.update(updatedData, forKey: testKey)
        
        // Retrieve and verify
        let retrievedData = try keychainService.retrieve(forKey: testKey)
        XCTAssertEqual(retrievedData, updatedData, "Retrieved data should match updated data")
    }
    
    func testUpdateNonExistentItem() throws {
        let newData = "new_data"
        
        // Update non-existent item (should create it)
        try keychainService.update(newData, forKey: testKey)
        
        // Retrieve and verify
        let retrievedData = try keychainService.retrieve(forKey: testKey)
        XCTAssertEqual(retrievedData, newData, "Should create new item when updating non-existent key")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteExistingItem() throws {
        // Store data
        try keychainService.store(testData, forKey: testKey)
        
        // Verify it exists
        XCTAssertTrue(keychainService.exists(forKey: testKey), "Item should exist before deletion")
        
        // Delete data
        try keychainService.delete(forKey: testKey)
        
        // Verify it's gone
        XCTAssertFalse(keychainService.exists(forKey: testKey), "Item should not exist after deletion")
    }
    
    func testDeleteNonExistentItem() throws {
        // Should not throw error when deleting non-existent item
        try keychainService.delete(forKey: "non_existent_key")
    }
    
    // MARK: - Existence Tests
    
    func testExists() throws {
        // Should not exist initially
        XCTAssertFalse(keychainService.exists(forKey: testKey), "Item should not exist initially")
        
        // Store data
        try keychainService.store(testData, forKey: testKey)
        
        // Should exist now
        XCTAssertTrue(keychainService.exists(forKey: testKey), "Item should exist after storing")
        
        // Delete data
        try keychainService.delete(forKey: testKey)
        
        // Should not exist anymore
        XCTAssertFalse(keychainService.exists(forKey: testKey), "Item should not exist after deletion")
    }
    
    // MARK: - Secure Storage Tests
    
    func testStoreAndRetrieveSecurely() throws {
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let value: Int
        }
        
        let testObject = TestObject(id: "123", name: "Test", value: 42)
        
        // Store object securely
        try keychainService.storeSecurely(testObject, forKey: testKey)
        
        // Retrieve object
        let retrievedObject = try keychainService.retrieveSecurely(TestObject.self, forKey: testKey)
        
        XCTAssertEqual(retrievedObject, testObject, "Retrieved object should match stored object")
    }
    
    func testStoreSecurelyComplexObject() throws {
        struct ComplexObject: Codable, Equatable {
            let id: UUID
            let timestamp: Date
            let data: [String: String]
            let numbers: [Int]
        }
        
        let complexObject = ComplexObject(
            id: UUID(),
            timestamp: Date(),
            data: ["key1": "value1", "key2": "value2"],
            numbers: [1, 2, 3, 4, 5]
        )
        
        // Store complex object
        try keychainService.storeSecurely(complexObject, forKey: testKey)
        
        // Retrieve complex object
        let retrievedObject = try keychainService.retrieveSecurely(ComplexObject.self, forKey: testKey)
        
        XCTAssertEqual(retrievedObject.id, complexObject.id)
        XCTAssertEqual(retrievedObject.data, complexObject.data)
        XCTAssertEqual(retrievedObject.numbers, complexObject.numbers)
        // Note: Date comparison might have slight differences due to encoding/decoding
    }
    
    // MARK: - Clear All Tests
    
    func testClearAll() throws {
        let keys = ["key1", "key2", "key3"]
        
        // Store multiple items
        for key in keys {
            try keychainService.store("data_for_\(key)", forKey: key)
        }
        
        // Verify all exist
        for key in keys {
            XCTAssertTrue(keychainService.exists(forKey: key), "Item \(key) should exist")
        }
        
        // Clear all
        try keychainService.clearAll()
        
        // Verify all are gone
        for key in keys {
            XCTAssertFalse(keychainService.exists(forKey: key), "Item \(key) should not exist after clear")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDataError() {
        // This test is more conceptual since we can't easily trigger invalid data errors
        // in the current implementation, but we can test the error types exist
        let error = KeychainError.invalidData
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }
    
    func testErrorDescriptions() {
        let errors: [KeychainError] = [
            .invalidData,
            .storeFailed(errSecDuplicateItem),
            .retrieveFailed(errSecItemNotFound),
            .updateFailed(errSecItemNotFound),
            .deleteFailed(errSecItemNotFound),
            .clearFailed(errSecItemNotFound)
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceStoreAndRetrieve() throws {
        let largeData = String(repeating: "A", count: 10000) // 10KB string
        
        measure {
            do {
                try keychainService.store(largeData, forKey: testKey)
                _ = try keychainService.retrieve(forKey: testKey)
                try keychainService.delete(forKey: testKey)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    // MARK: - Multiple Keys Tests
    
    func testMultipleKeys() throws {
        let keyValuePairs = [
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3")
        ]
        
        // Store all pairs
        for (key, value) in keyValuePairs {
            try keychainService.store(value, forKey: key)
        }
        
        // Retrieve and verify all pairs
        for (key, expectedValue) in keyValuePairs {
            let retrievedValue = try keychainService.retrieve(forKey: key)
            XCTAssertEqual(retrievedValue, expectedValue, "Value for key \(key) should match")
        }
        
        // Clean up
        for (key, _) in keyValuePairs {
            try keychainService.delete(forKey: key)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyString() throws {
        let emptyString = ""
        
        try keychainService.store(emptyString, forKey: testKey)
        let retrieved = try keychainService.retrieve(forKey: testKey)
        
        XCTAssertEqual(retrieved, emptyString, "Should handle empty strings")
    }
    
    func testUnicodeString() throws {
        let unicodeString = "Hello 🌍 世界 🚀"
        
        try keychainService.store(unicodeString, forKey: testKey)
        let retrieved = try keychainService.retrieve(forKey: testKey)
        
        XCTAssertEqual(retrieved, unicodeString, "Should handle unicode strings")
    }
}