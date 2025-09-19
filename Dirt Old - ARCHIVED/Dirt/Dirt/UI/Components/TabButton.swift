import SwiftUI

/// A tab button component for custom tab bars with Material Glass styling
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? UIColors.accentPrimary : UIColors.secondaryLabel)
                
                if isSelected {
                    Capsule()
                        .fill(UIGradients.primary)
                        .frame(width: 30, height: 3)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 30, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, UISpacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}