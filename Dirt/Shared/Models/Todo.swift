import Foundation

struct Todo: Codable, Identifiable {
    let id: Int?
    let title: String
    let isComplete: Bool
    let userId: UUID
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isComplete = "is_complete"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: Int? = nil, title: String, isComplete: Bool = false, userId: UUID, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isComplete = isComplete
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
