import SwiftUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Post Type Selection
                    PostTypeSelection(
                        selectedSentiment: $viewModel.selectedSentiment,
                        selectedCategory: $viewModel.selectedCategory
                    )
                    
                    // Title Input
                    TitleInput(title: $viewModel.title)
                    
                    // Content Input
                    ContentInput(content: $viewModel.content)
                    
                    // Tags Input
                    TagsInput(
                        tags: $viewModel.tags,
                        suggestedTags: viewModel.suggestedTags
                    )
                    
                    // Media Attachment (placeholder)
                    MediaAttachment()
                    
                    // Guidelines
                    PostingGuidelines()
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasContent {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await viewModel.createPost()
                            if viewModel.isPostCreated {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canPost || viewModel.isLoading)
                }
            }
            .alert("Discard Post?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("Your post will be lost if you don't save it.")
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Creating post...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                        )
                }
            }
        }
    }
}

// MARK: - Post Type Selection
struct PostTypeSelection: View {
    @Binding var selectedSentiment: PostSentiment?
    @Binding var selectedCategory: PostCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What kind of post is this?")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Sentiment Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Flag Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    ForEach(PostSentiment.allCases, id: \.self) { sentiment in
                        SentimentButton(
                            sentiment: sentiment,
                            isSelected: selectedSentiment == sentiment,
                            action: {
                                selectedSentiment = selectedSentiment == sentiment ? nil : sentiment
                            }
                        )
                    }
                }
            }
            
            // Category Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(PostCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                }
            }
        }
    }
}

struct SentimentButton: View {
    let sentiment: PostSentiment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: sentiment.iconName)
                    .font(.subheadline)
                Text(sentiment.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(sentiment.color) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : Color(sentiment.color))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryButton: View {
    let category: PostCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.iconName)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Title Input
struct TitleInput: View {
    @Binding var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Give your post a clear, descriptive title...", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
            
            HStack {
                Spacer()
                Text("\(title.count)/100")
                    .font(.caption)
                    .foregroundColor(title.count > 100 ? .red : .secondary)
            }
        }
    }
}

// MARK: - Content Input
struct ContentInput: View {
    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Share your experience, ask for advice, or start a discussion...", text: $content, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(8...15)
                .font(.body)
            
            HStack {
                Text("Be respectful and constructive")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(content.count)/2000")
                    .font(.caption)
                    .foregroundColor(content.count > 2000 ? .red : .secondary)
            }
        }
    }
}

// MARK: - Tags Input
struct TagsInput: View {
    @Binding var tags: [String]
    let suggestedTags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Current tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                onRemove: {
                                    tags.removeAll { $0 == tag }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // Add new tag
            HStack {
                TextField("Add a tag...", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .disabled(newTag.isEmpty || tags.count >= 5)
            }
            
            // Suggested tags
            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedTags, id: \.self) { tag in
                                if !tags.contains(tag) {
                                    Button("#\(tag)") {
                                        if tags.count < 5 {
                                            tags.append(tag)
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
            
            Text("Add up to 5 tags to help others find your post")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) && tags.count < 5 {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
}

struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(text)")
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// MARK: - Media Attachment
struct MediaAttachment: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Media (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                // TODO: Implement media picker
            }) {
                HStack {
                    Image(systemName: "photo")
                    Text("Add Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Images will be blurred by default for privacy")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Posting Guidelines
struct PostingGuidelines: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Guidelines")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                GuidelineRow(
                    icon: "checkmark.circle.fill",
                    text: "Be respectful and constructive",
                    color: .green
                )
                
                GuidelineRow(
                    icon: "shield.fill",
                    text: "Protect privacy - no personal information",
                    color: .blue
                )
                
                GuidelineRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "No harassment, hate speech, or spam",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GuidelineRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    CreatePostView()
}