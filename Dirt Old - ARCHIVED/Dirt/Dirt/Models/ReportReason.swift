import Foundation

/// Reasons for reporting content
enum ReportReason: String, CaseIterable, Identifiable, Codable {
    case spam = "Spam"
    case harassment = "Harassment"
    case inappropriateContent = "Inappropriate Content"
    case misinformation = "Misinformation"
    case violence = "Violence"
    case hateSpeech = "Hate Speech"
    case other = "Other"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .spam:
            return "Unwanted commercial content or repetitive posts"
        case .harassment:
            return "Bullying, intimidation, or targeted harassment"
        case .inappropriateContent:
            return "Content that violates community guidelines"
        case .misinformation:
            return "False or misleading information"
        case .violence:
            return "Content that promotes or depicts violence"
        case .hateSpeech:
            return "Content that attacks or demeans individuals or groups"
        case .other:
            return "Other violations not covered above"
        }
    }
}