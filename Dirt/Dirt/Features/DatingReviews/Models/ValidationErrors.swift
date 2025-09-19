import Foundation

// MARK: - Dating Review Validation Errors
enum DatingReviewValidationError: LocalizedError {
    case invalidContent
    case invalidRating
    case invalidUsername
    case invalidTags
    case invalidImageCount
    case invalidImageSize
    case contentTooShort
    case contentTooLong
    case tooManyTags
    case tagTooLong
    case missingRequiredFields
    case inappropriateContent
    case personalInformationDetected
    case invalidPhoneHash
    case invalidReputation
    case invalidCategory
    
    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return "Content is invalid or empty"
        case .invalidRating:
            return "Rating must be between 1 and 5"
        case .invalidUsername:
            return "Username is invalid"
        case .invalidTags:
            return "One or more tags are invalid"
        case .invalidImageCount:
            return "Must include 1-5 images"
        case .invalidImageSize:
            return "Image size is too large"
        case .contentTooShort:
            return "Content is too short (minimum 10 characters)"
        case .contentTooLong:
            return "Content is too long (maximum 5000 characters)"
        case .tooManyTags:
            return "Too many tags (maximum 10)"
        case .tagTooLong:
            return "Tag is too long (maximum 50 characters)"
        case .missingRequiredFields:
            return "Please fill in all required fields"
        case .inappropriateContent:
            return "Content contains inappropriate material"
        case .personalInformationDetected:
            return "Content contains personal information that must be removed"
        case .invalidPhoneHash:
            return "Phone number hash is required"
        case .invalidReputation:
            return "Reputation cannot be negative"
        case .invalidCategory:
            return "Invalid category selected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidContent:
            return "Please provide meaningful content for your review"
        case .invalidRating:
            return "Please select a rating from 1 to 5 stars"
        case .invalidUsername:
            return "Please choose a different username"
        case .invalidTags:
            return "Please select valid tags from the available options"
        case .invalidImageCount:
            return "Please include between 1 and 5 images"
        case .invalidImageSize:
            return "Please use smaller images or compress them"
        case .contentTooShort:
            return "Please provide more detailed feedback"
        case .contentTooLong:
            return "Please shorten your review content"
        case .tooManyTags:
            return "Please select fewer tags"
        case .tagTooLong:
            return "Please use shorter tag names"
        case .missingRequiredFields:
            return "Please complete all required fields before submitting"
        case .inappropriateContent:
            return "Please remove inappropriate content and try again"
        case .personalInformationDetected:
            return "Please blur or remove any personal information from images and text"
        case .invalidPhoneHash:
            return "Please provide a valid phone number"
        case .invalidReputation:
            return "Reputation score is invalid"
        case .invalidCategory:
            return "Please select a valid category"
        }
    }
}