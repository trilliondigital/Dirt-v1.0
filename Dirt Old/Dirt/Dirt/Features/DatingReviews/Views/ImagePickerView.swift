import SwiftUI
import PhotosUI

// MARK: - Image Picker View
struct ImagePickerView: View {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading = false
    
    private let maxImages = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Profile Screenshots")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose up to \(maxImages) screenshots of the dating profile. Personal information will be automatically blurred.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Photo Picker
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: maxImages - selectedImages.count,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Select Photos")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Tap to choose from your photo library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(selectedImages.count >= maxImages || isLoading)
                
                // Selected Images Preview
                if !selectedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selected Images")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(selectedImages.count)/\(maxImages)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ImagePreviewCard(
                                        image: image,
                                        onRemove: {
                                            selectedImages.remove(at: index)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Loading State
                if isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Processing images...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guidelines:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        GuidelineRow(text: "Only include screenshots from dating apps")
                        GuidelineRow(text: "Personal information will be automatically blurred")
                        GuidelineRow(text: "Ensure images are clear and readable")
                        GuidelineRow(text: "Respect privacy - no identifying information")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Add Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onChange(of: selectedPhotos) { photos in
            Task {
                await loadSelectedPhotos(photos)
            }
        }
    }
    
    // MARK: - Photo Loading
    
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        isLoading = true
        
        for photo in photos {
            if selectedImages.count >= maxImages {
                break
            }
            
            if let data = try? await photo.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImages.append(image)
                }
            }
        }
        
        isLoading = false
        selectedPhotos.removeAll()
    }
}

// MARK: - Image Preview Card

struct ImagePreviewCard: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .font(.title3)
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Guideline Row

struct GuidelineRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .offset(y: 2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ImagePickerView(selectedImages: .constant([]))
    }
}