import Foundation

// MARK: - ReportService (stub)
// Centralizes report submissions for future backend integration.
// For now, it logs to the console. Replace with API calls later.
struct ReportService {
    static func submitReport(postId: UUID, reason: ReportReason) {
        let payload: [String: Any] = [
            "postId": postId.uuidString,
            "reason": reason.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        debugPrint("[ReportService] submitReport:", payload)
    }
    
    static func submitReport(reason: ReportReason, metadata: [String: String] = [:]) {
        let payload: [String: Any] = [
            "reason": reason.rawValue,
            "metadata": metadata,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        debugPrint("[ReportService] submitReport (no id):", payload)
    }
}
