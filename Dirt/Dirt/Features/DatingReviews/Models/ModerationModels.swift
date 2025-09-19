import Foundation
import UIKit

// MARK: - Moderation Status
enum ModerationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case flagged = "flagged"
    case appealed = "appealed"
    case underReview = "under_review"
}

// MARK: - Content Type
enum ContentType: String, Codable {
    case review = "review"
    case post = "post"
    case comment = "comment"
    case image = "image"
}

// MARK: - Moderation Flag Types
enum ModerationFlag: String, Codable, CaseIterable {
    case personalInformation = "personal_information"
    case inappropriateContent = "inappropriate_content"
    case spam = "spam"
    case harassment = "harassment"
    case violentContent = "violent_content"
    case hateSpeech = "hate_speech"
    case sexualContent = "sexual_content"
    case misinformation = "misinformation"
    case copyrightViolation = "copyright_violation"
    case other = "other"
    
    var description: String {
        switch self {
        case .personalInformation:
            return "Personal Information Detected"
        case .inappropriateContent:
            return "Inappropriate Content"
        case .spam:
            return "Spam"
        case .harassment:
            return "Harassment"
        case .violentContent:
            return "Violent Content"
        case .hateSpeech:
            return "Hate Speech"
        case .sexualContent:
            return "Sexual Content"
        case .misinformation:
            return "Misinformation"
        case .copyrightViolation:
            return "Copyright Violation"
        case .other:
            return "Other Violation"
        }
    }
    
    var severity: ModerationSeverity {
        switch self {
        case .personalInformation, .harassment, .hateSpeech, .violentContent:
            return .high
        case .inappropriateContent, .sexualContent, .misinformation:
            return .medium
        case .spam, .copyrightViolation, .other:
            return .low
        }
    }
}

// MARK: - Moderation Severity
enum ModerationSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var autoActionThreshold: Double {
        switch self {
        case .low:
            return 0.9
        case .medium:
            return 0.8
        case .high:
            return 0.7
        case .critical:
            return 0.6
        }
    }
}

// MARK: - Moderation Result
struct ModerationResult: Codable {
    let contentId: UUID
    let contentType: ContentType
    let status: ModerationStatus
    let flags: [ModerationFlag]
    let confidence: Double
    let severity: ModerationSeverity
    let reason: String?
    let detectedPII: [PIIDetection]
    let createdAt: Date
    let reviewedAt: Date?
    let reviewedBy: UUID?
    let notes: String?
    
    var requiresHumanReview: Bool {
        return confidence < severity.autoActionThreshold || 
               flags.contains { $0.severity == .high || $0.severity == .critical }
    }
}

// MARK: - PII Detection
struct PIIDetection: Codable {
    let type: PIIType
    let location: CGRect
    let confidence: Double
    let text: String?
}

enum PIIType: String, Codable, CaseIterable {
    case name = "name"
    case phoneNumber = "phone_number"
    case email = "email"
    case socialMedia = "social_media"
    case address = "address"
    case creditCard = "credit_card"
    case ssn = "ssn"
    case other = "other"
    
    var description: String {
        switch self {
        case .name:
            return "Name"
        case .phoneNumber:
            return "Phone Number"
        case .email:
            return "Email Address"
        case .socialMedia:
            return "Social Media Handle"
        case .address:
            return "Address"
        case .creditCard:
            return "Credit Card"
        case .ssn:
            return "Social Security Number"
        case .other:
            return "Other Personal Information"
        }
    }
}

// MARK: - Moderation Queue Item
struct ModerationQueueItem: Identifiable, Codable {
    let id: UUID
    let contentId: UUID
    let contentType: ContentType
    let authorId: UUID
    let content: String?
    let imageUrls: [String]
    let moderationResult: ModerationResult
    let reportCount: Int
    let priority: ModerationPriority
    let createdAt: Date
    let updatedAt: Date
    
    var isHighPriority: Bool {
        return priority == .high || priority == .critical ||
               moderationResult.severity == .high || moderationResult.severity == .critical
    }
}

enum ModerationPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var sortOrder: Int {
        switch self {
        case .critical:
            return 0
        case .high:
            return 1
        case .medium:
            return 2
        case .low:
            return 3
        }
    }
}

// MARK: - Moderation Action
struct ModerationAction: Codable {
    let id: UUID
    let contentId: UUID
    let moderatorId: UUID
    let action: ModerationActionType
    let reason: String
    let notes: String?
    let createdAt: Date
}

enum ModerationActionType: String, Codable {
    case approve = "approve"
    case reject = "reject"
    case edit = "edit"
    case flag = "flag"
    case ban = "ban"
    case warn = "warn"
    case delete = "delete"
}