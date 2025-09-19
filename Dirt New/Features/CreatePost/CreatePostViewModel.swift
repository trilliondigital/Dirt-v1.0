import SwiftUI
import Combine

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var selectedSentiment: PostSentiment?
    @Published var selectedCategory: PostCategory?
    @Published var tags: [String] = []
    @Published var isLoading = false
    @Published var isPostCreated = false
    @Published var error: CreatePostError?
    
    let suggestedTags = [
        "dating-apps", "first-date", "texting", "red-flags", "green-flags",
        "ghosting", "profile-tips", "conversation", "relationship", "advice"
    ]
    
    private let supabaseManager = SupabaseManager.shared
    
    var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canPost: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedContent.isEmpty &&
               selectedSentiment != nil &&
               selectedCategory != nil &&
               trimmedTitle.count <= 100 &&
               trimmedContent.count <= 2000
    }
    
    func createPost() async {
        guard canPost else { return }
        
        isLoading = true
        error = nil
        
        do {
            let post = Post(
                authorId: UUID(), // This would come from the current user
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                category: selectedCategory!,
                sentiment: selectedSentiment!,
                tags: tags
            )
            
            _ = try await supabaseManager.createPost(post)
            
            // Reset form
            resetForm()
            isPostCreated = true
            
        } catch {
            self.error = .creationFailed
        }
        
        isLoading = false
    }
    
    private func resetForm() {
        title = ""
        content = ""
        selectedSentiment = nil
        selectedCategory = nil
        tags = []
    }
}

enum CreatePostError: LocalizedError {
    case creationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create post"
        case .validationFailed:
            return "Please check your input and try again"
        }
    }
}