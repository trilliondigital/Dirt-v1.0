import SwiftUI

struct PublishingStepView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: DesignTokens.spacing.xl) {
            Spacer()
            
            // Publishing Animation
            PublishingAnimationView(
                progress: viewModel.postingProgress,
                isComplete: viewModel.postingProgress >= 1.0
            )
            
            // Status Text
            VStack(spacing: DesignTokens.spacing.sm) {
                Text(statusTitle)
                    .font(TypographyStyles.title2)
                    .foregroundColor(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(statusDescription)
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Bar
            if viewModel.isPosting {
                ProgressView(value: viewModel.postingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: ColorPalette.primary))
                    .scaleEffect(y: 2)
                    .padding(.horizontal, DesignTokens.spacing.xl)
            }
            
            Spacer()
            
            // Action Button
            if viewModel.postingProgress >= 1.0 {
                VStack(spacing: DesignTokens.spacing.md) {
                    ActionButton(
                        title: "View in Feed",
                        style: .primary,
                        size: .large,
                        action: {
                            // Navigate to feed
                            dismiss()
                        }
                    )
                    
                    ActionButton(
                        title: "Create Another Post",
                        style: .secondary,
                        size: .medium,
                        action: {
                            viewModel.resetForm()
                        }
                    )
                }
                .padding(.horizontal, DesignTokens.spacing.md)
            }
        }
        .padding(DesignTokens.spacing.md)
        .onAppear {
            // Auto-dismiss after completion
            if viewModel.postingProgress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        }
    }
    
    private var statusTitle: String {
        if viewModel.postingProgress >= 1.0 {
            return "Post Published!"
        } else if viewModel.isPosting {
            return "Publishing Your Post"
        } else {
            return "Ready to Publish"
        }
    }
    
    private var statusDescription: String {
        if viewModel.postingProgress >= 1.0 {
            return "Your post has been shared with the community and is now visible in the feed."
        } else if viewModel.isPosting {
            return "Please wait while we process and publish your post to the community."
        } else {
            return "Your post is ready to be shared with the community."
        }
    }
}

struct PublishingAnimationView: View {
    let progress: Double
    let isComplete: Bool
    
    @State private var animationOffset: CGFloat = 0
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(ColorPalette.border, lineWidth: 3)
                .frame(width: 120, height: 120)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ColorPalette.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Content
            if isComplete {
                // Success Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(ColorPalette.success)
                    .scaleEffect(showCheckmark ? 1.2 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
                    .onAppear {
                        showCheckmark = true
                    }
            } else if progress > 0 {
                // Publishing Icon
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 30))
                    .foregroundColor(ColorPalette.primary)
                    .offset(x: animationOffset)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animationOffset = 10
                        }
                    }
            } else {
                // Ready Icon
                Image(systemName: "paperplane")
                    .font(.system(size: 30))
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        PublishingAnimationView(progress: 0.0, isComplete: false)
        PublishingAnimationView(progress: 0.6, isComplete: false)
        PublishingAnimationView(progress: 1.0, isComplete: true)
    }
}