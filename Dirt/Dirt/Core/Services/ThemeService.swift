import Foundation
import SwiftUI

// MARK: - Theme Types

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Colors

struct AppColors {
    // Primary Colors
    static let primaryLight = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let primaryDark = Color(red: 0.4, green: 0.78, blue: 1.0)
    
    // Background Colors
    #if canImport(UIKit)
    static let backgroundLight = Color(.systemBackground)
    static let backgroundDark = Color(.systemBackground)
    
    static let secondaryBackgroundLight = Color(.secondarySystemBackground)
    static let secondaryBackgroundDark = Color(.secondarySystemBackground)
    
    // Text Colors
    static let textPrimaryLight = Color(.label)
    static let textPrimaryDark = Color(.label)
    
    static let textSecondaryLight = Color(.secondaryLabel)
    static let textSecondaryDark = Color(.secondaryLabel)
    
    // Border Colors
    static let borderLight = Color(.separator)
    static let borderDark = Color(.separator)
    
    // Card Colors
    static let cardLight = Color(.systemBackground)
    static let cardDark = Color(.systemBackground)
    #else
    // macOS fallbacks
    static let backgroundLight = Color(.windowBackground)
    static let backgroundDark = Color(.windowBackground)
    
    static let secondaryBackgroundLight = Color(.controlBackground)
    static let secondaryBackgroundDark = Color(.controlBackground)
    
    // Text Colors
    static let textPrimaryLight = Color(.labelColor)
    static let textPrimaryDark = Color(.labelColor)
    
    static let textSecondaryLight = Color(.secondaryLabelColor)
    static let textSecondaryDark = Color(.secondaryLabelColor)
    
    // Border Colors
    static let borderLight = Color(.separatorColor)
    static let borderDark = Color(.separatorColor)
    
    // Card Colors
    static let cardLight = Color(.controlBackgroundColor)
    static let cardDark = Color(.controlBackgroundColor)
    #endif
    
    // Success/Error Colors
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let info = Color.blue
}

// MARK: - Theme Service

@MainActor
class ThemeService: ObservableObject {
    static let shared = ThemeService()
    
    @Published var currentTheme: AppTheme = .system {
        didSet {
            saveTheme()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    private let themeKey = "selectedTheme"
    
    private init() {
        loadTheme()
        updateDarkModeStatus()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        updateDarkModeStatus()
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func updateDarkModeStatus() {
        switch currentTheme {
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }
    }
    
    // Color getters based on current theme
    var primaryColor: Color {
        isDarkMode ? AppColors.primaryDark : AppColors.primaryLight
    }
    
    var backgroundColor: Color {
        isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight
    }
    
    var secondaryBackgroundColor: Color {
        isDarkMode ? AppColors.secondaryBackgroundDark : AppColors.secondaryBackgroundLight
    }
    
    var textPrimaryColor: Color {
        isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight
    }
    
    var textSecondaryColor: Color {
        isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight
    }
    
    var borderColor: Color {
        isDarkMode ? AppColors.borderDark : AppColors.borderLight
    }
    
    var cardColor: Color {
        isDarkMode ? AppColors.cardDark : AppColors.cardLight
    }
}

// MARK: - Theme Toggle Component

struct ThemeToggleView: View {
    @StateObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    ThemeOptionRow(
                        theme: theme,
                        isSelected: themeService.currentTheme == theme
                    ) {
                        themeService.setTheme(theme)
                    }
                }
            }
        }
    }
}

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(themeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var themeDescription: String {
        switch theme {
        case .system:
            return "Matches your device settings"
        case .light:
            return "Light mode always"
        case .dark:
            return "Dark mode always"
        }
    }
}

// MARK: - Theme Environment

struct ThemeEnvironment: ViewModifier {
    @StateObject private var themeService = ThemeService.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeService.currentTheme.colorScheme)
            .environmentObject(themeService)
    }
}

extension View {
    func withTheme() -> some View {
        modifier(ThemeEnvironment())
    }
}

// MARK: - Custom Styled Components

struct ThemedCard<Content: View>: View {
    @EnvironmentObject private var themeService: ThemeService
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(themeService.cardColor)
            .cornerRadius(12)
            .shadow(
                color: themeService.isDarkMode ? .clear : .black.opacity(0.1),
                radius: themeService.isDarkMode ? 0 : 4,
                x: 0,
                y: themeService.isDarkMode ? 0 : 2
            )
    }
}

struct ThemedButton: View {
    @EnvironmentObject private var themeService: ThemeService
    let title: String
    let action: () -> Void
    let style: ButtonStyleType
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
    }
    
    init(_ title: String, style: ButtonStyleType = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(8)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return themeService.primaryColor
        case .secondary:
            return themeService.secondaryBackgroundColor
        case .destructive:
            return AppColors.error
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return themeService.textPrimaryColor
        }
    }
}

struct ThemedTextField: View {
    @EnvironmentObject private var themeService: ThemeService
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(themeService.secondaryBackgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeService.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Status Bar Style

struct StatusBarStyleModifier: ViewModifier {
    @EnvironmentObject private var themeService: ThemeService
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateStatusBarStyle()
            }
            .onChange(of: themeService.isDarkMode) { _ in
                updateStatusBarStyle()
            }
    }
    
    private func updateStatusBarStyle() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.statusBarManager?.statusBarStyle = themeService.isDarkMode ? .lightContent : .darkContent
            }
        }
    }
}

extension View {
    func statusBarStyle() -> some View {
        modifier(StatusBarStyleModifier())
    }
}

// MARK: - Theme Preview

struct ThemePreview: View {
    @StateObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            ThemedCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Card")
                        .font(.headline)
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Text("This is how content looks in the current theme.")
                        .font(.body)
                        .foregroundColor(themeService.textSecondaryColor)
                    
                    HStack {
                        ThemedButton("Primary") {}
                        ThemedButton("Secondary", style: .secondary) {}
                        ThemedButton("Destructive", style: .destructive) {}
                    }
                }
            }
            
            ThemedCard {
                VStack(spacing: 12) {
                    ThemedTextField("Sample Input", text: .constant(""))
                    ThemedTextField("Password", text: .constant(""), isSecure: true)
                }
            }
        }
        .padding()
        .background(themeService.backgroundColor)
    }
}