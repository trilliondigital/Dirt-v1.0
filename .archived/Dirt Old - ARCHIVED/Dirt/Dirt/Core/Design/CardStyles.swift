import SwiftUI

// MARK: - Reusable Card Styles
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(UIColors.background)
            .cornerRadius(UICornerRadius.lg)
            .shadow(color: UIShadow.soft, radius: 10, x: 0, y: 2)
    }
}

extension View {
    func cardBackground() -> some View { self.modifier(CardBackground()) }
}