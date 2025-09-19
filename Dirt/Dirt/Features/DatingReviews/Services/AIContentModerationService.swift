import Foundation
import UIKit
import Vision
import NaturalLanguage

// MARK: - AI Content Moderation Service
class AIContentModerationService {
    static let shared = AIContentModerationService()
    
    private let textClassifier: NLModel?
    private let piiDetector = PIIDetectionService()
    private let imageProcessor = ImageModerationService()
    
    private init() {
        // Initialize text classification model (would be trained model in production)
        self.textClassifier = try? NLModel(mlModel: createMockTextClassificationModel())
    }
    
    // MARK: - Public API
    
    /// Moderates text content for policy violations
    func moderateText(_ text: String) async -> ModerationResult {
        let contentId = UUID()
        
        // Detect PII in text
        let piiDetections = await piiDetector.detectPIIInText(text)
        
        // Classify content for policy violations
        let (flags, confidence) = classifyTextContent(text)
        
        // Determine severity and status
        let severity = determineSeverity(for: flags)
        let status = determineStatus(confidence: confidence, severity: severity, piiCount: piiDetections.count)
        
        return ModerationResult(
            contentId: contentId,
            contentType: .post,
            status: status,
            flags: flags,
            confidence: confidence,
            severity: severity,
            reason: generateReason(for: flags),
            detectedPII: piiDetections,
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
    }
    
    /// Moderates image content and detects PII
    func moderateImage(_ image: UIImage) async -> ModerationResult {
        let contentId = UUID()
        
        // Detect PII in image
        let piiDetections = await piiDetector.detectPIIInImage(image)
        
        // Analyze image content
        let (flags, confidence) = await imageProcessor.analyzeImage(image)
        
        // Determine severity and status
        let severity = determineSeverity(for: flags)
        let status = determineStatus(confidence: confidence, severity: severity, piiCount: piiDetections.count)
        
        return ModerationResult(
            contentId: contentId,
            contentType: .image,
            status: status,
            flags: flags,
            confidence: confidence,
            severity: severity,
            reason: generateReason(for: flags),
            detectedPII: piiDetections,
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
    }
    
    /// Moderates complete review content (text + images)
    func moderateReview(text: String, images: [UIImage]) async -> ModerationResult {
        let contentId = UUID()
        
        // Moderate text content
        let textResult = await moderateText(text)
        
        // Moderate all images
        var allPIIDetections: [PIIDetection] = textResult.detectedPII
        var allFlags: Set<ModerationFlag> = Set(textResult.flags)
        var minConfidence = textResult.confidence
        
        for image in images {
            let imageResult = await moderateImage(image)
            allPIIDetections.append(contentsOf: imageResult.detectedPII)
            allFlags.formUnion(imageResult.flags)
            minConfidence = min(minConfidence, imageResult.confidence)
        }
        
        let finalFlags = Array(allFlags)
        let severity = determineSeverity(for: finalFlags)
        let status = determineStatus(confidence: minConfidence, severity: severity, piiCount: allPIIDetections.count)
        
        return ModerationResult(
            contentId: contentId,
            contentType: .review,
            status: status,
            flags: finalFlags,
            confidence: minConfidence,
            severity: severity,
            reason: generateReason(for: finalFlags),
            detectedPII: allPIIDetections,
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
    }
    
    /// Creates blurred version of image with PII obscured
    func blurPIIInImage(_ image: UIImage, piiDetections: [PIIDetection]) -> UIImage {
        return imageProcessor.blurPII(in: image, detections: piiDetections)
    }
    
    // MARK: - Private Methods
    
    private func classifyTextContent(_ text: String) -> ([ModerationFlag], Double) {
        var flags: [ModerationFlag] = []
        var confidence: Double = 1.0
        
        // Basic keyword-based detection (would use ML model in production)
        let lowercaseText = text.lowercased()
        
        // Check for inappropriate content
        let inappropriateKeywords = ["fuck", "shit", "damn", "bitch", "asshole"]
        if inappropriateKeywords.contains(where: { lowercaseText.contains($0) }) {
            flags.append(.inappropriateContent)
            confidence = min(confidence, 0.85)
        }
        
        // Check for harassment
        let harassmentKeywords = ["kill yourself", "die", "hate you", "worthless"]
        if harassmentKeywords.contains(where: { lowercaseText.contains($0) }) {
            flags.append(.harassment)
            confidence = min(confidence, 0.9)
        }
        
        // Check for spam patterns
        if text.count < 10 || text.filter({ $0.isUppercase }).count > text.count / 2 {
            flags.append(.spam)
            confidence = min(confidence, 0.7)
        }
        
        // Check for hate speech
        let hateSpeechKeywords = ["nazi", "terrorist", "subhuman"]
        if hateSpeechKeywords.contains(where: { lowercaseText.contains($0) }) {
            flags.append(.hateSpeech)
            confidence = min(confidence, 0.95)
        }
        
        return (flags, confidence)
    }
    
    private func determineSeverity(for flags: [ModerationFlag]) -> ModerationSeverity {
        let maxSeverity = flags.map { $0.severity }.max() ?? .low
        return maxSeverity
    }
    
    private func determineStatus(confidence: Double, severity: ModerationSeverity, piiCount: Int) -> ModerationStatus {
        // Auto-reject if PII detected
        if piiCount > 0 {
            return .flagged
        }
        
        // Auto-reject high confidence violations
        if confidence >= severity.autoActionThreshold {
            switch severity {
            case .critical, .high:
                return .rejected
            case .medium:
                return .flagged
            case .low:
                return .approved
            }
        }
        
        // Require human review for uncertain cases
        return .pending
    }
    
    private func generateReason(for flags: [ModerationFlag]) -> String? {
        guard !flags.isEmpty else { return nil }
        
        if flags.count == 1 {
            return flags.first?.description
        } else {
            return "Multiple policy violations detected: \(flags.map { $0.description }.joined(separator: ", "))"
        }
    }
    
    private func createMockTextClassificationModel() -> MLModel {
        // In production, this would load a trained Core ML model
        // For now, return a mock model
        fatalError("Mock model - implement with actual trained model")
    }
}

// MARK: - PII Detection Service
class PIIDetectionService {
    
    func detectPIIInText(_ text: String) async -> [PIIDetection] {
        var detections: [PIIDetection] = []
        
        // Phone number detection
        let phoneRegex = try! NSRegularExpression(pattern: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#)
        let phoneMatches = phoneRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in phoneMatches {
            if let range = Range(match.range, in: text) {
                let phoneNumber = String(text[range])
                detections.append(PIIDetection(
                    type: .phoneNumber,
                    location: CGRect.zero, // Text doesn't have visual location
                    confidence: 0.9,
                    text: phoneNumber
                ))
            }
        }
        
        // Email detection
        let emailRegex = try! NSRegularExpression(pattern: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#)
        let emailMatches = emailRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in emailMatches {
            if let range = Range(match.range, in: text) {
                let email = String(text[range])
                detections.append(PIIDetection(
                    type: .email,
                    location: CGRect.zero,
                    confidence: 0.95,
                    text: email
                ))
            }
        }
        
        // Social media handle detection
        let socialRegex = try! NSRegularExpression(pattern: #"@[A-Za-z0-9_]+"#)
        let socialMatches = socialRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in socialMatches {
            if let range = Range(match.range, in: text) {
                let handle = String(text[range])
                detections.append(PIIDetection(
                    type: .socialMedia,
                    location: CGRect.zero,
                    confidence: 0.8,
                    text: handle
                ))
            }
        }
        
        return detections
    }
    
    func detectPIIInImage(_ image: UIImage) async -> [PIIDetection] {
        return await withCheckedContinuation { continuation in
            var detections: [PIIDetection] = []
            
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: detections)
                return
            }
            
            // Use Vision framework for text recognition
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: detections)
                    return
                }
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    let text = topCandidate.string
                    let boundingBox = observation.boundingBox
                    
                    // Convert normalized coordinates to image coordinates
                    let imageRect = CGRect(
                        x: boundingBox.minX * image.size.width,
                        y: (1 - boundingBox.maxY) * image.size.height,
                        width: boundingBox.width * image.size.width,
                        height: boundingBox.height * image.size.height
                    )
                    
                    // Check if text contains PII patterns
                    if self.containsPhoneNumber(text) {
                        detections.append(PIIDetection(
                            type: .phoneNumber,
                            location: imageRect,
                            confidence: Double(topCandidate.confidence),
                            text: text
                        ))
                    }
                    
                    if self.containsEmail(text) {
                        detections.append(PIIDetection(
                            type: .email,
                            location: imageRect,
                            confidence: Double(topCandidate.confidence),
                            text: text
                        ))
                    }
                    
                    if self.containsSocialHandle(text) {
                        detections.append(PIIDetection(
                            type: .socialMedia,
                            location: imageRect,
                            confidence: Double(topCandidate.confidence),
                            text: text
                        ))
                    }
                }
                
                continuation.resume(returning: detections)
            }
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func containsPhoneNumber(_ text: String) -> Bool {
        let phoneRegex = try! NSRegularExpression(pattern: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#)
        return phoneRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
    
    private func containsEmail(_ text: String) -> Bool {
        let emailRegex = try! NSRegularExpression(pattern: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#)
        return emailRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
    
    private func containsSocialHandle(_ text: String) -> Bool {
        let socialRegex = try! NSRegularExpression(pattern: #"@[A-Za-z0-9_]+"#)
        return socialRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}

// MARK: - Image Moderation Service
class ImageModerationService {
    
    func analyzeImage(_ image: UIImage) async -> ([ModerationFlag], Double) {
        // In production, this would use a trained ML model for image classification
        // For now, implement basic checks
        
        var flags: [ModerationFlag] = []
        var confidence: Double = 0.8
        
        // Basic image analysis (would be replaced with actual ML model)
        let imageSize = image.size
        
        // Check for extremely small images (potential spam)
        if imageSize.width < 100 || imageSize.height < 100 {
            flags.append(.spam)
            confidence = 0.7
        }
        
        // In production, would analyze image content for:
        // - Inappropriate content
        // - Violence
        // - Sexual content
        // - etc.
        
        return (flags, confidence)
    }
    
    func blurPII(in image: UIImage, detections: [PIIDetection]) -> UIImage {
        guard !detections.isEmpty else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw original image
        image.draw(at: .zero)
        
        // Apply blur to PII regions
        let context = UIGraphicsGetCurrentContext()
        
        for detection in detections {
            let blurRect = detection.location
            
            // Create a blur effect (simplified - in production would use Core Image)
            context?.setFillColor(UIColor.black.withAlphaComponent(0.8).cgColor)
            context?.fill(blurRect)
            
            // Add "REDACTED" text
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: min(blurRect.height * 0.3, 16))
            ]
            
            let text = "REDACTED"
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: blurRect.midX - textSize.width / 2,
                y: blurRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}