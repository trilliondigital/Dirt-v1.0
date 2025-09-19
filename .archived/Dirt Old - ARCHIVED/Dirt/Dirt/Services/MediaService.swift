import Foundation
import UIKit
@preconcurrency import Vision
import CoreImage

// MARK: - Media Service
@MainActor
class MediaService: ObservableObject {
    static let shared = MediaService()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    private let supabaseManager = SupabaseManager.shared
    private let maxImageSize: CGFloat = 1024
    private let compressionQuality: CGFloat = 0.8
    
    private init() {}
    
    // MARK: - Image Upload
    
    func uploadImage(
        _ image: UIImage,
        bucket: String,
        folder: String,
        compress: Bool = true
    ) async throws -> String {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            // Step 1: Process image (30%)
            let processedImage = compress ? try await compressImage(image) : image
            processingProgress = 0.3
            
            // Step 2: Convert to data (20%)
            guard let imageData = processedImage.jpegData(compressionQuality: compressionQuality) else {
                throw MediaServiceError.imageProcessingFailed
            }
            processingProgress = 0.5
            
            // Step 3: Generate filename (10%)
            let filename = generateUniqueFilename(extension: "jpg")
            let fullPath = "\(folder)/\(filename)"
            processingProgress = 0.6
            
            // Step 4: Upload to storage (40%)
            let url = try await uploadToStorage(
                data: imageData,
                bucket: bucket,
                path: fullPath
            )
            processingProgress = 1.0
            
            return url
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Image Processing
    
    func processImageForPII(_ image: UIImage) async throws -> UIImage {
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            isProcessing = false
            processingProgress = 0.0
        }
        
        do {
            // Step 1: Detect text regions (50%)
            let textRegions = try await detectTextRegions(in: image)
            processingProgress = 0.5
            
            // Step 2: Analyze for PII (30%)
            let piiRegions = try await analyzePIIRegions(textRegions, in: image)
            processingProgress = 0.8
            
            // Step 3: Apply blur to PII regions (20%)
            let processedImage = try await blurPIIRegions(piiRegions, in: image)
            processingProgress = 1.0
            
            return processedImage
            
        } catch {
            // If PII processing fails, return original image
            // In production, you might want to reject the image instead
            return image
        }
    }
    
    // MARK: - Private Methods
    
    private func compressImage(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = image.size
                let maxDimension = max(size.width, size.height)
                
                if maxDimension <= self.maxImageSize {
                    continuation.resume(returning: image)
                    return
                }
                
                let scale = self.maxImageSize / maxDimension
                let newSize = CGSize(
                    width: size.width * scale,
                    height: size.height * scale
                )
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if let resizedImage = resizedImage {
                    continuation.resume(returning: resizedImage)
                } else {
                    continuation.resume(throwing: MediaServiceError.imageProcessingFailed)
                }
            }
        }
    }
    
    private func detectTextRegions(in image: UIImage) async throws -> [VNTextObservation] {
        guard let cgImage = image.cgImage else {
            throw MediaServiceError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectTextRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNTextObservation] ?? []
                continuation.resume(returning: observations)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func analyzePIIRegions(
        _ textObservations: [VNTextObservation],
        in image: UIImage
    ) async throws -> [CGRect] {
        // In a real implementation, this would use OCR to read text
        // and then analyze it for PII patterns
        
        // For now, we'll blur all detected text regions as a safety measure
        return textObservations.compactMap { observation in
            let boundingBox = observation.boundingBox
            
            // Convert normalized coordinates to image coordinates
            let imageSize = image.size
            return CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
        }
    }
    
    private func blurPIIRegions(_ regions: [CGRect], in image: UIImage) async throws -> UIImage {
        guard !regions.isEmpty else {
            return image
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: MediaServiceError.imageProcessingFailed)
                    return
                }
                
                let context = CIContext()
                let ciImage = CIImage(cgImage: cgImage)
                
                guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
                    continuation.resume(throwing: MediaServiceError.imageProcessingFailed)
                    return
                }
                
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(10.0, forKey: kCIInputRadiusKey)
                
                guard let blurredImage = blurFilter.outputImage else {
                    continuation.resume(throwing: MediaServiceError.imageProcessingFailed)
                    return
                }
                
                // Create a mask for the regions to blur
                var maskedImage = ciImage
                
                for region in regions {
                    // Create a mask for this region
                    let _ = CIVector(cgRect: region)
                    
                    guard let maskFilter = CIFilter(name: "CIConstantColorGenerator") else {
                        continue
                    }
                    
                    maskFilter.setValue(CIColor.white, forKey: kCIInputColorKey)
                    
                    guard let maskImage = maskFilter.outputImage?.cropped(to: region) else {
                        continue
                    }
                    
                    // Blend the blurred region with the original
                    guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
                        continue
                    }
                    
                    blendFilter.setValue(maskedImage, forKey: kCIInputBackgroundImageKey)
                    blendFilter.setValue(blurredImage, forKey: kCIInputImageKey)
                    blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
                    
                    if let blendedImage = blendFilter.outputImage {
                        maskedImage = blendedImage
                    }
                }
                
                guard let outputCGImage = context.createCGImage(maskedImage, from: maskedImage.extent) else {
                    continuation.resume(throwing: MediaServiceError.imageProcessingFailed)
                    return
                }
                
                let processedImage = UIImage(cgImage: outputCGImage)
                continuation.resume(returning: processedImage)
            }
        }
    }
    
    private func generateUniqueFilename(extension: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "\(timestamp)_\(uuid).\(`extension`)"
    }
    
    private func uploadToStorage(
        data: Data,
        bucket: String,
        path: String
    ) async throws -> String {
        // In a real implementation, this would upload to Supabase Storage
        // For now, we'll simulate the upload and return a mock URL
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return a mock URL
        return "https://example.com/storage/\(bucket)/\(path)"
    }
}

// MARK: - Media Service Errors

enum MediaServiceError: LocalizedError {
    case imageProcessingFailed
    case uploadFailed
    case invalidImageFormat
    case imageTooLarge
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .uploadFailed:
            return "Failed to upload image"
        case .invalidImageFormat:
            return "Invalid image format"
        case .imageTooLarge:
            return "Image is too large"
        case .networkError:
            return "Network error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageProcessingFailed:
            return "Please try with a different image"
        case .uploadFailed:
            return "Please check your internet connection and try again"
        case .invalidImageFormat:
            return "Please use a JPEG or PNG image"
        case .imageTooLarge:
            return "Please use a smaller image"
        case .networkError:
            return "Please check your internet connection"
        }
    }
}