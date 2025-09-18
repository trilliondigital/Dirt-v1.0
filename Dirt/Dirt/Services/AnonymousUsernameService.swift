import Foundation

@MainActor
class AnonymousUsernameService: ObservableObject {
    static let shared = AnonymousUsernameService()
    
    private init() {}
    
    // MARK: - Username Generation
    
    func generateUsername() -> String {
        let adjectives = [
            "Swift", "Bold", "Wise", "Cool", "Sharp", "Bright", "Strong", "Quick", 
            "Smart", "Brave", "Silent", "Fierce", "Noble", "Calm", "Steady", "Alert",
            "Clever", "Keen", "Agile", "Solid", "Smooth", "Clear", "Pure", "True",
            "Wild", "Free", "Dark", "Light", "Deep", "High", "Fast", "Slow"
        ]
        
        let nouns = [
            "Wolf", "Eagle", "Lion", "Tiger", "Bear", "Hawk", "Fox", "Shark", 
            "Falcon", "Panther", "Dragon", "Phoenix", "Raven", "Viper", "Lynx", "Jaguar",
            "Cobra", "Stallion", "Rhino", "Bison", "Moose", "Stag", "Ram", "Bull",
            "Knight", "Warrior", "Hunter", "Scout", "Ranger", "Guardian", "Sentinel", "Nomad"
        ]
        
        let numbers = String(Int.random(in: 100...999))
        
        let adjective = adjectives.randomElement() ?? "Anonymous"
        let noun = nouns.randomElement() ?? "User"
        
        return "\(adjective)\(noun)\(numbers)"
    }
    
    func generateMultipleUsernames(count: Int = 3) -> [String] {
        var usernames: Set<String> = []
        
        while usernames.count < count {
            usernames.insert(generateUsername())
        }
        
        return Array(usernames)
    }
    
    // MARK: - Username Validation
    
    func isValidUsername(_ username: String) -> Bool {
        // Check length (should be reasonable)
        guard username.count >= 3 && username.count <= 50 else {
            return false
        }
        
        // Check for allowed characters (alphanumeric only)
        let allowedCharacters = CharacterSet.alphanumerics
        let usernameCharacterSet = CharacterSet(charactersIn: username)
        
        return allowedCharacters.isSuperset(of: usernameCharacterSet)
    }
    
    func validateUsernameFormat(_ username: String) -> UsernameValidationResult {
        if username.isEmpty {
            return .invalid("Username cannot be empty")
        }
        
        if username.count < 3 {
            return .invalid("Username must be at least 3 characters")
        }
        
        if username.count > 50 {
            return .invalid("Username must be less than 50 characters")
        }
        
        let allowedCharacters = CharacterSet.alphanumerics
        let usernameCharacterSet = CharacterSet(charactersIn: username)
        
        if !allowedCharacters.isSuperset(of: usernameCharacterSet) {
            return .invalid("Username can only contain letters and numbers")
        }
        
        // Check for inappropriate content (basic check)
        let lowercaseUsername = username.lowercased()
        let inappropriateWords = ["admin", "moderator", "support", "help", "test", "null", "undefined"]
        
        for word in inappropriateWords {
            if lowercaseUsername.contains(word) {
                return .invalid("Username contains restricted words")
            }
        }
        
        return .valid
    }
    
    // MARK: - Username Availability (Mock Implementation)
    
    func checkUsernameAvailability(_ username: String) async -> UsernameAvailabilityResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock implementation - in real app, this would check against backend
        let unavailableUsernames = ["admin", "test", "user", "guest", "anonymous"]
        
        if unavailableUsernames.contains(username.lowercased()) {
            return .unavailable("Username is already taken")
        }
        
        // Simulate random unavailability for demonstration
        if Int.random(in: 1...10) <= 2 { // 20% chance of being unavailable
            return .unavailable("Username is already taken")
        }
        
        return .available
    }
}

// MARK: - Supporting Types

enum UsernameValidationResult {
    case valid
    case invalid(String)
}

enum UsernameAvailabilityResult {
    case available
    case unavailable(String)
    case error(String)
}