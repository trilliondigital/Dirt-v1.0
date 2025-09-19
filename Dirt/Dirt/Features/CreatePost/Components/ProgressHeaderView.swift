import SwiftUI

struct ProgressHeaderView: View {
    let currentStep: PostCreationStep
    let progress: Double
    
    var body: some View {
        VStack(spacing: DesignTokens.spacing.md) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(ColorPalette.primary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
            
            // Step Information
            VStack(spacing: DesignTokens.spacing.xs) {
                HStack {
                    Image(systemName: currentStep.iconName)
                        .foregroundColor(ColorPalette.primary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentStep.title)
                            .font(TypographyStyles.headline)
                            .foregroundColor(ColorPalette.textPrimary)
                        
                        Text(currentStep.description)
                            .font(TypographyStyles.caption1)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Step Counter
                    Text("\(stepNumber)/\(totalSteps)")
                        .font(TypographyStyles.caption1)
                        .foregroundColor(ColorPalette.textSecondary)
                        .padding(.horizontal, DesignTokens.spacing.sm)
                        .padding(.vertical, DesignTokens.spacing.xs)
                        .background(
                            Capsule()
                                .fill(ColorPalette.surfaceSecondary)
                        )
                }
            }
        }
        .padding(.horizontal, DesignTokens.spacing.md)
        .padding(.vertical, DesignTokens.spacing.sm)
        .background(
            GlassCard(style: .thin)
        )
    }
    
    private var stepNumber: Int {
        switch currentStep {
        case .content: return 1
        case .categorization: return 2
        case .media: return 3
        case .preview: return 4
        case .publishing: return 5
        }
    }
    
    private var totalSteps: Int {
        return PostCreationStep.allCases.count
    }
}

#Preview {
    VStack {
        ProgressHeaderView(
            currentStep: .content,
            progress: 0.2
        )
        
        ProgressHeaderView(
            currentStep: .categorization,
            progress: 0.4
        )
        
        ProgressHeaderView(
            currentStep: .publishing,
            progress: 1.0
        )
    }
    .padding()
}