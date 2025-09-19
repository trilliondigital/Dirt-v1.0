import Foundation
import SwiftUI

struct PasswordStrength {
    let score: Int // 0-4
    let feedback: [String]
    let color: Color
    let label: String
    
    static let weak = PasswordStrength(score: 0, feedback: [], color: .red, label: "Weak")
    static let fair = PasswordStrength(score: 1, feedback: [], color: .orange, label: "Fair")
    static let good = PasswordStrength(score: 2, feedback: [], color: .yellow, label: "Good")
    static let strong = PasswordStrength(score: 3, feedback: [], color: .green, label: "Strong")
    static let veryStrong = PasswordStrength(score: 4, feedback: [], color: .blue, label: "Very Strong")
}

class PasswordValidator: ObservableObject {
    @Published var strength: PasswordStrength = .weak
    @Published var isValid: Bool = false
    
    func validatePassword(_ password: String) {
        let feedback = generateFeedback(for: password)
        let score = calculateScore(for: password)
        
        strength = PasswordStrength(
            score: score,
            feedback: feedback,
            color: colorForScore(score),
            label: labelForScore(score)
        )
        
        isValid = score >= 2 && password.count >= 8
    }
    
    private func calculateScore(for password: String) -> Int {
        var score = 0
        
        // Length bonus
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character variety
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        // Penalize common patterns
        if isCommonPassword(password) { score -= 2 }
        if hasRepeatingCharacters(password) { score -= 1 }
        if hasSequentialCharacters(password) { score -= 1 }
        
        return max(0, min(4, score))
    }
    
    private func generateFeedback(for password: String) -> [String] {
        var feedback: [String] = []
        
        if password.count < 8 {
            feedback.append("Use at least 8 characters")
        }
        
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            feedback.append("Add lowercase letters")
        }
        
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            feedback.append("Add uppercase letters")
        }
        
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            feedback.append("Add numbers")
        }
        
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) == nil {
            feedback.append("Add special characters")
        }
        
        if isCommonPassword(password) {
            feedback.append("Avoid common passwords")
        }
        
        if hasRepeatingCharacters(password) {
            feedback.append("Avoid repeating characters")
        }
        
        if hasSequentialCharacters(password) {
            feedback.append("Avoid sequential characters")
        }
        
        return feedback
    }
    
    private func isCommonPassword(_ password: String) -> Bool {
        let commonPasswords = [
            "password", "123456", "123456789", "12345678", "12345",
            "1234567", "qwerty", "abc123", "password123", "admin",
            "letmein", "welcome", "monkey", "dragon", "master"
        ]
        return commonPasswords.contains(password.lowercased())
    }
    
    private func hasRepeatingCharacters(_ password: String) -> Bool {
        let chars = Array(password)
        for i in 0..<chars.count-2 {
            if chars[i] == chars[i+1] && chars[i+1] == chars[i+2] {
                return true
            }
        }
        return false
    }
    
    private func hasSequentialCharacters(_ password: String) -> Bool {
        let chars = Array(password.lowercased())
        for i in 0..<chars.count-2 {
            let first = chars[i].asciiValue ?? 0
            let second = chars[i+1].asciiValue ?? 0
            let third = chars[i+2].asciiValue ?? 0
            
            if second == first + 1 && third == second + 1 {
                return true
            }
        }
        return false
    }
    
    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        case 4: return .blue
        default: return .gray
        }
    }
    
    private func labelForScore(_ score: Int) -> String {
        switch score {
        case 0: return "Weak"
        case 1: return "Fair"
        case 2: return "Good"
        case 3: return "Strong"
        case 4: return "Very Strong"
        default: return "Unknown"
        }
    }
}

// MARK: - SwiftUI Components

struct PasswordStrengthMeter: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(strength.label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strength.color)
            }
            
            // Strength bar
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(index <= strength.score ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                }
            }
            
            // Feedback
            if !strength.feedback.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(strength.feedback, id: \.self) { feedback in
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(feedback)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}