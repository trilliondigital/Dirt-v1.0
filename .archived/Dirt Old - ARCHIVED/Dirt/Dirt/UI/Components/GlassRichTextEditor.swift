import SwiftUI

/// A Material Glass rich text editor component with formatting options
struct GlassRichTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let maxCharacters: Int
    let accessibilityLabel: String?
    let accessibilityHint: String?
    
    @FocusState private var isFocused: Bool
    @State private var showFormatting: Bool = false
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Formatting states
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var currentFontSize: CGFloat = 16
    
    init(
        text: Binding<String>,
        placeholder: String = "Enter your text...",
        maxCharacters: Int = 10000,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.maxCharacters = maxCharacters
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
    
    var body: some View {
        VStack(spacing: UISpacing.sm) {
            // Formatting toolbar (shown when focused)
            if showFormatting && isFocused {
                formattingToolbar
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Text editor
            textEditorView
            
            // Character count and info
            editorFooter
        }
        .animation(
            AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.2)),
            value: showFormatting
        )
    }
    
    // MARK: - Text Editor View
    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: UICornerRadius.md)
                .fill(MaterialDesignSystem.Glass.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: UICornerRadius.md)
                        .stroke(
                            isFocused ? 
                                AccessibilitySystem.AccessibleColors.focusRing : 
                                MaterialDesignSystem.GlassBorders.subtle,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
            
            // Text editor
            TextEditor(text: $text)
                .focused($isFocused)
                .font(AccessibilitySystem.DynamicType.scaledFont(
                    size: currentFontSize,
                    weight: isBold ? .semibold : .regular
                ))
                .foregroundColor(AccessibilitySystem.AccessibleColors.primaryText)
                .padding(AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm))
                .background(Color.clear)
                .accessibilityLabel(accessibilityLabel ?? "Rich text editor")
                .accessibilityHint(accessibilityHint ?? "Enter and format your text")
                .accessibilityAddTraits(.allowsDirectInteraction)
                .onChange(of: text) { _, newValue in
                    // Enforce character limit
                    if newValue.count > maxCharacters {
                        text = String(newValue.prefix(maxCharacters))
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    withAnimation(AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.2))) {
                        showFormatting = focused
                    }
                }
            
            // Placeholder text
            if text.isEmpty {
                Text(placeholder)
                    .font(AccessibilitySystem.DynamicType.scaledFont(size: currentFontSize))
                    .foregroundColor(AccessibilitySystem.AccessibleColors.secondaryText)
                    .padding(.top, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm + 8))
                    .padding(.leading, AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm + 5))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 120)
        .glassFocusRing(isFocused: isFocused, cornerRadius: UICornerRadius.md)
        .glassHighContrast()
    }
    
    // MARK: - Formatting Toolbar
    private var formattingToolbar: some View {
        GlassCard(
            material: MaterialDesignSystem.Glass.thin,
            cornerRadius: UICornerRadius.sm,
            padding: UISpacing.sm
        ) {
            HStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.sm)) {
                // Bold button
                formatButton(
                    systemImage: "bold",
                    isActive: isBold,
                    accessibilityLabel: "Bold",
                    accessibilityHint: "Double tap to toggle bold formatting"
                ) {
                    toggleBold()
                }
                
                // Italic button
                formatButton(
                    systemImage: "italic",
                    isActive: isItalic,
                    accessibilityLabel: "Italic",
                    accessibilityHint: "Double tap to toggle italic formatting"
                ) {
                    toggleItalic()
                }
                
                Divider()
                    .frame(height: 20)
                    .background(MaterialDesignSystem.GlassBorders.subtle)
                
                // Font size controls
                formatButton(
                    systemImage: "textformat.size.smaller",
                    isActive: false,
                    accessibilityLabel: "Decrease font size",
                    accessibilityHint: "Double tap to make text smaller"
                ) {
                    decreaseFontSize()
                }
                
                formatButton(
                    systemImage: "textformat.size.larger",
                    isActive: false,
                    accessibilityLabel: "Increase font size",
                    accessibilityHint: "Double tap to make text larger"
                ) {
                    increaseFontSize()
                }
                
                Spacer()
                
                // Dismiss formatting toolbar
                formatButton(
                    systemImage: "keyboard.chevron.compact.down",
                    isActive: false,
                    accessibilityLabel: "Hide formatting",
                    accessibilityHint: "Double tap to hide formatting options"
                ) {
                    isFocused = false
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Text formatting toolbar")
    }
    
    // MARK: - Format Button Helper
    private func formatButton(
        systemImage: String,
        isActive: Bool,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            // Haptic feedback
            if !UIAccessibility.isReduceMotionEnabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            action()
        }) {
            Image(systemName: systemImage)
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 16, weight: .medium))
                .foregroundColor(
                    isActive ? 
                        AccessibilitySystem.AccessibleColors.accessibleBlue : 
                        AccessibilitySystem.AccessibleColors.primaryText
                )
                .frame(width: 32, height: 32)
                .background(
                    isActive ? 
                        MaterialDesignSystem.GlassColors.primary : 
                        Color.clear,
                    in: RoundedRectangle(cornerRadius: UICornerRadius.xs)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
        .accessibleTouchTarget()
    }
    
    // MARK: - Editor Footer
    private var editorFooter: some View {
        HStack {
            // Formatting info
            if isBold || isItalic || currentFontSize != 16 {
                HStack(spacing: AccessibilitySystem.DynamicType.scaledSpacing(UISpacing.xs)) {
                    if isBold {
                        Text("Bold")
                            .font(AccessibilitySystem.DynamicType.scaledFont(size: 12, weight: .semibold))
                    }
                    if isItalic {
                        Text("Italic")
                            .font(AccessibilitySystem.DynamicType.scaledFont(size: 12, weight: .regular))
                            .italic()
                    }
                    if currentFontSize != 16 {
                        Text("Size: \(Int(currentFontSize))")
                            .font(AccessibilitySystem.DynamicType.scaledFont(size: 12))
                    }
                }
                .foregroundColor(AccessibilitySystem.AccessibleColors.secondaryText)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current formatting: \(formattingDescription)")
            }
            
            Spacer()
            
            // Character count
            Text("\(text.count)/\(maxCharacters)")
                .font(AccessibilitySystem.DynamicType.scaledFont(size: 12))
                .foregroundColor(
                    text.count > maxCharacters - 100 ? 
                        UIColors.danger : 
                        AccessibilitySystem.AccessibleColors.secondaryText
                )
                .accessibilityLabel("Character count: \(text.count) of \(maxCharacters)")
        }
    }
    
    // MARK: - Formatting Actions
    private func toggleBold() {
        withAnimation(AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.1))) {
            isBold.toggle()
        }
        
        // Announce to VoiceOver
        let announcement = isBold ? "Bold formatting enabled" : "Bold formatting disabled"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    private func toggleItalic() {
        withAnimation(AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.1))) {
            isItalic.toggle()
        }
        
        // Announce to VoiceOver
        let announcement = isItalic ? "Italic formatting enabled" : "Italic formatting disabled"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    private func increaseFontSize() {
        let newSize = min(currentFontSize + 2, 24)
        if newSize != currentFontSize {
            withAnimation(AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.1))) {
                currentFontSize = newSize
            }
            
            // Announce to VoiceOver
            UIAccessibility.post(notification: .announcement, argument: "Font size increased to \(Int(newSize))")
        }
    }
    
    private func decreaseFontSize() {
        let newSize = max(currentFontSize - 2, 12)
        if newSize != currentFontSize {
            withAnimation(AccessibilitySystem.ReducedMotion.animation(.easeInOut(duration: 0.1))) {
                currentFontSize = newSize
            }
            
            // Announce to VoiceOver
            UIAccessibility.post(notification: .announcement, argument: "Font size decreased to \(Int(newSize))")
        }
    }
    
    // MARK: - Computed Properties
    private var formattingDescription: String {
        var description: [String] = []
        
        if isBold { description.append("bold") }
        if isItalic { description.append("italic") }
        if currentFontSize != 16 { description.append("size \(Int(currentFontSize))") }
        
        return description.isEmpty ? "none" : description.joined(separator: ", ")
    }
}

// MARK: - Preview
struct GlassRichTextEditor_Previews: PreviewProvider {
    @State static var text = ""
    
    static var previews: some View {
        VStack {
            GlassRichTextEditor(
                text: $text,
                placeholder: "Enter your discussion content...",
                maxCharacters: 1000
            )
            
            Spacer()
        }
        .padding()
        .background(UIColors.groupedBackground)
    }
}