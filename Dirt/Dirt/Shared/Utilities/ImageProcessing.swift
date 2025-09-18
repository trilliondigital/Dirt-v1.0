import UIKit
import CoreImage

// MARK: - ImageProcessing Utilities
struct ImageProcessing {
    static func blurForUpload(_ image: UIImage, radius: CGFloat = 12) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext(options: nil)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter?.outputImage,
              let cgImage = context.createCGImage(output, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }

    // Stub: remove EXIF metadata (no-op here). Replace with real EXIF stripping when integrating picker.
    static func stripEXIF(_ image: UIImage) -> UIImage { image }
}