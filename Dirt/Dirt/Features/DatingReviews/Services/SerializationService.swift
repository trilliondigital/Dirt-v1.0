import Foundation

// MARK: - Serialization Service
class SerializationService {
    static let shared = SerializationService()
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Serialization Methods
    func encode<T: Codable>(_ object: T) throws -> Data {
        return try encoder.encode(object)
    }
    
    func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(type, from: data)
    }
    
    func encodeToString<T: Codable>(_ object: T) throws -> String {
        let data = try encode(object)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed
        }
        return string
    }
    
    func decodeFromString<T: Codable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw SerializationError.decodingFailed
        }
        return try decode(type, from: data)
    }
    
    // MARK: - User Serialization
    func serializeUser(_ user: User) throws -> [String: Any] {
        let data = try encode(user)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerializationError.serializationFailed
        }
        return json
    }
    
    func deserializeUser(from json: [String: Any]) throws -> User {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try decode(User.self, from: data)
    }
    
    // MARK: - Review Serialization
    func serializeReview(_ review: Review) throws -> [String: Any] {
        let data = try encode(review)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerializationError.serializationFailed
        }
        return json
    }
    
    func deserializeReview(from json: [String: Any]) throws -> Review {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try decode(Review.self, from: data)
    }
    
    // MARK: - Dating Review Post Serialization
    func serializePost(_ post: DatingReviewPost) throws -> [String: Any] {
        let data = try encode(post)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerializationError.serializationFailed
        }
        return json
    }
    
    func deserializePost(from json: [String: Any]) throws -> DatingReviewPost {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try decode(DatingReviewPost.self, from: data)
    }
    
    // MARK: - Comment Serialization
    func serializeComment(_ comment: Comment) throws -> [String: Any] {
        let data = try encode(comment)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerializationError.serializationFailed
        }
        return json
    }
    
    func deserializeComment(from json: [String: Any]) throws -> Comment {
        let data = try JSONSerialization.data(withJSONObject: json)
        return try decode(Comment.self, from: data)
    }
    
    // MARK: - Batch Serialization
    func serializeUsers(_ users: [User]) throws -> [[String: Any]] {
        return try users.map { try serializeUser($0) }
    }
    
    func deserializeUsers(from jsonArray: [[String: Any]]) throws -> [User] {
        return try jsonArray.map { try deserializeUser(from: $0) }
    }
    
    func serializeReviews(_ reviews: [Review]) throws -> [[String: Any]] {
        return try reviews.map { try serializeReview($0) }
    }
    
    func deserializeReviews(from jsonArray: [[String: Any]]) throws -> [Review] {
        return try jsonArray.map { try deserializeReview(from: $0) }
    }
    
    func serializePosts(_ posts: [DatingReviewPost]) throws -> [[String: Any]] {
        return try posts.map { try serializePost($0) }
    }
    
    func deserializePosts(from jsonArray: [[String: Any]]) throws -> [DatingReviewPost] {
        return try jsonArray.map { try deserializePost(from: $0) }
    }
    
    func serializeComments(_ comments: [Comment]) throws -> [[String: Any]] {
        return try comments.map { try serializeComment($0) }
    }
    
    func deserializeComments(from jsonArray: [[String: Any]]) throws -> [Comment] {
        return try jsonArray.map { try deserializeComment(from: $0) }
    }
    
    // MARK: - Database Serialization Helpers
    func serializeForDatabase<T: Codable>(_ object: T) throws -> String {
        return try encodeToString(object)
    }
    
    func deserializeFromDatabase<T: Codable>(_ type: T.Type, from string: String) throws -> T {
        return try decodeFromString(type, from: string)
    }
    
    // MARK: - API Serialization Helpers
    func serializeForAPI<T: Codable>(_ object: T) throws -> Data {
        return try encode(object)
    }
    
    func deserializeFromAPI<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        return try decode(type, from: data)
    }
    
    // MARK: - Validation with Serialization
    func validateAndSerialize<T: Codable>(_ object: T) throws -> Data {
        // Validate the object if it has validation methods
        if let validatable = object as? Validatable {
            try validatable.validate()
        }
        
        return try encode(object)
    }
    
    func deserializeAndValidate<T: Codable>(_ type: T.Type, from data: Data) throws -> T {
        let object = try decode(type, from: data)
        
        // Validate the object if it has validation methods
        if let validatable = object as? Validatable {
            try validatable.validate()
        }
        
        return object
    }
}

// MARK: - Serialization Errors
enum SerializationError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case serializationFailed
    case deserializationFailed
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode object to JSON"
        case .decodingFailed:
            return "Failed to decode JSON to object"
        case .serializationFailed:
            return "Failed to serialize object"
        case .deserializationFailed:
            return "Failed to deserialize object"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Validatable Protocol
protocol Validatable {
    func validate() throws
}

// MARK: - Make models conform to Validatable
extension User: Validatable {}
extension Review: Validatable {}
extension DatingReviewPost: Validatable {}
extension Comment: Validatable {}

// MARK: - Serialization Extensions
extension User {
    func toJSON() throws -> [String: Any] {
        return try SerializationService.shared.serializeUser(self)
    }
    
    static func fromJSON(_ json: [String: Any]) throws -> User {
        return try SerializationService.shared.deserializeUser(from: json)
    }
}

extension Review {
    func toJSON() throws -> [String: Any] {
        return try SerializationService.shared.serializeReview(self)
    }
    
    static func fromJSON(_ json: [String: Any]) throws -> Review {
        return try SerializationService.shared.deserializeReview(from: json)
    }
}

extension DatingReviewPost {
    func toJSON() throws -> [String: Any] {
        return try SerializationService.shared.serializePost(self)
    }
    
    static func fromJSON(_ json: [String: Any]) throws -> DatingReviewPost {
        return try SerializationService.shared.deserializePost(from: json)
    }
}

extension Comment {
    func toJSON() throws -> [String: Any] {
        return try SerializationService.shared.serializeComment(self)
    }
    
    static func fromJSON(_ json: [String: Any]) throws -> Comment {
        return try SerializationService.shared.deserializeComment(from: json)
    }
}