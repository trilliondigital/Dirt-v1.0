import SwiftUI

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.services) private var services
    @State private var postText: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImageRevealed: Bool = false
    @State private var isImagePickerPresented = false
    @State private var selectedTags: Set<ControlledTag> = []
    @State private var isAnonymous = false
    @State private var selectedFlag: FlagCategory? = nil
    
    private let maxCharacters: Int = 500
    
    enum FlagCategory: String, CaseIterable, Identifiable {
        case red = "Red Flag"
        case green = "Green Flag"
        var id: String { rawValue }
    }
    
    // Controlled tags are defined in `ControlledTags.swift`
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Text Editor with Material Glass background
                GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg, padding: 0) {
                    TextEditor(text: $postText)
                        .padding(UISpacing.md)
                        .frame(height: 150)
                        .background(Color.clear)
                        .overlay(
                            postText.isEmpty ? 
                                Text("Share your experience...")
                                    .foregroundColor(UIColors.secondaryLabel)
                                    .padding(.top, UISpacing.md)
                                    .padding(.leading, UISpacing.md)
                                    .allowsHitTesting(false) : nil,
                            alignment: .topLeading
                        )
                        .onChange(of: postText) { _, newValue in
                            if newValue.count > maxCharacters {
                                postText = String(newValue.prefix(maxCharacters))
                            }
                        }
                }
                .padding(UISpacing.md)
                
                // Character Counter
                HStack {
                    Spacer()
                    Text("\(postText.count)/\(maxCharacters)")
                        .font(.caption)
                        .foregroundColor(postText.count > maxCharacters - 20 ? UIColors.danger : UIColors.secondaryLabel)
                        .padding(.trailing, UISpacing.md)
                }
                .padding(.bottom, UISpacing.xs)
                
                // Required Flag Selection with Material Glass
                GlassCard(material: MaterialDesignSystem.Glass.ultraThin, cornerRadius: UICornerRadius.lg) {
                    VStack(alignment: .leading, spacing: UISpacing.sm) {
                        Text("Flag")
                            .font(.headline)
                            .foregroundColor(UIColors.label)
                        
                        HStack(spacing: UISpacing.sm) {
                            ForEach(FlagCategory.allCases) { flag in
                                Button(action: {
                                    selectedFlag = flag
                                    // Add haptic feedback
                                    let selectionFeedback = UISelectionFeedbackGenerator()
                                    selectionFeedback.selectionChanged()
                                }) {
                                    HStack(spacing: UISpacing.xs) {
                                        Image(systemName: flag == .red ? "flag.fill" : "checkmark.seal.fill")
                                            .foregroundColor(flag == .red ? UIColors.danger : UIColors.success)
                                        Text(flag.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, UISpacing.md)
                                    .padding(.vertical, UISpacing.sm)
                                    .background(
                                        selectedFlag == flag ? 
                                            (flag == .red ? MaterialDesignSystem.GlassColors.danger : MaterialDesignSystem.GlassColors.success) :
                                            MaterialDesignSystem.Glass.ultraThin,
                                        in: RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                            .stroke(
                                                selectedFlag == flag ? 
                                                    (flag == .red ? UIColors.danger.opacity(0.5) : UIColors.success.opacity(0.5)) : 
                                                    MaterialDesignSystem.GlassBorders.subtle,
                                                lineWidth: selectedFlag == flag ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, UISpacing.md)
                .padding(.bottom, UISpacing.xs)
                
                // Selected Image Preview with Material Glass
                if let selectedImage = selectedImage {
                    GlassCard(material: MaterialDesignSystem.Glass.thin, cornerRadius: UICornerRadius.lg, padding: 0) {
                        Image(uiImage: isImageRevealed ? selectedImage : ImageProcessing.blurForUpload(selectedImage))
                            .resizable()
                            .scaledToFit()
                            .clipped()
                            .onTapGesture { 
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { 
                                    isImageRevealed.toggle() 
                                }
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                            .overlay(
                                Group {
                                    if !isImageRevealed {
                                        Text("Tap to reveal")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(UIColors.label)
                                            .padding(UISpacing.xs)
                                            .background(MaterialDesignSystem.Glass.regular, in: Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                                            )
                                            .padding(UISpacing.sm)
                                    }
                                }, alignment: .bottomTrailing
                            )
                            .overlay(
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                                        self.selectedImage = nil 
                                    }
                                    // Add haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.7))
                                                .frame(width: 28, height: 28)
                                        )
                                }
                                .padding(UISpacing.sm),
                                alignment: .topTrailing
                            )
                    }
                    .padding(.horizontal, UISpacing.md)
                }
                
                // Tag Selection with Material Glass
                GlassCard(material: MaterialDesignSystem.Glass.ultraThin, cornerRadius: UICornerRadius.lg) {
                    VStack(alignment: .leading, spacing: UISpacing.sm) {
                        Text("Add Tags")
                            .font(.headline)
                            .foregroundColor(UIColors.label)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: UISpacing.xs) {
                                ForEach(TagCatalog.all) { tag in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                        // Add haptic feedback
                                        let selectionFeedback = UISelectionFeedbackGenerator()
                                        selectionFeedback.selectionChanged()
                                    }) {
                                        Text(tag.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(
                                                selectedTags.contains(tag) ? 
                                                    UIColors.accentPrimary : 
                                                    UIColors.label
                                            )
                                            .padding(.horizontal, UISpacing.md)
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
                            }
                            .padding(.horizontal, UISpacing.xxs)
                        }
                    }
                }
                .padding(.horizontal, UISpacing.md)
                .padding(.vertical, UISpacing.xs)
                
                // Anonymous Toggle with Material Glass
                GlassCard(material: MaterialDesignSystem.Glass.ultraThin, cornerRadius: UICornerRadius.lg) {
                    Toggle(isOn: $isAnonymous) {
                        HStack(spacing: UISpacing.sm) {
                            Image(systemName: "theatermasks")
                                .foregroundColor(UIColors.accentSecondary)
                                .font(.system(size: 16, weight: .medium))
                            Text("Post Anonymously")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(UIColors.label)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: UIColors.accentSecondary))
                }
                .padding(.horizontal, UISpacing.md)
                .padding(.vertical, UISpacing.xs)
                
                Spacer()
                
                // Action Buttons with Material Glass
                HStack(spacing: UISpacing.md) {
                    GlassButton(
                        "Photo",
                        systemImage: "photo",
                        style: .secondary
                    ) {
                        isImagePickerPresented = true
                    }
                    
                    GlassButton(
                        NSLocalizedString("Post", comment: ""),
                        style: canPost ? .primary : .subtle
                    ) {
                        let trimmed = postText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let flag = selectedFlag == .red ? "red" : "green"
                        let tags = selectedTags.map { $0.rawValue }
                        Task {
                            do {
                                try await services.postSubmissionService.createPost(content: trimmed, flag: flag, tags: tags, anonymous: isAnonymous)
                                // Success haptic feedback
                                let notificationFeedback = UINotificationFeedbackGenerator()
                                notificationFeedback.notificationOccurred(.success)
                                toastCenter.show(.success, NSLocalizedString("Posted", comment: ""))
                                presentationMode.wrappedValue.dismiss()
                            } catch {
                                // Error haptic feedback
                                let notificationFeedback = UINotificationFeedbackGenerator()
                                notificationFeedback.notificationOccurred(.error)
                                toastCenter.show(.error, ErrorPresenter.message(for: error))
                            }
                        }
                    }
                    .disabled(!canPost)
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
                    Text("New Post")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(UIColors.label)
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                // Material Glass modal for image picker
                GlassModal(isPresented: $isImagePickerPresented) {
                    VStack(spacing: UISpacing.lg) {
                        Text("Select Image")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(UIColors.label)
                        
                        Text("In a real app, this would open PHPickerViewController")
                            .font(.body)
                            .foregroundColor(UIColors.secondaryLabel)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: UISpacing.md) {
                            GlassButton("Select Demo Image", systemImage: "photo", style: .primary) {
                                // Simulate image selection
                                if let raw = UIImage(systemName: "photo") {
                                    let stripped = ImageProcessing.stripEXIF(raw)
                                    self.selectedImage = stripped
                                    self.isImageRevealed = false
                                }
                                isImagePickerPresented = false
                            }
                            
                            GlassButton("Cancel", style: .secondary) {
                                isImagePickerPresented = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var canPost: Bool {
        let trimmed = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxCharacters && selectedFlag != nil
    }
}

// MARK: - Preview
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
