import Foundation

final class DiscussionPostService {
    static let shared = DiscussionPostService()
    private init() {}
    
    struct CreateDiscussionPostResponse: Codable {
        let id: UUID
        let createdAt: Date
    }
    
    /// Creates a new discussion post with validation and moderation
    func createDiscussionPost(
        title: String,
        content: String,
        category: PostCategory,
        tags: [String]
    ) async throws {
        
        // Client-side validation
        try validateDiscussionPost(title: title, content: content, tags: tags)
        
        let payload: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "category": category.rawValue,
            "tags": tags,
            "type": "discussion"
        ]
        
        // Retry on transient failures (network, 5xx)
        func isTransient(_ error: Error) -> Bool {
            if error is URLError { return true }
            let ns = error as NSError
            if ns.domain == "SupabaseFunction" {
                // Retry server errors and rate limit
                return ns.code >= 500 || ns.code == 429
            }
            return false
        }
        
        let data = try await Retry.withExponentialBackoff(
            .init(maxAttempts: 3, initialDelay: 0.6, multiplier: 2.0, jitter: 0.25),
            shouldRetry: { isTransient($0) }
        ) {
            try await SupabaseManager.shared.callEdgeFunction(name: "posts-create", json: payload)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(CreateDiscussionPostResponse.self, from: data)
        
        // Fire-and-forget mentions processing
        Task.detached {
            await MentionsService.shared.processMentions(postId: response.id, content: content)
        }
        
        // Analytics tracking
        await trackDiscussionPostCreation(category: category, tags: tags)
    }
    
    /// Validates discussion post input
    private func validateDiscussionPost(title: String, content: String, tags: [String]) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Title validation
        guard !trimmedTitle.isEmpty else {
            throw DiscussionPostValidationError.emptyTitle
        }
        
        guard trimmedTitle.count <= 200 else {
            throw DiscussionPostValidationError.titleTooLong
        }
        
        // Content validation
        guard !trimmedContent.isEmpty else {
            throw DiscussionPostValidationError.emptyContent
        }
        
        guard trimmedContent.count <= 10000 else {
            throw DiscussionPostValidationError.contentTooLong
        }
        
        // Tags validation
        guard tags.count <= 10 else {
            throw DiscussionPostValidationError.tooManyTags
        }
        
        // Validate individual tags
        for tag in tags {
            guard !tag.isEmpty else {
                throw DiscussionPostValidationError.invalidTag
            }
            
            guard tag.count <= 50 else {
                throw DiscussionPostValidationError.tagTooLong
            }
        }
        
        // Content moderation checks
        try performContentModerationChecks(title: trimmedTitle, content: trimmedContent)
    }
    
    /// Performs basic content moderation checks
    private func performContentModerationChecks(title: String, content: String) throws {
        let combinedText = "\(title) \(content)".lowercased()
        
        // Check for prohibited content patterns
        let prohibitedPatterns = [
            "\\b\\d{3}[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b", // Phone numbers
            "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", // Email addresses
            "@[A-Za-z0-9_]+", // Social media handles
            "\\b(instagram|twitter|snapchat|facebook|tiktok)\\b.*\\b[A-Za-z0-9_]+\\b" // Social media references
        ]
        
        for pattern in prohibitedPatterns {
            if combinedText.range(of: pattern, options: .regularExpression) != nil {
                throw DiscussionPostValidationError.containsProhibitedContent
            }
        }
        
        // Check for excessive profanity or inappropriate content
        let inappropriateWords = ["spam", "scam", "fake", "bot"]
        let wordCount = inappropriateWords.filter { combinedText.contains($0) }.count
        
        if wordCount > 2 {
            throw DiscussionPostValidationError.inappropriateContent
        }
    }
    
    /// Tracks analytics for discussion post creation
    private func trackDiscussionPostCreation(category: PostCategory, tags: [String]) async {
        Task {
            await AnalyticsService.shared.trackUserAction("discussion_post_created", parameters: [
                "category": category.rawValue,
                "tag_count": "\(tags.count)",
                "tags": tags.joined(separator: ",")
            ])
        }
        
        // Track time to first discussion post
        let defaults = UserDefaults.standard
        let firstLaunchKey = "firstLaunchAt"
        let firstDiscussionPostLoggedKey = "firstDiscussionPostLogged"
        
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: firstLaunchKey)
        }
        
        if defaults.bool(forKey: firstDiscussionPostLoggedKey) == false {
            if let firstLaunchTs = defaults.object(forKey: firstLaunchKey) as? Double {
                let ms = Int((Date().timeIntervalSince1970 - firstLaunchTs) * 1000)
                Task {
                    await AnalyticsService.shared.trackUserAction("time_to_first_discussion_post_ms", parameters: ["value": "\(ms)"])
                }
                defaults.set(true, forKey: firstDiscussionPostLoggedKey)
            }
        }
    }
}

// MARK: - Validation Errors
enum DiscussionPostValidationError: LocalizedError {
    case emptyTitle
    case titleTooLong
    case emptyContent
    case contentTooLong
    case tooManyTags
    case invalidTag
    case tagTooLong
    case containsProhibitedContent
    case inappropriateContent
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Please enter a title for your discussion"
        case .titleTooLong:
            return "Title must be 200 characters or less"
        case .emptyContent:
            return "Please add content to your discussion"
        case .contentTooLong:
            return "Content must be 10,000 characters or less"
        case .tooManyTags:
            return "You can select up to 10 tags"
        case .invalidTag:
            return "Invalid tag selected"
        case .tagTooLong:
            return "Tag names must be 50 characters or less"
        case .containsProhibitedContent:
            return "Your post contains prohibited content. Please remove personal information or contact details."
        case .inappropriateContent:
            return "Your post may contain inappropriate content. Please review and try again."
        }
    }
}