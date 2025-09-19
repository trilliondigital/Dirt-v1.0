import Foundation

public struct Validation {
    public static func isNonEmpty(_ text: String, max: Int? = nil) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let max = max { return !trimmed.isEmpty && trimmed.count <= max }
        return !trimmed.isEmpty
    }
}