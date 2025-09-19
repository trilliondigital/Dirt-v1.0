import SwiftUI
import Combine

@MainActor
class CreatePostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentStep: PostCreationStep = .content
    @Published var title: String = ""
    @Published var content: String = ""
    @Published var selectedCategory: PostCategory = .general
    @Published var selectedSentiment: PostSentiment = .neutral
    @Published var selectedTags: Set<String> = []
    @Published var suggestedTags: [String] = []
    @Published var selectedImages: [UIImage] = []
    @Published var isPosting: Bool = false
    @Published var postingProgress: Double = 0.0
    @Published var showingImagePicker: Bool = false
    @Published var showingPreview: Bool = false
    @Published var validationErrors: [ValidationError] = []
    @Published var hasUnsavedChanges: Bool = false
    @Published var autoSaveStatus: AutoSaveStatus = .idle
    
    // MARK: - Character Limits
    let titleCharacterLimit = 100
    let contentCharacterLimit = 2000
    let maxImages = 4
    let maxTags = 5
    
    // MARK: - Computed Properties
    var titleCharacterCount: Int { title.count }
    var contentCharacterCount: Int { content.count }
    var isContentStepValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        titleCharacterCount <= titleCharacterLimit &&
        contentCharacterCount <= contentCharacterLimit
    }
    
    var canProceedToNextStep: Bool {
        switch currentStep {
        case .content:
            return isContentStepValid
        case .categorization:
            return true // Category and sentiment have defaults
        case .media:
            return true // Media is optional
        case .preview:
            return true
        case .publishing:
            return false // Can't proceed from publishing
        }
    }
    
    var canGoToPreviousStep: Bool {
        currentStep != .content
    }
    
    var progressPercentage: Double {
        switch currentStep {
        case .content: return 0.2
        case .categorization: return 0.4
        case .media: return 0.6
        case .preview: return 0.8
        case .publishing: return 1.0
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 3.0
    
    // MARK: - Initialization
    init() {
        setupAutoSave()
        setupContentAnalysis()
        loadDraftIfExists()
    }
    
    // MARK: - Navigation Methods
    func goToNextStep() {
        guard canProceedToNextStep else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .content:
                currentStep = .categorization
            case .categorization:
                currentStep = .media
            case .media:
                currentStep = .preview
            case .preview:
                currentStep = .publishing
                publishPost()
            case .publishing:
                break
            }
        }
    }
    
    func goToPreviousStep() {
        guard canGoToPreviousStep else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .content:
                break
            case .categorization:
                currentStep = .content
            case .media:
                currentStep = .categorization
            case .preview:
                currentStep = .media
            case .publishing:
                currentStep = .preview
            }
        }
    }
    
    func goToStep(_ step: PostCreationStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Content Management
    func addTag(_ tag: String) {
        guard selectedTags.count < maxTags else { return }
        selectedTags.insert(tag.lowercased())
        updateSuggestedTags()
    }
    
    func removeTag(_ tag: String) {
        selectedTags.remove(tag)
        updateSuggestedTags()
    }
    
    func addImage(_ image: UIImage) {
        guard selectedImages.count < maxImages else { return }
        selectedImages.append(image)
        hasUnsavedChanges = true
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        hasUnsavedChanges = true
    }
    
    // MARK: - Validation
    func validateCurrentStep() {
        validationErrors.removeAll()
        
        switch currentStep {
        case .content:
            validateContent()
        case .categorization:
            validateCategorization()
        case .media:
            validateMedia()
        case .preview, .publishing:
            validateAll()
        }
    }
    
    private func validateContent() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.emptyTitle)
        }
        
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(.emptyContent)
        }
        
        if titleCharacterCount > titleCharacterLimit {
            validationErrors.append(.titleTooLong)
        }
        
        if contentCharacterCount > contentCharacterLimit {
            validationErrors.append(.contentTooLong)
        }
        
        // Check for inappropriate content
        if containsInappropriateContent(title + " " + content) {
            validationErrors.append(.inappropriateContent)
        }
    }
    
    private func validateCategorization() {
        // Category and sentiment validation if needed
    }
    
    private func validateMedia() {
        // Media validation if needed
    }
    
    private func validateAll() {
        validateContent()
        validateCategorization()
        validateMedia()
    }
    
    // MARK: - Auto-Save
    private func setupAutoSave() {
        // Monitor changes to trigger auto-save
        Publishers.CombineLatest4($title, $content, $selectedCategory, $selectedSentiment)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
                self?.scheduleAutoSave()
            }
            .store(in: &cancellables)
    }
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.autoSave()
            }
        }
    }
    
    private func autoSave() async {
        guard hasUnsavedChanges else { return }
        
        autoSaveStatus = .saving
        
        // Simulate auto-save delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Save draft to UserDefaults or local storage
        saveDraft()
        
        autoSaveStatus = .saved
        hasUnsavedChanges = false
        
        // Reset status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.autoSaveStatus == .saved {
                self.autoSaveStatus = .idle
            }
        }
    }
    
    // MARK: - Content Analysis
    private func setupContentAnalysis() {
        // Analyze content for tag suggestions
        Publishers.CombineLatest($title, $content)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] title, content in
                self?.analyzeContentForTags(title: title, content: content)
            }
            .store(in: &cancellables)
    }
    
    private func analyzeContentForTags(title: String, content: String) {
        let combinedText = (title + " " + content).lowercased()
        var suggestions: [String] = []
        
        // Simple keyword-based tag suggestions
        let tagKeywords: [String: [String]] = [
            "dating": ["dating", "date", "relationship"],
            "texting": ["text", "message", "chat", "phone"],
            "profile": ["profile", "bio", "photo", "picture"],
            "first-date": ["first date", "meeting", "coffee"],
            "red-flag": ["red flag", "warning", "avoid"],
            "green-flag": ["green flag", "good sign", "positive"],
            "ghosting": ["ghost", "disappeared", "no response"],
            "communication": ["talk", "communicate", "conversation"]
        ]
        
        for (tag, keywords) in tagKeywords {
            if keywords.contains(where: { combinedText.contains($0) }) {
                suggestions.append(tag)
            }
        }
        
        // Filter out already selected tags
        suggestions = suggestions.filter { !selectedTags.contains($0) }
        
        // Limit suggestions
        suggestedTags = Array(suggestions.prefix(6))
    }
    
    private func updateSuggestedTags() {
        analyzeContentForTags(title: title, content: content)
    }
    
    // MARK: - Publishing
    func publishPost() {
        guard !isPosting else { return }
        
        isPosting = true
        postingProgress = 0.0
        
        Task {
            do {
                // Simulate publishing steps with progress
                await updateProgress(0.2, message: "Validating content...")
                try await Task.sleep(nanoseconds: 500_000_000)
                
                await updateProgress(0.4, message: "Processing images...")
                try await Task.sleep(nanoseconds: 800_000_000)
                
                await updateProgress(0.6, message: "Checking guidelines...")
                try await Task.sleep(nanoseconds: 600_000_000)
                
                await updateProgress(0.8, message: "Publishing post...")
                try await Task.sleep(nanoseconds: 700_000_000)
                
                await updateProgress(1.0, message: "Complete!")
                try await Task.sleep(nanoseconds: 500_000_000)
                
                // Reset form after successful posting
                await resetForm()
                
            } catch {
                await MainActor.run {
                    isPosting = false
                    postingProgress = 0.0
                    // Handle error
                }
            }
        }
    }
    
    private func updateProgress(_ progress: Double, message: String) async {
        await MainActor.run {
            postingProgress = progress
        }
    }
    
    // MARK: - Form Management
    func resetForm() {
        title = ""
        content = ""
        selectedCategory = .general
        selectedSentiment = .neutral
        selectedTags.removeAll()
        suggestedTags.removeAll()
        selectedImages.removeAll()
        currentStep = .content
        isPosting = false
        postingProgress = 0.0
        validationErrors.removeAll()
        hasUnsavedChanges = false
        autoSaveStatus = .idle
        clearDraft()
    }
    
    // MARK: - Draft Management
    private func saveDraft() {
        let draft = PostDraft(
            title: title,
            content: content,
            category: selectedCategory,
            sentiment: selectedSentiment,
            tags: Array(selectedTags),
            timestamp: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "post_draft")
        }
    }
    
    private func loadDraftIfExists() {
        guard let data = UserDefaults.standard.data(forKey: "post_draft"),
              let draft = try? JSONDecoder().decode(PostDraft.self, from: data) else {
            return
        }
        
        // Only load draft if it's recent (within 24 hours)
        guard Date().timeIntervalSince(draft.timestamp) < 24 * 60 * 60 else {
            clearDraft()
            return
        }
        
        title = draft.title
        content = draft.content
        selectedCategory = draft.category
        selectedSentiment = draft.sentiment
        selectedTags = Set(draft.tags)
        hasUnsavedChanges = false
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "post_draft")
    }
    
    // MARK: - Content Moderation
    private func containsInappropriateContent(_ text: String) -> Bool {
        // Simple content filtering - in production, this would use a proper moderation service
        let inappropriateWords = ["spam", "scam", "fake"]
        let lowercaseText = text.lowercased()
        return inappropriateWords.contains { lowercaseText.contains($0) }
    }
}

