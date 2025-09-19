import Foundation
import UIKit
import SwiftUI

// MARK: - Review Creation Service
@MainActor
class ReviewCreationService: ObservableObject {
    static let shared = ReviewCreationService()
    
    @Published var isSubmitting = false
    @Published var submissionProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let mediaService = MediaService.shared
    private let validationService = ModelValidationService.shared
    private let supabaseManager = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Review Creation
    
    func createReview(
        authorId: UUID,
        images: [UIImage],
        ratings: ReviewRatings,
        content: String,
        selectedTags: [ReviewTag],
        datingApp: DatingApp
    ) async throws -> Review {
        isSubmitting = true
        submissionProgress = 0.0
        errorMessage = nil
        successMessage = nil
        
        defer {
            isSubmitting = false
            submissionProgress = 0.0
        }
        
        do {
            // Step 1: Validate input (10%)
            try validateReviewInput(
                images: images,
                ratings: ratings,
                content: content,
                tags: selectedTags
            )
            submissionProgress = 0.1
            
            // Step 2: Process and upload images (50%)
            let imageUrls = try await processAndUploadImages(images)
            submissionProgress = 0.6
            
            // Step 3: Create review object (20%)
            let review = Review(
                authorId: authorId,
                profileScreenshots: imageUrls,
                ratings: ratings,
                content: content,
                tags: selectedTags.map { $0.rawValue },
                datingApp: datingApp
            )
            submissionProgress = 0.8
            
            // Step 4: Validate complete review
            try validationService.validateReview(review)
            
            // Step 5: Submit to backend (20%)
            let submittedReview = try await submitReview(review)
            submissionProgress = 1.0
            
            successMessage = "Review submitted successfully!"
            return submittedReview
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Input Validation
    
    private func validateReviewInput(
        images: [UIImage],
        ratings: ReviewRatings,
        content: String,
        tags: [ReviewTag]
    ) throws {
        // Validate images
        guard !images.isEmpty else {
            throw DatingReviewValidationError.invalidImageCount
        }
        
        guard images.count <= 5 else {
            throw DatingReviewValidationError.invalidImageCount
        }
        
        // Validate ratings
        try ratings.validate()
        
        // Validate content
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DatingReviewValidationError.invalidContent
        }
        
        guard content.count >= 10 else {
            throw DatingReviewValidationError.contentTooShort
        }
        
        guard content.count <= 5000 else {
            throw DatingReviewValidationError.contentTooLong
        }
        
        // Validate tags
        guard tags.count <= 10 else {
            throw DatingReviewValidationError.tooManyTags
        }
        
        // Check for personal information in content
        let moderationFlags = validationService.validateForModeration(content)
        if moderationFlags.contains(.personalInformation) {
            throw DatingReviewValidationError.personalInformationDetected
        }
        
        // Check for inappropriate content
        if moderationFlags.contains(where: { $0.severity.rawValue >= ModerationSeverity.high.rawValue }) {
            throw DatingReviewValidationError.inappropriateContent
        }
    }
    
    // MARK: - Image Processing
    
    private func processAndUploadImages(_ images: [UIImage]) async throws -> [String] {
        var uploadedUrls: [String] = []
        let totalImages = images.count
        
        for (index, image) in images.enumerated() {
            // Process image for PII blurring
            let processedImage = try await processImageForPII(image)
            
            // Upload processed image
            let url = try await mediaService.uploadImage(
                processedImage,
                bucket: "reviews",
                folder: "profile-screenshots",
                compress: true
            )
            
            uploadedUrls.append(url)
            
            // Update progress (images take 50% of total progress, starting from 10%)
            let imageProgress = Double(index + 1) / Double(totalImages) * 0.5
            submissionProgress = 0.1 + imageProgress
        }
        
        return uploadedUrls
    }
    
    // MARK: - PII Detection and Blurring
    
    private func processImageForPII(_ image: UIImage) async throws -> UIImage {
        // In a real implementation, this would use ML/AI to detect and blur PII
        // For now, we'll implement a basic version that detects text regions
        
        return try await detectAndBlurPII(in: image)
    }
    
    private func detectAndBlurPII(in image: UIImage) async throws -> UIImage {
        // This is a simplified implementation
        // In production, you would use Vision framework or a third-party service
        
        guard let cgImage = image.cgImage else {
            throw DatingReviewValidationError.invalidContent
        }
        
        // For now, return the original image
        // In a real implementation, you would:
        // 1. Use Vision framework to detect text
        // 2. Use ML models to identify PII (names, phone numbers, etc.)
        // 3. Apply blur effects to detected regions
        
        return image
    }
    
    // MARK: - Backend Submission
    
    private func submitReview(_ review: Review) async throws -> Review {
        // Convert review to JSON for submission
        let reviewData = try JSONEncoder().encode(review)
        
        // Submit to Supabase
        // In a real implementation:
        // let response = try await supabaseManager.client
        //     .from("reviews")
        //     .insert(review)
        //     .execute()
        
        // For now, simulate network delay and return the review
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return review
    }
    
    // MARK: - Draft Management
    
    func saveDraft(
        images: [UIImage],
        ratings: ReviewRatings?,
        content: String,
        selectedTags: [ReviewTag],
        datingApp: DatingApp?
    ) async throws {
        let draft = ReviewDraft(
            id: UUID(),
            images: images,
            ratings: ratings,
            content: content,
            tags: selectedTags,
            datingApp: datingApp,
            lastModified: Date()
        )
        
        // Save to local storage
        try await saveDraftLocally(draft)
    }
    
    func loadDrafts() async throws -> [ReviewDraft] {
        // Load from local storage
        return try await loadDraftsLocally()
    }
    
    func deleteDraft(_ draftId: UUID) async throws {
        try await deleteDraftLocally(draftId)
    }
    
    // MARK: - Local Storage Helpers
    
    private func saveDraftLocally(_ draft: ReviewDraft) async throws {
        // In a real implementation, save to Core Data or UserDefaults
        // For now, we'll just simulate the operation
    }
    
    private func loadDraftsLocally() async throws -> [ReviewDraft] {
        // In a real implementation, load from Core Data or UserDefaults
        return []
    }
    
    private func deleteDraftLocally(_ draftId: UUID) async throws {
        // In a real implementation, delete from Core Data or UserDefaults
    }
}

// MARK: - Review Draft Model

struct ReviewDraft: Identifiable, Codable {
    let id: UUID
    let images: [UIImage]
    let ratings: ReviewRatings?
    let content: String
    let tags: [ReviewTag]
    let datingApp: DatingApp?
    let lastModified: Date
    
