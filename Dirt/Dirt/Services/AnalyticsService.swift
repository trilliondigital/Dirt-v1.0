import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    struct Event: Codable { let name: String; let params: [String: String]; let ts: Date }
    private let queue = DispatchQueue(label: "analytics.queue")

    func log(_ name: String, _ params: [String: String] = [:]) {
        let event = Event(name: name, params: params, ts: Date())
        queue.async {
            #if DEBUG
            print("[Analytics]", event.name, event.params)
            #endif
            // TODO: send to backend/batch endpoint when available
        }
    }
}
