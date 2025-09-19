import Foundation

// MARK: - ReportService
// Centralizes report submissions and routes to backend when enabled.
struct ReportService {
    // Toggle backend usage via ModerationService
    static var backendEnabled: Bool {
        get { ModerationService.shared.backendEnabled }
        set { ModerationService.shared.backendEnabled = newValue }
    }

    @MainActor
    static func submitReport(postId: UUID, reason: ReportReason) {
        let payload: [String: Any] = [
            "postId": postId.uuidString,
            "reason": reason.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        debugPrint("[ReportService] submitReport:", payload)
        AnalyticsService.shared.trackUserAction("report_submitted", parameters: [
            "post_id": postId.uuidString,
            "reason": reason.rawValue
        ])

        // Always enqueue locally for soft-hide policy
        ModerationQueue.shared.enqueue(postId: postId, reason: reason.rawValue)
        let autoHide = ModerationQueue.shared.shouldAutoHide(postId: postId)
        debugPrint("[ReportService] moderation: shouldAutoHide=", autoHide)

        // If backend enabled, also submit to backend asynchronously with retry
        if backendEnabled {
            Task {
                do {
                    try await submitReportWithRetry(postId: postId, reason: reason)
                } catch {
                    debugPrint("[ReportService] backend submit failed after retries:", String(describing: error))
                    await AnalyticsService.shared.trackUserAction("report_submit_failed", parameters: [
                        "post_id": postId.uuidString,
                        "reason": reason.rawValue
                    ])
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

    // Async API that throws on failure and retries transient errors
    static func submitReportWithRetry(postId: UUID, reason: ReportReason) async throws {
        // Already enqueued locally in the non-throwing API. If callers invoke this directly,
        // ensure local enqueue still happens to keep behavior consistent.
        ModerationQueue.shared.enqueue(postId: postId, reason: reason.rawValue)

        guard backendEnabled else { return }

        func isTransient(_ error: Error) -> Bool {
            if error is URLError { return true }
            let ns = error as NSError
            if ns.domain == "SupabaseFunction" { return ns.code >= 500 || ns.code == 429 }
            return false
        }

        _ = try await Retry.withExponentialBackoff(
            .init(maxAttempts: 3, initialDelay: 0.6, multiplier: 2.0, jitter: 0.25),
            shouldRetry: { isTransient($0) }
        ) {
            try await ModerationService.shared.submitReport(postId: postId, reason: reason.rawValue)
        }
    }
}