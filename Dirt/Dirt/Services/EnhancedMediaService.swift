import Foundation
import UIKit
import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Media Types

enum MediaType {
    case image
    case video
    case audio
    case document
}

struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL?
    let thumbnail: UIImage?
    let type: MediaType
    let size: Int64
    let filename: String
    let mimeType: String
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Image Compression

class ImageCompressionService {
    static let shared = ImageCompressionService()
    
    private init() {}
    
    func compressImage(
        _ image: UIImage,
        maxSizeKB: Int = 500,
        maxDimension: CGFloat = 1024
    ) -> UIImage? {
        // Resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        
        // Compress to target size
        return compressToSize(resizedImage, maxSizeKB: maxSizeKB)
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Only resize if the image is larger than the max dimension
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func compressToSize(_ image: UIImage, maxSizeKB: Int) -> UIImage? {
        let maxSizeBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return image
        }
        
        // Binary search for optimal compression
        var minCompression: CGFloat = 0.0
        var maxCompression: CGFloat = 1.0
        
        while imageData.count > maxSizeBytes && compression > 0.1 {
            maxCompression = compression
            compression = (minCompression + maxCompression) / 2
            
            guard let newData = image.jpegData(compressionQuality: compression) else {
                break
            }
            
            imageData = newData
            
            if imageData.count < maxSizeBytes {
                minCompression = compression
            }
        }
        
        return UIImage(data: imageData)
    }
}

// MARK: - Enhanced Media Service

@MainActor
class EnhancedMediaService: ObservableObject {
    static let shared = EnhancedMediaService()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    
    private let compressionService = ImageCompressionService.shared
    private let supabaseManager = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Image Upload
    
    func uploadImage(
        _ image: UIImage,
        bucket: String = "media",
        folder: String = "images",
        compress: Bool = true
    ) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // Compress image if needed
            let finalImage = compress ? 
                compressionService.compressImage(image) ?? image : 
                image
            
            guard let imageData = finalImage.jpegData(compressionQuality: 0.8) else {
                throw MediaError.compressionFailed
            }
            
            // Generate unique filename
            let filename = "\(UUID().uuidString).jpg"
            let path = "\(folder)/\(filename)"
            
            // Upload to Supabase Storage
            let url = try await uploadData(
                data: imageData,
                bucket: bucket,
                path: path,
                contentType: "image/jpeg"
            )
            
            return url
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - File Upload
    
    func uploadFile(
        data: Data,
        filename: String,
        contentType: String,
        bucket: String = "media",
        folder: String = "files"
    ) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            let path = "\(folder)/\(filename)"
            let url = try await uploadData(
                data: data,
                bucket: bucket,
                path: path,
                contentType: contentType
            )
            
            return url
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Multiple File Upload
    
    func uploadMultipleFiles(
        _ items: [MediaItem],
        bucket: String = "media",
        folder: String = "mixed"
    ) async throws -> [String] {
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        var uploadedURLs: [String] = []
        
        for (index, item) in items.enumerated() {
            do {
                guard let url = item.url,
                      let data = try? Data(contentsOf: url) else {
                    throw MediaError.invalidFile
                }
                
                let path = "\(folder)/\(item.filename)"
                let uploadedURL = try await uploadData(
                    data: data,
                    bucket: bucket,
                    path: path,
                    contentType: item.mimeType
                )
                
                uploadedURLs.append(uploadedURL)
                uploadProgress = Double(index + 1) / Double(items.count)
            } catch {
                errorMessage = error.localizedDescription
                throw error
            }
        }
        
        return uploadedURLs
    }
    
    // MARK: - Private Upload Helper
    
    private func uploadData(
        data: Data,
        bucket: String,
        path: String,
        contentType: String
    ) async throws -> String {
        // Simulate upload progress
        for i in 1...10 {
            uploadProgress = Double(i) / 10.0
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // In a real implementation, you would use Supabase Storage:
        // let file = try await supabaseManager.client.storage
        //     .from(bucket)
        //     .upload(path: path, file: data, options: FileOptions(contentType: contentType))
        
        // For now, return a mock URL
        return "https://example.com/\(path)"
    }
    
    // MARK: - Image Processing
    
    func generateThumbnail(for image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail
    }
    
    func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Media Picker

struct MediaPickerView: View {
    @Binding var selectedItems: [MediaItem]
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isShowingCamera = false
    @State private var isShowingDocumentPicker = false
    
    let maxSelections: Int
    let allowedTypes: [MediaType]
    
    init(
        selectedItems: Binding<[MediaItem]>,
        maxSelections: Int = 5,
        allowedTypes: [MediaType] = [.image, .video, .document]
    ) {
        self._selectedItems = selectedItems
        self.maxSelections = maxSelections
        self.allowedTypes = allowedTypes
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Selected items preview
            if !selectedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedItems) { item in
                            MediaItemPreview(item: item) {
                                removeItem(item)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Selection buttons
            VStack(spacing: 12) {
                if allowedTypes.contains(.image) {
                    HStack(spacing: 12) {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: maxSelections,
                            matching: .images
                        ) {
                            Label("Photos", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { isShowingCamera = true }) {
                            Label("Camera", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                if allowedTypes.contains(.document) {
                    Button(action: { isShowingDocumentPicker = true }) {
                        Label("Documents", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .onChange(of: selectedPhotos) { photos in
            Task {
                await loadSelectedPhotos(photos)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraView { image in
                addImageItem(image)
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPickerView { urls in
                addDocumentItems(urls)
            }
        }
    }
    
    private func loadSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            if let data = try? await photo.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    addImageItem(image)
                }
            }
        }
    }
    
    private func addImageItem(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let item = MediaItem(
            url: nil,
            thumbnail: image,
            type: .image,
            size: Int64(data.count),
            filename: "image_\(UUID().uuidString).jpg",
            mimeType: "image/jpeg"
        )
        
        selectedItems.append(item)
    }
    
    private func addDocumentItems(_ urls: [URL]) {
        for url in urls {
            guard let data = try? Data(contentsOf: url) else { continue }
            
            let item = MediaItem(
                url: url,
                thumbnail: nil,
                type: .document,
                size: Int64(data.count),
                filename: url.lastPathComponent,
                mimeType: "application/octet-stream"
            )
            
            selectedItems.append(item)
        }
    }
    
    private func removeItem(_ item: MediaItem) {
        selectedItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Media Item Preview

struct MediaItemPreview: View {
    let item: MediaItem
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay {
                    if let thumbnail = item.thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        VStack {
                            Image(systemName: iconForType(item.type))
                                .font(.title2)
                                .foregroundColor(.secondary)
                            
                            Text(item.formattedSize)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
    
    private func iconForType(_ type: MediaType) -> String {
        switch type {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        case .document: return "doc"
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentsSelected: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onDocumentsSelected(urls)
        }
    }
}

// MARK: - Image Zoom View

struct ImageZoomView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 0.5), 5.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
        }
    }
}

// MARK: - Errors

enum MediaError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case invalidFile
    case fileTooLarge
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload file"
        case .invalidFile:
            return "Invalid file format"
        case .fileTooLarge:
            return "File is too large"
        }
    }
}
