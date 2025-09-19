import SwiftUI
import Combine

/// Theme management system for handling light/dark mode and user preferences
@MainActor
class ThemeManager: ObservableObject {
    
    // MARK: - Theme Types
    enum AppTheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .system:
                return "System"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
        
        var systemImage: String {
            switch self {
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            case .system:
                return "circle.lefthalf.filled"
            }
        }
    }
    
    // MARK: - Published Properties
    @Published var currentTheme: AppTheme {
        didSet {
            saveThemePreference()
        }
    }
    
    @Published var isDarkMode: Bool = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme_preference"
    
    // MARK: - Initialization
    init() {
        // Load saved theme preference or default to system
        let savedTheme = userDefaults.string(forKey: themeKey) ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        // Set initial dark mode state
        updateDarkModeState()
    }
    
    // MARK: - Public Methods
    
    /// Set the app theme
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
            currentTheme = theme
            updateDarkModeState()
        }
    }
    
    /// Toggle between light and dark themes (skips system)
    func toggleTheme() {
        let newTheme: AppTheme = currentTheme == .light ? .dark : .light
        setTheme(newTheme)
    }
    
    /// Update dark mode state based on current theme and system settings
    func updateDarkModeState() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            // This will be updated by the system when color scheme changes
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    /// Handle system color scheme changes
    func handleSystemColorSchemeChange(_ colorScheme: ColorScheme) {
        if currentTheme == .system {
            withAnimation(.easeInOut(duration: DesignTokens.Animation.quick)) {
                isDarkMode = colorScheme == .dark
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveThemePreference() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
}

// MARK: - Theme-Aware Color Extensions
extension Color {
    
    /// Dynamic color that adapts to current theme
    static func dynamicColor(
        light: Color,
        dark: Color
    ) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    /// Semantic colors that adapt to theme
    static var adaptivePrimary: Color {
        dynamicColor(
            light: DesignTokens.Colors.primaryLight,
            dark: DesignTokens.Colors.primaryDark
        )
    }
    
    static var adaptiveSecondary: Color {
        dynamicColor(
            light: DesignTokens.Colors.secondaryLight,
            dark: DesignTokens.Colors.secondaryDark
        )
    }
    
    static var adaptiveSuccess: Color {
        dynamicColor(
            light: DesignTokens.Colors.successLight,
            dark: DesignTokens.Colors.successDark
        )
    }
    
    static var adaptiveWarning: Color {
        dynamicColor(
            light: DesignTokens.Colors.warningLight,
            dark: DesignTokens.Colors.warningDark
        )
    }
    
    static var adaptiveError: Color {
        dynamicColor(
            light: DesignTokens.Colors.errorLight,
            dark: DesignTokens.Colors.errorDark
        )
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme Modifier
struct ThemeModifier: ViewModifier {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.colorScheme) private var systemColorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.themeManager, themeManager)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onChange(of: systemColorScheme) { newColorScheme in
                themeManager.handleSystemColorSchemeChange(newColorScheme)
            }
            .onAppear {
                themeManager.updateDarkModeState()
            }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply theme management to the view hierarchy
    func withThemeManagement() -> some View {
        self.modifier(ThemeModifier())
    }
}

// MARK: - Theme Utilities
extension ThemeManager {
    
    /// Get appropriate material type based on current theme
    var preferredMaterialType: MaterialDesignSystem.MaterialType {
        isDarkMode ? .regular : .thin
    }
    
    /// Get theme-appropriate shadow opacity
    var shadowOpacity: Double {
        isDarkMode ? 0.3 : 0.15
    }
    
    /// Get theme-appropriate border opacity
    var borderOpacity: Double {
        isDarkMode ? 0.2 : 0.1
    }
}