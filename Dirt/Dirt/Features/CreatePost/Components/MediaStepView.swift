import SwiftUI
import PhotosUI

struct MediaStepView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
                    Text("Add Photos (Optional)")
                        .font(TypographyStyles.title2)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Text("Photos help tell your story and make your post more engaging. You can add up to \(viewModel.maxImages) images.")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textSecondary)
                }
                
                // Image Grid
                if viewModel.selectedImages.isEmpty {
                    EmptyMediaView(onAddPhotos: {
                        viewModel.showingImagePicker = true
                    })
                } else {
                    ImageGridView(
                        images: viewModel.selectedImages,
                        onRemoveImage: viewModel.removeImage,
                        onAddMore: {
                            viewModel.showingImagePicker = true
                        },
                        canAddMore: viewModel.selectedImages.count < viewModel.maxImages
                    )
                }
                
                // Media Guidelines
                MediaGuidelinesView()
            }
            .padding(DesignTokens.spacing.md)
        }
        .photosPicker(
            isPresented: $viewModel.showingImagePicker,
            selection: $selectedPhotos,
            maxSelectionCount: viewModel.maxImages - viewModel.selectedImages.count,
            matching: .images
        )
        .onChange(of: selectedPhotos) { items in
            Task {
                await loadSelectedImages(items)
            }
        }
        .onAppear {
            viewModel.validateCurrentStep()
        }
    }
    
    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.addImage(image)
                }
            }
        }
        selectedPhotos.removeAll()
    }
}

struct EmptyMediaView: View {
    let onAddPhotos: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.spacing.lg) {
            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(ColorPalette.textTertiary)
            
            // Text
            VStack(spacing: DesignTokens.spacing.sm) {
                Text("No Photos Added")
                    .font(TypographyStyles.headline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Text("Photos make your post more engaging and help others understand your experience better.")
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Add Photos Button
            ActionButton(
                title: "Add Photos",
                style: .primary,
                size: .medium,
                action: onAddPhotos
            )
        }
        .padding(DesignTokens.spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                .fill(ColorPalette.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.lg)
                        .stroke(ColorPalette.border, lineWidth: 1, lineCap: .round, dash: [5, 5])
                )
        )
    }
}

struct ImageGridView: View {
    let images: [UIImage]
    let onRemoveImage: (Int) -> Void
    let onAddMore: () -> Void
    let canAddMore: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.md) {
            // Header
            HStack {
                Text("Selected Photos (\(images.count)/4)")
                    .font(TypographyStyles.headline)
                    .foregroundColor(ColorPalette.textPrimary)
                
                Spacer()
                
                if canAddMore {
                    Button("Add More") {
                        onAddMore()
                    }
                    .font(TypographyStyles.subheadline)
                    .foregroundColor(ColorPalette.primary)
                }
            }
            
            // Image Grid
            LazyVGrid(columns: columns, spacing: DesignTokens.spacing.md) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ImageThumbnail(
                        image: image,
                        index: index,
                        onRemove: { onRemoveImage(index) }
                    )
                }
                
                // Add More Button (if space available)
                if canAddMore && images.count < 4 {
                    AddMoreImageButton(onTap: onAddMore)
                }
            }
        }
    }
}

struct ImageThumbnail: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .background(ColorPalette.surfaceSecondary)
                .cornerRadius(DesignTokens.cornerRadius.md)
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
            .padding(DesignTokens.spacing.xs)
            
            // Index Badge
            VStack {
                Spacer()
                HStack {
                    Text("\(index + 1)")
                        .font(TypographyStyles.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignTokens.spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    
                    Spacer()
                }
                .padding(DesignTokens.spacing.xs)
            }
        }
    }
}

struct AddMoreImageButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DesignTokens.spacing.sm) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(ColorPalette.primary)
                
                Text("Add Photo")
                    .font(TypographyStyles.caption1)
                    .foregroundColor(ColorPalette.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                    .fill(ColorPalette.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                            .stroke(ColorPalette.primary, lineWidth: 1, lineCap: .round, dash: [5, 5])
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MediaGuidelinesView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing.sm) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(ColorPalette.primary)
                    
                    Text("Photo Guidelines")
                        .font(TypographyStyles.subheadline)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(ColorPalette.textSecondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.spacing.xs) {
                    GuidelineRow(icon: "checkmark.circle", text: "Use clear, well-lit photos", color: ColorPalette.success)
                    GuidelineRow(icon: "eye.slash", text: "Avoid identifying information (faces, names, locations)", color: ColorPalette.warning)
                    GuidelineRow(icon: "hand.raised", text: "No inappropriate or offensive content", color: ColorPalette.error)
                    GuidelineRow(icon: "person.2", text: "Respect others' privacy in shared photos", color: ColorPalette.primary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignTokens.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius.md)
                .fill(ColorPalette.primary.opacity(0.05))
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct GuidelineRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 16)
            
            Text(text)
                .font(TypographyStyles.caption1)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    MediaStepView(viewModel: CreatePostViewModel())
}