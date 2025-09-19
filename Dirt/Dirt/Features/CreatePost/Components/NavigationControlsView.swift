import SwiftUI

struct NavigationControlsView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing.md) {
            // Previous Button
            if viewModel.canGoToPreviousStep {
                ActionButton(
                    title: "Previous",
                    style: .secondary,
                    size: .medium,
                    action: {
                        viewModel.goToPreviousStep()
                    }
                )
                .frame(maxWidth: .infinity)
            }
            
            // Next/Publish Button
            ActionButton(
                title: nextButtonTitle,
                style: .primary,
                size: .medium,
                isLoading: viewModel.isPosting,
                isDisabled: !viewModel.canProceedToNextStep,
                action: {
                    viewModel.goToNextStep()
                }
            )
            .frame(maxWidth: .infinity)
        }
        .padding(DesignTokens.spacing.md)
        .background(
            GlassCard(style: .thin)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private var nextButtonTitle: String {
        switch viewModel.currentStep {
        case .content:
            return "Continue"
        case .categorization:
            return "Add Media"
        case .media:
            return "Preview"
        case .preview:
            return "Publish Post"
        case .publishing:
            return "Publishing..."
        }
    }
}

struct AutoSaveStatusView: View {
    let status: AutoSaveStatus
    
    var body: some View {
        HStack(spacing: DesignTokens.spacing.xs) {
            if status != .idle {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.caption)
                
                Text(status.message)
                    .font(TypographyStyles.caption2)
                    .foregroundColor(statusColor)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: status)
    }
    
    private var statusIcon: String {
        switch status {
        case .idle:
            return ""
        case .saving:
            return "arrow.clockwise"
        case .saved:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .idle:
            return .clear
        case .saving:
            return ColorPalette.textSecondary
        case .saved:
            return ColorPalette.success
        case .error:
            return ColorPalette.error
        }
    }
}

#Preview {
    VStack {
        NavigationControlsView(viewModel: CreatePostViewModel())
        
        Divider()
        
        HStack {
            AutoSaveStatusView(status: .saving)
            Spacer()
            AutoSaveStatusView(status: .saved)
            Spacer()
            AutoSaveStatusView(status: .error)
        }
        .padding()
    }
}