// MARK: - Supporting Types
enum PostCreationStep: CaseIterable {
    case content
    case categorization
    case media
    case preview
    case publishing
    
    var title: String {
        switch self {
        case .content: return "Write Your Post"
        case .categorization: return "Categorize"
        case .media: return "Add Media"
        case .preview: return "Preview"
        case .publishing: return "Publishing"
        }
    }
    
    var description: String {
        switch self {
        case .content: return "Share your thoughts and experiences"
        case .categorization: return "Help others find your post"
        case .media: return "Add photos to your story"
        case .preview: return "Review before posting"
        case .publishing: return "Sharing with the community"
        }
    }
    
    var iconName: String {
        switch self {
        case .content: return "pencil"
        case .categorization: return "tag"
        case .media: return "photo"
        case .preview: return "eye"
        case .publishing: return "paperplane"
        }
    }
}

enum ValidationError: Identifiable, Equatable {
    case emptyTitle
    case emptyContent
    case titleTooLong
    case contentTooLong
    case inappropriateContent
    
    var id: String {
        switch self {
        case .emptyTitle: return "empty_title"
        case .emptyContent: return "empty_content"
        case .titleTooLong: return "title_too_long"
        case .contentTooLong: return "content_too_long"
        case .inappropriateContent: return "inappropriate_content"
        }
    }
    
    var message: String {
        switch self {
        case .emptyTitle:
            return "Please add a title to your post"
        case .emptyContent:
            return "Please add some content to your post"
        case .titleTooLong:
            return "Title is too long (max 100 characters)"
        case .contentTooLong:
            return "Content is too long (max 2000 characters)"
        case .inappropriateContent:
            return "Content may violate community guidelines"
        }
    }
}

enum AutoSaveStatus {
    case idle
    case saving
    case saved
    case error
    
    var message: String {
        switch self {
        case .idle: return ""
        case .saving: return "Saving draft..."
        case .saved: return "Draft saved"
        case .error: return "Failed to save"
        }
    }
}

struct PostDraft: Codable {
    let title: String
    let content: String
    let category: PostCategory
    let sentiment: PostSentiment
    let tags: [String]
    let timestamp: Date
}