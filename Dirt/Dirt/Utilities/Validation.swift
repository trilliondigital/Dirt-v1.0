import Foundation

public enum ReportReason: String, CaseIterable, Identifiable, Codable {
    case harassment = "Harassment or hate"
    case doxxing = "PII / Doxxing"
    case spam = "Spam or scams"
    case misinformation = "Misinformation"
    case illegal = "Illegal content"
    case other = "Other"
    
    public var id: String { rawValue }
}

public struct Validation {
    public static func isNonEmpty(_ text: String, max: Int? = nil) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let max = max { return !trimmed.isEmpty && trimmed.count <= max }
        return !trimmed.isEmpty
    }
}
