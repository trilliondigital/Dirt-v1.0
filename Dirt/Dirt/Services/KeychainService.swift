import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.trilliondigi.dirt"
    
    private init() {}
    
    // MARK: - Store Data
    
    func store(_ data: String, forKey key: String) throws {
        guard let data = data.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        try store(data, forKey: key)
    }
    
    func store(_ data: Data, forKey key: String) throws {
        // Delete any existing item first
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    // MARK: - Retrieve Data
    
    func retrieve(forKey key: String) throws -> String {
        let data = try retrieveData(forKey: key)
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    func retrieveData(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    // MARK: - Update Data
    
    func update(_ data: String, forKey key: String) throws {
        guard let data = data.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        try update(data, forKey: key)
    }
    
    func update(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            // If item doesn't exist, create it
            if status == errSecItemNotFound {
                try store(data, forKey: key)
            } else {
                throw KeychainError.updateFailed(status)
            }
        }
    }
    
    // MARK: - Delete Data
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    // MARK: - Check Existence
    
    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Clear All Data
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.clearFailed(status)
        }
    }
    
    // MARK: - Secure Storage for Sensitive Data
    
    func storeSecurely<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try store(data, forKey: key)
    }
    
    func retrieveSecurely<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        let data = try retrieveData(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Error Types

enum KeychainError: LocalizedError {
    case invalidData
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case updateFailed(OSStatus)
    case deleteFailed(OSStatus)
    case clearFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .storeFailed(let status):
            return "Failed to store item in keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from keychain (status: \(status))"
        case .updateFailed(let status):
            return "Failed to update item in keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete item from keychain (status: \(status))"
        case .clearFailed(let status):
            return "Failed to clear keychain (status: \(status))"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidData:
            return "Ensure the data is in the correct format"
        case .storeFailed, .retrieveFailed, .updateFailed, .deleteFailed, .clearFailed:
            return "Check device security settings and try again"
        }
    }
}