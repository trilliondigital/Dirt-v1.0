import Foundation

// MARK: - ReportService
// Centralizes report submissions and routes to backend when enabled.
struct ReportService {
    // Toggle backend usage via ModerationService
    static var backendEnabled: Bool {
        get { ModerationService.shared.backendEnabled }
        set { ModerationService.shared.backendEnabled = newValue }
    }

    static func submitReport(postId: UUID, reason: ReportReason) {
        let payload: [String: Any] = [
            "postId": postId.uuidString,
            "reason": reason.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        debugPrint("[ReportService] submitReport:", payload)

        // Always enqueue locally for soft-hide policy
        ModerationQueue.shared.enqueue(postId: postId, reason: reason.rawValue)
        let autoHide = ModerationQueue.shared.shouldAutoHide(postId: postId)
        debugPrint("[ReportService] moderation: shouldAutoHide=", autoHide)

        // If backend enabled, also submit to backend asynchronously
        if backendEnabled {
            Task {
                do {
                    let record = try await ModerationService.shared.submitReport(postId: postId, reason: reason.rawValue)
                    debugPrint("[ReportService] backend submit ok:", record)
                } catch {
                    debugPrint("[ReportService] backend submit failed:", String(describing: error))
                }
            }
        }
    }

    static func submitReport(reason: ReportReason, metadata: [String: String] = [:]) {
        let payload: [String: Any] = [
            "reason": reason.rawValue,
            "metadata": metadata,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        debugPrint("[ReportService] submitReport (no id):", payload)
        // Optional: could forward metadata-only reports to backend when enabled
    }
}
