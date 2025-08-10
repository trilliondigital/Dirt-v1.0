import Foundation

enum ControlledTag: String, CaseIterable, Identifiable, Codable {
    case ghosting = "👻 Ghosting"
    case greatConversation = "💬 Great Conversation"
    case secondDate = "💑 Second Date"
    case avoid = "❌ Avoid"

    var id: String { rawValue }
}

struct TagCatalog {
    static let all: [ControlledTag] = ControlledTag.allCases
}