    enum CodingKeys: String, CodingKey {
        case id, ratings, content, tags, datingApp, lastModified
    }
    
    // Custom encoding/decoding to handle UIImage
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ratings = try container.decodeIfPresent(ReviewRatings.self, forKey: .ratings)
        content = try container.decode(String.self, forKey: .content)
        tags = try container.decode([ReviewTag].self, forKey: .tags)
        datingApp = try container.decodeIfPresent(DatingApp.self, forKey: .datingApp)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
        
        // For simplicity, initialize with empty images array
        // In a real implementation, you'd save/load image data
        images = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(ratings, forKey: .ratings)
        try container.encode(content, forKey: .content)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(datingApp, forKey: .datingApp)
        try container.encode(lastModified, forKey: .lastModified)
        
        // Images are not encoded in this simplified implementation
    }
    
    init(
        id: UUID,
        images: [UIImage],
        ratings: ReviewRatings?,
        content: String,
        tags: [ReviewTag],
        datingApp: DatingApp?,
        lastModified: Date
    ) {
        self.id = id
        self.images = images
        self.ratings = ratings
        self.content = content
        self.tags = tags
        self.datingApp = datingApp
        self.lastModified = lastModified
    }
}

// MARK: - Review Tag Extension

extension ReviewTag: Codable {}