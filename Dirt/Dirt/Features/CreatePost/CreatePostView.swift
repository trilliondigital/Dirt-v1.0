import SwiftUI

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                ProgressHeaderView(
                    currentStep: viewModel.currentStep,
                    progress: viewModel.progressPercentage
                )
                
                // Step Content
                TabView(selection: $viewModel.currentStep) {
                    ContentStepView(viewModel: viewModel)
                        .tag(PostCreationStep.content)
                    
                    CategorizationStepView(viewModel: viewModel)
                        .tag(PostCreationStep.categorization)
                    
                    MediaStepView(viewModel: viewModel)
                        .tag(PostCreationStep.media)
                    
                    PreviewStepView(viewModel: viewModel)
                        .tag(PostCreationStep.preview)
                    
                    PublishingStepView(viewModel: viewModel)
                        .tag(PostCreationStep.publishing)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Navigation Controls (hide during publishing)
                if viewModel.currentStep != .publishing {
                    NavigationControlsView(viewModel: viewModel)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .publishing {
                        Button("Cancel") {
                            if viewModel.hasUnsavedChanges {
                                // Show confirmation alert
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep != .publishing {
                        AutoSaveStatusView(status: viewModel.autoSaveStatus)
                    }
                }
            }
            .alert("Unsaved Changes", isPresented: .constant(viewModel.hasUnsavedChanges && viewModel.currentStep == .content)) {
                Button("Keep Editing") { }
                Button("Discard", role: .destructive) {
                    viewModel.resetForm()
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Do you want to keep editing or discard them?")
            }
        }
    }
}
