import Foundation

public enum ReportStatus: String, Codable {
    case pending
    case reviewed
    case actioned
    case dismissed
}

public struct ReportRecord: Identifiable, Codable {
    public let id: UUID
    public let postId: UUID
    public let reason: String
    public let createdAt: Date
    public var status: ReportStatus
    public var notes: String?
}

final class ModerationService {
    static let shared = ModerationService()
    private init() {}

    // Toggle to route to backend when available
    var backendEnabled: Bool = false

    // MARK: - API surface (stubs)
    func submitReport(postId: UUID, reason: String, notes: String? = nil) async throws -> ReportRecord {
        if backendEnabled {
            do {
                let payload: [String: Any] = [
                    "post_id": postId.uuidString,
                    "reason": reason,
                    "notes": notes as Any
                ]
                let data = try await SupabaseManager.shared.callEdgeFunction(name: "moderation-submit", json: payload)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(ReportRecord.self, from: data)
            } catch {
                // Fallback to stub on failure
                debugPrint("[ModerationService] moderation-submit failed, falling back:", String(describing: error))
            }
        }
        // Stub fallback
        try await Task.sleep(nanoseconds: 300_000_000)
        return ReportRecord(id: UUID(), postId: postId, reason: reason, createdAt: Date(), status: .pending, notes: notes)
    }

    func fetchQueue(page: Int = 1, pageSize: Int = 20) async throws -> [ReportRecord] {
        if backendEnabled {
            do {
                let payload: [String: Any] = [
                    "page": page,
                    "page_size": pageSize
                ]
                let data = try await SupabaseManager.shared.callEdgeFunction(name: "moderation-queue", json: payload)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([ReportRecord].self, from: data)
            } catch {
                debugPrint("[ModerationService] moderation-queue failed, falling back:", String(describing: error))
            }
        }
        // Stub fallback
        try await Task.sleep(nanoseconds: 250_000_000)
        return (0..<min(pageSize, 10)).map { _ in
            ReportRecord(id: UUID(), postId: UUID(), reason: "red flag", createdAt: Date().addingTimeInterval(-Double.random(in: 1_000...80_000)), status: .pending, notes: nil)
        }
    }

    func updateReportStatus(reportId: UUID, status: ReportStatus, notes: String? = nil) async throws -> ReportRecord {
        if backendEnabled {
            do {
                let payload: [String: Any] = [
                    "report_id": reportId.uuidString,
                    "status": status.rawValue,
                    "notes": notes as Any
                ]
                let data = try await SupabaseManager.shared.callEdgeFunction(name: "moderation-update", json: payload)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(ReportRecord.self, from: data)
            } catch {
                debugPrint("[ModerationService] moderation-update failed, falling back:", String(describing: error))
            }
        }
        // Stub fallback echo
        try await Task.sleep(nanoseconds: 200_000_000)
        return ReportRecord(id: reportId, postId: UUID(), reason: "red flag", createdAt: Date().addingTimeInterval(-10_000), status: status, notes: notes)
    }
}
