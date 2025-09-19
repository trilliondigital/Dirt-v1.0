import SwiftUI
import PhotosUI

// MARK: - Review Creation View
struct ReviewCreationView: View {
    @StateObject private var reviewService = ReviewCreationService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var selectedImages: [UIImage] = []
    @State private var ratings = ReviewRatings(photos: 3, bio: 3, conversation: 3, overall: 3)
    @State private var reviewContent = ""
    @State private var selectedTags: Set<ReviewTag> = []
    @State private var selectedDatingApp: DatingApp = .tinder
    
    // UI state
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingTagSelector = false
    @State private var showingDraftAlert = false
    @State private var showingSubmissionAlert = false
    
    // Validation state
    @State private var validationErrors: [String] = []
    @State private var showingValidationAlert = false
    
    let authorId: UUID
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Image Upload Section
                    imageUploadSection
                    
                    // Dating App Selection
                    datingAppSection
                    
                    // Ratings Section
                    ratingsSection
                    
                    // Review Content
                    contentSection
                    
                    // Tags Section
                    tagsSection
                    
                    // Submit Button
                    submitSection
                }
                .padding()
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Draft") {
                        saveDraft()
                    }
                    .disabled(reviewContent.isEmpty && selectedImages.isEmpty)
                }
            }
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
        .alert("Submission Status", isPresented: $showingSubmissionAlert) {
            Button("OK") {
                if reviewService.successMessage != nil {
                    dismiss()
                }
            }
        } message: {
            Text(reviewService.errorMessage ?? reviewService.successMessage ?? "")
        }
        .alert("Save Draft", isPresented: $showingDraftAlert) {
            Button("Save") {
                Task {
                    try await reviewService.saveDraft(
                        images: selectedImages,
                        ratings: ratings,
                        content: reviewContent,
                        selectedTags: Array(selectedTags),
                        datingApp: selectedDatingApp
                    )
                }
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to save this review as a draft?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share Your Experience")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Help other men by sharing your honest experience with this dating profile. All personal information will be automatically blurred.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Image Upload Section
    
    private var imageUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profile Screenshots")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedImages.count)/5")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if selectedImages.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Add screenshots of the dating profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button("Camera") {
                            showingCamera = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Photo Library") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Image grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ImageThumbnailView(
                            image: image,
                            onRemove: {
                                selectedImages.remove(at: index)
                            }
                        )
                    }
                    
                    if selectedImages.count < 5 {
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                if selectedImages.count < 5 {
                    selectedImages.append(image)
                }
            }
        }
    }
    
    // MARK: - Dating App Section
    
    private var datingAppSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dating App")
                .font(.headline)
            
            Picker("Dating App", selection: $selectedDatingApp) {
                ForEach(DatingApp.allCases, id: \.self) { app in
                    Text(app.displayName).tag(app)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Ratings Section
    
    private var ratingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rate Your Experience")
                .font(.headline)
            
            VStack(spacing: 12) {
                RatingRow(title: "Photos", rating: $ratings.photos)
                RatingRow(title: "Bio/Profile", rating: $ratings.bio)
                RatingRow(title: "Conversation", rating: $ratings.conversation)
                RatingRow(title: "Overall", rating: $ratings.overall)
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Review")
                    .font(.headline)
                
                Spacer()
                
                Text("\(reviewContent.count)/5000")
                    .font(.caption)
                    .foregroundColor(reviewContent.count > 4500 ? .red : .secondary)
            }
            
            TextEditor(text: $reviewContent)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if reviewContent.isEmpty {
                Text("Share details about your experience, conversation quality, and any red or green flags you noticed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.headline)
                
                Spacer()
                
                Button("Select Tags") {
                    showingTagSelector = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            if selectedTags.isEmpty {
                Text("Add tags to help categorize your review")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: true,
                            onTap: {
                                selectedTags.remove(tag)
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagSelector) {
            TagSelectorView(selectedTags: $selectedTags)
        }
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        VStack(spacing: 16) {
            if reviewService.isSubmitting {
                VStack(spacing: 8) {
                    ProgressView(value: reviewService.submissionProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Submitting review...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: submitReview) {
                HStack {
                    if reviewService.isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Text("Submit Review")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(reviewService.isSubmitting || !isFormValid)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !selectedImages.isEmpty &&
        !reviewContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        reviewContent.count >= 10
    }
    
    // MARK: - Actions
    
    private func handleCancel() {
        if hasUnsavedChanges {
            showingDraftAlert = true
        } else {
            dismiss()
        }
    }
    
    private var hasUnsavedChanges: Bool {
        !selectedImages.isEmpty ||
        !reviewContent.isEmpty ||
        !selectedTags.isEmpty
    }
    
    private func saveDraft() {
        Task {
            do {
                try await reviewService.saveDraft(
                    images: selectedImages,
                    ratings: ratings,
                    content: reviewContent,
                    selectedTags: Array(selectedTags),
                    datingApp: selectedDatingApp
                )
            } catch {
                // Handle error
            }
        }
    }
    
    private func submitReview() {
        // Clear previous validation errors
        validationErrors.removeAll()
        
        // Validate form
        if !validateForm() {
            showingValidationAlert = true
            return
        }
        
        Task {
            do {
                let _ = try await reviewService.createReview(
                    authorId: authorId,
                    images: selectedImages,
                    ratings: ratings,
                    content: reviewContent,
                    selectedTags: Array(selectedTags),
                    datingApp: selectedDatingApp
                )
                
                showingSubmissionAlert = true
            } catch {
                showingSubmissionAlert = true
            }
        }
    }
    
    private func validateForm() -> Bool {
        var errors: [String] = []
        
        if selectedImages.isEmpty {
            errors.append("Please add at least one screenshot")
        }
        
        if reviewContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Please write a review")
        } else if reviewContent.count < 10 {
            errors.append("Review must be at least 10 characters")
        }
        
        validationErrors = errors
        return errors.isEmpty
    }
}

// MARK: - Supporting Views

struct RatingRow: View {
    let title: String
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rating = star
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(star <= rating ? .yellow : .gray)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct ImageThumbnailView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

struct TagChip: View {
    let tag: ReviewTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(tag.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Preview

struct ReviewCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewCreationView(authorId: UUID())
    }
}