import SwiftUI

/// A customizable text field with validation, error states, and consistent styling
struct CustomTextField: View {
    
    // MARK: - Field Types
    enum FieldType {
        case text
        case email
        case password
        case search
        case multiline
        
        var keyboardType: UIKeyboardType {
            switch self {
            case .email:
                return .emailAddress
            case .text, .password, .search, .multiline:
                return .default
            }
        }
        
        var textContentType: UITextContentType? {
            switch self {
            case .email:
                return .emailAddress
            case .password:
                return .password
            case .text, .search, .multiline:
                return nil
            }
        }
        
        var autocapitalization: TextInputAutocapitalization {
            switch self {
            case .email, .password:
                return .never
            case .text, .multiline:
                return .sentences
            case .search:
                return .words
            }
        }
    }
    
    // MARK: - Validation State
    enum ValidationState {
        case none
        case valid
        case invalid(String)
        
        var isValid: Bool {
            switch self {
            case .none, .valid:
                return true
            case .invalid:
                return false
            }
        }
        
        var errorMessage: String? {
            switch self {
            case .invalid(let message):
                return message
            case .none, .valid:
                return nil
            }
        }
    }
    
    // MARK: - Properties
    let title: String
    let placeholder: String
    let type: FieldType
    let isRequired: Bool
    let maxLength: Int?
    let validation: ValidationState
    
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isSecureTextVisible = false
    @Environment(\.animationPreferences) private var animationPreferences
    
    // MARK: - Initialization
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        type: FieldType = .text,
        isRequired: Bool = false,
        maxLength: Int? = nil,
        validation: ValidationState = .none
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.type = type
        self.isRequired = isRequired
        self.maxLength = maxLength
        self.validation = validation
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Title and Required Indicator
            HStack(spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.callout.weight(.medium))
                    .foregroundColor(titleColor)
                
                if isRequired {
                    Text("*")
                        .font(DesignTokens.Typography.callout.weight(.medium))
                        .foregroundColor(Color.adaptiveError)
                }
                
                Spacer()
                
                // Character Count
                if let maxLength = maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(characterCountColor)
                }
            }
            
            // Text Field Container
            VStack(spacing: 0) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // Leading Icon
                    if let leadingIcon = leadingIcon {
                        Image(systemName: leadingIcon)
                            .foregroundColor(iconColor)
                            .font(DesignTokens.Typography.body)
                    }
                    
                    // Text Input
                    textInputView
                    
                    // Trailing Actions
                    trailingActionsView
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                )
            }
            
            // Error Message
            if let errorMessage = validation.errorMessage {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color.adaptiveError)
                        .font(DesignTokens.Typography.caption)
                    
                    Text(errorMessage)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(Color.adaptiveError)
                }
                .transition(animationPreferences.scaleTransition)
            }
        }
        .animation(animationPreferences.standardEasing, value: isFocused)
        .animation(animationPreferences.standardEasing, value: validation.isValid)
    }
    
    // MARK: - Text Input View
    @ViewBuilder
    private var textInputView: some View {
        switch type {
        case .multiline:
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .keyboardType(type.keyboardType)
                .textContentType(type.textContentType)
                .textInputAutocapitalization(type.autocapitalization)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    handleTextChange(newValue)
                }
            
        case .password:
            if isSecureTextVisible {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(type.keyboardType)
                    .textContentType(type.textContentType)
                    .textInputAutocapitalization(type.autocapitalization)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        handleTextChange(newValue)
                    }
            } else {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .textContentType(type.textContentType)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        handleTextChange(newValue)
                    }
            }
            
        default:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(type.keyboardType)
                .textContentType(type.textContentType)
                .textInputAutocapitalization(type.autocapitalization)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    handleTextChange(newValue)
                }
        }
    }
    
    // MARK: - Trailing Actions View
    @ViewBuilder
    private var trailingActionsView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            // Clear Button
            if !text.isEmpty && isFocused {
                Button(action: clearText) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .font(DesignTokens.Typography.body)
                }
            }
            
            // Password Visibility Toggle
            if type == .password {
                Button(action: togglePasswordVisibility) {
                    Image(systemName: isSecureTextVisible ? "eye.slash" : "eye")
                        .foregroundColor(iconColor)
                        .font(DesignTokens.Typography.body)
                }
            }
            
            // Validation Indicator
            if case .valid = validation {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.adaptiveSuccess)
                    .font(DesignTokens.Typography.body)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var leadingIcon: String? {
        switch type {
        case .email:
            return "envelope"
        case .password:
            return "lock"
        case .search:
            return "magnifyingglass"
        case .text, .multiline:
            return nil
        }
    }
    
    private var titleColor: Color {
        if !validation.isValid {
            return Color.adaptiveError
        }
        return isFocused ? Color.adaptivePrimary : DesignTokens.Colors.textPrimary
    }
    
    private var backgroundColor: Color {
        DesignTokens.Colors.surface
    }
    
    private var borderColor: Color {
        if !validation.isValid {
            return Color.adaptiveError
        }
        return isFocused ? Color.adaptivePrimary : DesignTokens.Colors.border
    }
    
    private var borderWidth: CGFloat {
        isFocused || !validation.isValid ? 2 : 1
    }
    
    private var iconColor: Color {
        if !validation.isValid {
            return Color.adaptiveError
        }
        return isFocused ? Color.adaptivePrimary : DesignTokens.Colors.textSecondary
    }
    
    private var characterCountColor: Color {
        guard let maxLength = maxLength else { return DesignTokens.Colors.textTertiary }
        
        let ratio = Double(text.count) / Double(maxLength)
        if ratio >= 1.0 {
            return Color.adaptiveError
        } else if ratio >= 0.8 {
            return Color.adaptiveWarning
        } else {
            return DesignTokens.Colors.textTertiary
        }
    }
    
    // MARK: - Methods
    private func handleTextChange(_ newValue: String) {
        // Enforce max length
        if let maxLength = maxLength, newValue.count > maxLength {
            text = String(newValue.prefix(maxLength))
            animationPreferences.warningHaptic()
        }
    }
    
    private func clearText() {
        text = ""
        animationPreferences.lightHaptic()
    }
    
    private func togglePasswordVisibility() {
        isSecureTextVisible.toggle()
        animationPreferences.lightHaptic()
    }
}

