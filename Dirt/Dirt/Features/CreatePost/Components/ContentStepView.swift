import SwiftUI

struct ContentStepView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @FocusState private var titleFocused: Bool
    @FocusState private var contentFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing.lg) {
                // Title Section
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    HStack {
                        Text("Title")
                            .font(TypographyStyles.headline)
                            .foregroundColor(ColorPalette.textPrimary)
                        
                        Spacer()
                        
                        CharacterCountView(
                            current: viewModel.titleCharacterCount,
                            limit: viewModel.titleCharacterLimit
                        )
                    }
                    
                    CustomTextField(
                        placeholder: "What's your story about?",
                        text: $viewModel.title,
                        style: .large
                    )
                    .focused($titleFocused)
                    .onSubmit {
                        contentFocused = true
                    }
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    HStack {
                        Text("Content")
                            .font(TypographyStyles.headline)
                            .foregroundColor(ColorPalette.textPrimary)
                        
                        Spacer()
                        
                        CharacterCountView(
                            current: viewModel.contentCharacterCount,
                            limit: viewModel.contentCharacterLimit
                        )
                    }
                    
                    RichTextEditor(
                        text: $viewModel.content,
                        placeholder: "Share your experience, ask a question, or give advice to the community..."
                    )
                    .focused($contentFocused)
                    .frame(minHeight: 200)
                }
                
                // Writing Tips
                WritingTipsView()
                
                // Validation Errors
                if !viewModel.validationErrors.isEmpty {
                    ValidationErrorsView(errors: viewModel.validationErrors)
                }
            }
            .padding(DesignTokens.spacing.md)
        }
        .onAppear {
            titleFocused = true
            viewModel.validateCurrentStep()
        }
        .onChange(of: viewModel.title) { _ in
            viewModel.validateCurrentStep()
        }
        .onChange(of: viewModel.content) { _ in
            viewModel.validateCurrentStep()
        }
    }
}

struct CharacterCountView: View {
    let current: Int
    let limit: Int
    
    private var isNearLimit: Bool {
        Double(current) / Double(limit) > 0.8
    }
    
    private var isOverLimit: Bool {
        current > limit
    }
    
    var body: some View {
        Text("\(current)/\(limit)")
            .font(TypographyStyles.caption1)
            .foregroundColor(
                isOverLimit ? ColorPalette.error :
                isNearLimit ? ColorPalette.warning :
                ColorPalette.textSecondary
            )
            .animation(.easeInOut(duration: 0.2), value: current)
    }
}

struct RichTextEditor: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(TypographyStyles.body)
                .foregroundColor(ColorPalette.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            
            if text.isEmpty {
                Text(placeholder)
                    .font(TypographyStyles.body)
                    .foregroundColor(ColorPalette.textTertiary)
                    .padding(.top, 8)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(ColorPalette.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                        .stroke(ColorPalette.border, lineWidth: 1)
                )
        )
    }
}

struct WritingTipsView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(ColorPalette.warning)
                    
                    Text("Writing Tips")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(ColorPalette.textSecondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.xs) {
                    TipRow(icon: "checkmark.circle", text: "Be specific and detailed in your experiences")
                    TipRow(icon: "heart", text: "Share both positive and negative experiences")
                    TipRow(icon: "person.2", text: "Respect others' privacy - avoid identifying details")
                    TipRow(icon: "shield", text: "Follow community guidelines for helpful content")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(ColorPalette.warning.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(ColorPalette.success)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(TypographyStyles.caption1)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
}

struct ValidationErrorsView: View {
    let errors: [ValidationError]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.xs) {
            ForEach(errors) { error in
                HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ColorPalette.error)
                        .font(.caption)
                    
                    Text(error.message)
                        .font(TypographyStyles.caption1)
                        .foregroundColor(ColorPalette.error)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(ColorPalette.error.opacity(0.1))
        )
    }
}

#Preview {
    ContentStepView(viewModel: CreatePostViewModel())
}