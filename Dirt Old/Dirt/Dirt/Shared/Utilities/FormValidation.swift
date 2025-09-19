import Foundation
import SwiftUI
import Combine

// MARK: - Validation Rules

protocol ValidationRule {
    func validate(_ value: String) -> ValidationResult
}

struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Built-in Validation Rules

struct RequiredRule: ValidationRule {
    let message: String
    
    init(message: String = "This field is required") {
        self.message = message
    }
    
    func validate(_ value: String) -> ValidationResult {
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? .invalid(message) 
            : .valid
    }
}

struct EmailRule: ValidationRule {
    let message: String
    
    init(message: String = "Please enter a valid email address") {
        self.message = message
    }
    
    func validate(_ value: String) -> ValidationResult {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: value) ? .valid : .invalid(message)
    }
}

struct MinLengthRule: ValidationRule {
    let minLength: Int
    let message: String
    
    init(minLength: Int, message: String? = nil) {
        self.minLength = minLength
        self.message = message ?? "Must be at least \(minLength) characters"
    }
    
    func validate(_ value: String) -> ValidationResult {
        return value.count >= minLength ? .valid : .invalid(message)
    }
}

struct MaxLengthRule: ValidationRule {
    let maxLength: Int
    let message: String
    
    init(maxLength: Int, message: String? = nil) {
        self.maxLength = maxLength
        self.message = message ?? "Must be no more than \(maxLength) characters"
    }
    
    func validate(_ value: String) -> ValidationResult {
        return value.count <= maxLength ? .valid : .invalid(message)
    }
}

struct PhoneRule: ValidationRule {
    let message: String
    
    init(message: String = "Please enter a valid phone number") {
        self.message = message
    }
    
    func validate(_ value: String) -> ValidationResult {
        let phoneRegex = "^[+]?[1-9]?[0-9]{7,15}$"
        let cleanedValue = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: cleanedValue) ? .valid : .invalid(message)
    }
}

struct URLRule: ValidationRule {
    let message: String
    
    init(message: String = "Please enter a valid URL") {
        self.message = message
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard let url = URL(string: value), 
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return .invalid(message)
        }
        return .valid
    }
}

struct CustomRule: ValidationRule {
    let validation: (String) -> Bool
    let message: String
    
    init(message: String, validation: @escaping (String) -> Bool) {
        self.message = message
        self.validation = validation
    }
    
    func validate(_ value: String) -> ValidationResult {
        return validation(value) ? .valid : .invalid(message)
    }
}

// MARK: - Form Field

class FormField: ObservableObject {
    @Published var value: String = ""
    @Published var errorMessage: String?
    @Published var isValid: Bool = true
    @Published var hasBeenEdited: Bool = false
    
    private let rules: [ValidationRule]
    private let validateOnChange: Bool
    
    init(rules: [ValidationRule] = [], validateOnChange: Bool = true) {
        self.rules = rules
        self.validateOnChange = validateOnChange
        
        if validateOnChange {
            $value
                .dropFirst()
                .sink { [weak self] _ in
                    self?.hasBeenEdited = true
                    self?.validate()
                }
                .store(in: &cancellables)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func validate() {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                isValid = false
                errorMessage = result.errorMessage
                return
            }
        }
        isValid = true
        errorMessage = nil
    }
    
    func forceValidation() {
        hasBeenEdited = true
        validate()
    }
}

// MARK: - Form Manager

class FormManager: ObservableObject {
    @Published var isValid: Bool = false
    
    private var fields: [String: FormField] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    func addField(_ field: FormField, for key: String) {
        fields[key] = field
        
        field.$isValid
            .sink { [weak self] _ in
                self?.updateFormValidity()
            }
            .store(in: &cancellables)
    }
    
    func getField(for key: String) -> FormField? {
        return fields[key]
    }
    
    func validateAll() -> Bool {
        fields.values.forEach { $0.forceValidation() }
        updateFormValidity()
        return isValid
    }
    
    private func updateFormValidity() {
        isValid = fields.values.allSatisfy { $0.isValid }
    }
}

// MARK: - SwiftUI Components

struct ValidatedTextField: View {
    let title: String
    let placeholder: String
    @ObservedObject var field: FormField
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isSecure {
                SecureField(placeholder, text: $field.value)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $field.value)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            if field.hasBeenEdited, let errorMessage = field.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct ValidatedTextEditor: View {
    let placeholder: String
    @ObservedObject var field: FormField
    let minHeight: CGFloat
    
    init(placeholder: String, field: FormField, minHeight: CGFloat = 100) {
        self.placeholder = placeholder
        self.field = field
        self.minHeight = minHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $field.value)
                    .frame(minHeight: minHeight)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if field.value.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            
            if field.hasBeenEdited, let errorMessage = field.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Character Counter

struct CharacterCounter: View {
    let currentCount: Int
    let maxCount: Int
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(currentCount)/\(maxCount)")
                .font(.caption)
                .foregroundColor(currentCount > maxCount ? .red : .secondary)
        }
    }
}

// MARK: - Input Masking

struct MaskedTextField: View {
    let title: String
    let mask: String // e.g., "(###) ###-####" for phone
    @Binding var text: String
    
    var body: some View {
        TextField(title, text: Binding(
            get: { applyMask(to: text, mask: mask) },
            set: { text = removeMask(from: $0, mask: mask) }
        ))
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numberPad)
    }
    
    private func applyMask(to text: String, mask: String) -> String {
        let cleanText = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        var result = ""
        var textIndex = cleanText.startIndex
        
        for char in mask {
            if textIndex >= cleanText.endIndex { break }
            
            if char == "#" {
                result.append(cleanText[textIndex])
                textIndex = cleanText.index(after: textIndex)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    private func removeMask(from text: String, mask: String) -> String {
        return text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}