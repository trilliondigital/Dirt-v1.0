import SwiftUI

struct DiscussionPostCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.services) private var services
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: PostCategory = .advice
    @State private var selectedTags: Set<PostTag> = []
    @State private var isSubmitting: Bool = false
    
    private let maxTitleCharacters: Int = 200
    private let maxContentCharacters: Int = 10000
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: UISpacing.md) {
                    // Title Input
                    titleSection
                    
                    // Category Selection
                    categorySection
                    
                    // Content Input (Rich Text Editor)
                    contentSection
                    
                    // Tag Selection
                    tagSection
                    
                    // Submit Button
                    submitSection
                }
                .padding(UISpacing.md)
            }
            .background(UIColors.groupedBackground.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    GlassButton("Cancel", style: .subtle) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("New Discussion")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(UIColors.label)
                }
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(UIColors.label)
                
                TextField("What's your discussion about?", text: $title)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .foregroundColor(UIColors.label)
                    .padding(UISpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: UICornerRadius.sm)
                            .fill(MaterialDesignSystem.Glass.ultraThin)
                            .overlay(
                                RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                            )
                    )
                    .onChange(of: title) { _, newValue in
                        if newValue.count > maxTitleCharacters {
                            title = String(newValue.prefix(maxTitleCharacters))
                        }
                    }
                
                HStack {
                    Spacer()
                    Text("\(title.count)/\(maxTitleCharacters)")
                        .font(.caption)
                        .foregroundColor(title.count > maxTitleCharacters - 20 ? UIColors.danger : UIColors.secondaryLabel)
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(UIColors.label)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: UISpacing.sm) {
                    ForEach(PostCategory.allCases, id: \.self) { category in
                        categoryButton(for: category)
                    }
                }
            }
        }
    }
    
    private func categoryButton(for category: PostCategory) -> some View {
        Button(action: {
            selectedCategory = category
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }) {
            VStack(spacing: UISpacing.xs) {
                Image(systemName: category.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedCategory == category ? UIColors.accentPrimary : UIColors.secondaryLabel)
                
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(selectedCategory == category ? UIColors.accentPrimary : UIColors.label)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(UISpacing.sm)
            .background(
                selectedCategory == category ?
                    MaterialDesignSystem.GlassColors.primary :
                    MaterialDesignSystem.Glass.ultraThin,
                in: RoundedRectangle(cornerRadius: UICornerRadius.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UICornerRadius.sm)
                    .stroke(
                        selectedCategory == category ?
                            UIColors.accentPrimary.opacity(0.6) :
                            MaterialDesignSystem.GlassBorders.subtle,
                        lineWidth: selectedCategory == category ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content Section (Rich Text Editor)
    private var contentSection: some View {
        GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                Text("Content")
                    .font(.headline)
                    .foregroundColor(UIColors.label)
                
                Text(selectedCategory.description)
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
                
                GlassRichTextEditor(
                    text: $content,
                    placeholder: "Share your thoughts, experiences, or ask for advice...",
                    maxCharacters: maxContentCharacters,
                    accessibilityLabel: "Discussion content",
                    accessibilityHint: "Enter the main content of your discussion post"
                )
            }
        }
    }
    
    // MARK: - Tag Section
    private var tagSection: some View {
        GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg) {
            VStack(alignment: .leading, spacing: UISpacing.sm) {
                HStack {
                    Text("Tags")
                        .font(.headline)
                        .foregroundColor(UIColors.label)
                    
                    Spacer()
                    
                    Text("\(selectedTags.count) selected")
                        .font(.caption)
                        .foregroundColor(UIColors.secondaryLabel)
                }
                
                Text("Select relevant tags to help others discover your post")
                    .font(.caption)
                    .foregroundColor(UIColors.secondaryLabel)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: UISpacing.xs) {
                    ForEach(PostTag.allCases, id: \.self) { tag in
                        tagButton(for: tag)
                    }
                }
            }
        }
    }
    
    private func tagButton(for tag: PostTag) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedTags.contains(tag) {
                    selectedTags.remove(tag)
                } else {
                    selectedTags.insert(tag)
                }
            }
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }) {
            Text(tag.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    selectedTags.contains(tag) ?
                        UIColors.accentPrimary :
                        UIColors.label
                )
                .padding(.horizontal, UISpacing.sm)
                .padding(.vertical, UISpacing.xs)
                .background(
                    selectedTags.contains(tag) ?
                        MaterialDesignSystem.GlassColors.primary :
                        MaterialDesignSystem.Glass.ultraThin,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            selectedTags.contains(tag) ?
                                UIColors.accentPrimary.opacity(0.6) :
                                MaterialDesignSystem.GlassBorders.subtle,
                            lineWidth: selectedTags.contains(tag) ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Submit Section
    private var submitSection: some View {
        VStack(spacing: UISpacing.sm) {
            GlassButton(
                isSubmitting ? "Creating Post..." : "Create Discussion Post",
                systemImage: isSubmitting ? nil : "plus.circle.fill",
                style: canSubmit ? .primary : .subtle
            ) {
                submitPost()
            }
            .disabled(!canSubmit || isSubmitting)
            
            if !canSubmit {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(UIColors.danger)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canSubmit: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty &&
               !trimmedContent.isEmpty &&
               trimmedTitle.count <= maxTitleCharacters &&
               trimmedContent.count <= maxContentCharacters &&
               !isSubmitting
    }
    
    private var validationMessage: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            return "Please enter a title for your discussion"
        } else if trimmedContent.isEmpty {
            return "Please add content to your discussion"
        } else if trimmedTitle.count > maxTitleCharacters {
            return "Title is too long"
        } else if trimmedContent.count > maxContentCharacters {
            return "Content is too long"
        }
        
        return ""
    }
    
    // MARK: - Actions
    private func submitPost() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = Array(selectedTags).map { $0.rawValue }
        
        Task {
            do {
                try await services.discussionPostService.createDiscussionPost(
                    title: trimmedTitle,
                    content: trimmedContent,
                    category: selectedCategory,
                    tags: tags
                )
                
                // Success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
                await MainActor.run {
                    toastCenter.show(.success, "Discussion post created successfully!")
                    presentationMode.wrappedValue.dismiss()
                }
                
            } catch {
                // Error haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                await MainActor.run {
                    isSubmitting = false
                    toastCenter.show(.error, ErrorPresenter.message(for: error))
                }
            }
        }
    }
}

// MARK: - Preview
struct DiscussionPostCreationView_Previews: PreviewProvider {
    static var previews: some View {
        DiscussionPostCreationView()
            .environmentObject(ToastCenter())
    }
}