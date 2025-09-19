import SwiftUI

struct CreatePostView: View {
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory = PostCategory.general
    @State private var selectedSentiment = PostSentiment.neutral
    @State private var isPosting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Post Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(PostCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    
                    Picker("Sentiment", selection: $selectedSentiment) {
                        ForEach(PostSentiment.allCases, id: \.self) { sentiment in
                            Label(sentiment.displayName, systemImage: sentiment.iconName)
                                .tag(sentiment)
                        }
                    }
                }
                
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isPosting)
                }
            }
            .navigationTitle("Create Post")
            .disabled(isPosting)
            .overlay {
                if isPosting {
                    ProgressView("Posting...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func createPost() {
        isPosting = true

        Task {
            do {
                // Simulate posting delay
                try await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    // Reset form
                    title = ""
                    content = ""
                    selectedCategory = .general
                    selectedSentiment = .neutral
                    isPosting = false
                }
            } catch {
                // Handle cancellation or other errors from sleep or future throwing calls
                await MainActor.run {
                    isPosting = false
                }
                print("CreatePostView.createPost error: \(error)")
            }
        }
    }
}
