import Foundation

// MARK: - Model Validation Service
class ModelValidationService {
    static let shared = ModelValidationService()
    
    private init() {}
    
    // MARK: - User Validation
    func validateUser(_ user: User) throws {
        try user.validate()
        
        // Additional business logic validation
        guard user.anonymousUsername.count >= 3 && user.anonymousUsername.count <= 50 else {
            throw DatingReviewValidationError.invalidUsername
        }
        
        // Check for inappropriate usernames
        let inappropriateWords = ["admin", "moderator", "system", "bot", "test"]
        let lowercaseUsername = user.anonymousUsername.lowercased()
        
        for word in inappropriateWords {
            if lowercaseUsername.contains(word) {
                throw DatingReviewValidationError.invalidUsername
            }
        }
    }
    
    // MARK: - Review Validation
    func validateReview(_ review: Review) throws {
        try review.validate()
        
        // Additional validation
        guard review.content.count >= 10 && review.content.count <= 5000 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard review.profileScreenshots.count >= 1 && review.profileScreenshots.count <= 5 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        // Validate tags
        guard review.tags.count <= 10 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        for tag in review.tags {
            guard tag.count <= 50 else {
                throw DatingReviewValidationError.invalidContent
            }
        }
    }
    
    // MARK: - Dating Review Post Validation
    func validatePost(_ post: DatingReviewPost) throws {
        try post.validate()
        
        // Additional validation
        guard post.title.count >= 5 && post.title.count <= 200 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard post.content.count >= 10 && post.content.count <= 10000 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        // Validate tags
        guard post.tags.count <= 10 else {
            throw DatingReviewValidationError.invalidContent
        }
        
        for tag in post.tags {
            guard tag.count <= 50 else {
                throw DatingReviewValidationError.invalidContent
            }
        }
    }
    
    // MARK: - Comment Validation
    func validateComment(_ comment: Comment) throws {
        try comment.validate()
        
        // Additional validation
        guard comment.content.count >= 1 && comment.content.count <= 2000 else {
            throw DatingReviewValidationError.invalidContent
        }
    }
    
    // MARK: - Content Moderation Validation
    func validateForModeration(_ content: String) -> [ModerationFlag] {
        var flags: [ModerationFlag] = []
        
        // Check for personal information patterns
        if containsPersonalInfo(content) {
            flags.append(.personalInformation)
        }
        
        // Check for inappropriate language
        if containsInappropriateLanguage(content) {
            flags.append(.inappropriateLanguage)
        }
        
        // Check for spam patterns
        if containsSpamPatterns(content) {
            flags.append(.spam)
        }
        
        // Check for harassment patterns
        if containsHarassmentPatterns(content) {
            flags.append(.harassment)
        }
        
        return flags
    }
    
    // MARK: - Private Validation Helpers
    private func containsPersonalInfo(_ content: String) -> Bool {
        // Phone number pattern
        let phonePattern = #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#
        
        // Email pattern
        let emailPattern = #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#
        
        // Social media handle pattern
        let socialPattern = #"@[A-Za-z0-9_]{1,15}\b"#
        
        let patterns = [phonePattern, emailPattern, socialPattern]
        
        for pattern in patterns {
            if content.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func containsInappropriateLanguage(_ content: String) -> Bool {
        // This would typically use a more sophisticated content moderation service
        // For now, we'll use a basic word list approach
        let inappropriateWords = [
            // Add inappropriate words here - keeping minimal for example
            "spam", "scam", "fake"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for word in inappropriateWords {
            if lowercaseContent.contains(word) {
                return true
            }
        }
        
        return false
    }
    
    private func containsSpamPatterns(_ content: String) -> Bool {
        // Check for excessive repetition
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let uniqueWords = Set(words)
        
        // If less than 30% unique words, might be spam
        if words.count > 10 && Double(uniqueWords.count) / Double(words.count) < 0.3 {
            return true
        }
        
        // Check for excessive capitalization
        let uppercaseCount = content.filter { $0.isUppercase }.count
        if uppercaseCount > content.count / 2 && content.count > 20 {
            return true
        }
        
        // Check for excessive punctuation
        let punctuationCount = content.filter { "!?.,;:".contains($0) }.count
        if punctuationCount > content.count / 4 && content.count > 20 {
            return true
        }
        
        return false
    }
    
    private func containsHarassmentPatterns(_ content: String) -> Bool {
        // This would typically use ML models for harassment detection
        // For now, we'll use basic pattern matching
        let harassmentPatterns = [
            "kill yourself",
            "you should die",
            "worthless",
            "pathetic loser"
        ]
        
        let lowercaseContent = content.lowercased()
        
        for pattern in harassmentPatterns {
            if lowercaseContent.contains(pattern) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Moderation Flags
enum ModerationFlag: String, CaseIterable {
    case personalInformation = "personal_information"
    case inappropriateLanguage = "inappropriate_language"
    case spam = "spam"
    case harassment = "harassment"
    case violence = "violence"
    case hate = "hate"
    
    var description: String {
        switch self {
        case .personalInformation:
            return "Contains personal information"
        case .inappropriateLanguage:
            return "Contains inappropriate language"
        case .spam:
            return "Appears to be spam"
        case .harassment:
            return "Contains harassment"
        case .violence:
            return "Contains violent content"
        case .hate:
            return "Contains hate speech"
        }
    }
    
    var severity: ModerationSeverity {
        switch self {
        case .personalInformation:
            return .high
        case .inappropriateLanguage:
            return .medium
        case .spam:
            return .low
        case .harassment:
            return .high
        case .violence:
            return .critical
        case .hate:
            return .critical
        }
    }
}

// MARK: - Moderation Severity
enum ModerationSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    var autoAction: ModerationAction {
        switch self {
        case .low:
            return .flag
        case .medium:
            return .flag
        case .high:
            return .hide
        case .critical:
            return .remove
        }
    }
}

// MARK: - Moderation Action
enum ModerationAction: String, CaseIterable {
    case approve = "approve"
    case flag = "flag"
    case hide = "hide"
    case remove = "remove"
    case ban = "ban"
    
    var description: String {
        switch self {
        case .approve:
            return "Approve content"
        case .flag:
            return "Flag for review"
        case .hide:
            return "Hide content"
        case .remove:
            return "Remove content"
        case .ban:
            return "Ban user"
        }
    }
}