import SwiftUI

/// A filter pill component for displaying selectable filter options with Material Glass styling
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : UIColors.label)
                .padding(.horizontal, UISpacing.md)
                .padding(.vertical, UISpacing.xs)
                .background(
                    Group {
                        if isSelected {
                            UIGradients.primary
                        } else {
                            MaterialDesignSystem.Glass.ultraThin
                        }
                    },
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? MaterialDesignSystem.GlassBorders.accent : MaterialDesignSystem.GlassBorders.subtle,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}