// MARK: - Convenience Initializers
extension CustomTextField {
    
    /// Create an email text field
    static func email(
        title: String = "Email",
        placeholder: String = "Enter your email",
        text: Binding<String>,
        isRequired: Bool = false,
        validation: ValidationState = .none
    ) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            type: .email,
            isRequired: isRequired,
            validation: validation
        )
    }
    
    /// Create a password text field
    static func password(
        title: String = "Password",
        placeholder: String = "Enter your password",
        text: Binding<String>,
        isRequired: Bool = false,
        validation: ValidationState = .none
    ) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            type: .password,
            isRequired: isRequired,
            validation: validation
        )
    }
    
    /// Create a search text field
    static func search(
        placeholder: String = "Search...",
        text: Binding<String>
    ) -> CustomTextField {
        CustomTextField(
            title: "",
            placeholder: placeholder,
            text: text,
            type: .search
        )
    }
    
    /// Create a multiline text field
    static func multiline(
        title: String,
        placeholder: String = "Enter text...",
        text: Binding<String>,
        maxLength: Int? = nil,
        validation: ValidationState = .none
    ) -> CustomTextField {
        CustomTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            type: .multiline,
            maxLength: maxLength,
            validation: validation
        )
    }
}

// MARK: - Preview
#Preview("Custom Text Field") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            CustomTextField.email(
                text: .constant("user@example.com"),
                isRequired: true,
                validation: .valid
            )
            
            CustomTextField.password(
                text: .constant("password123"),
                isRequired: true,
                validation: .invalid("Password must be at least 8 characters")
            )
            
            CustomTextField.search(
                text: .constant("Search query")
            )
            
            CustomTextField.multiline(
                title: "Description",
                text: .constant("This is a multiline text field that can expand to show more content."),
                maxLength: 200
            )
            
            CustomTextField(
                title: "Username",
                placeholder: "Enter username",
                text: .constant("johndoe"),
                isRequired: true,
                maxLength: 20,
                validation: .valid
            )
        }
        .padding(DesignTokens.Spacing.lg)
    }
    .background(DesignTokens.Colors.background)
    .withAnimationPreferences()
}