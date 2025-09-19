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
        
        // Enhanced inappropriate content detection
        let inappropriateKeywords = [
            "fuck", "shit", "damn", "bitch", "asshole", "cunt", "whore", "slut",
            "retard", "faggot", "nigger", "chink", "spic", "kike"
        ]
        let inappropriateMatches = inappropriateKeywords.filter { lowercaseText.contains($0) }
        if !inappropriateMatches.isEmpty {
            flags.append(.inappropriateContent)
            confidence = min(confidence, 0.85 - Double(inappropriateMatches.count) * 0.05)
        }
        
        // Enhanced harassment detection
        let harassmentPatterns = [
            "kill yourself", "kys", "die", "hate you", "worthless", "pathetic",
            "loser", "nobody likes you", "go die", "end yourself", "suicide",
            "you should die", "waste of space", "piece of shit"
        ]
        let harassmentMatches = harassmentPatterns.filter { lowercaseText.contains($0) }
        if !harassmentMatches.isEmpty {
            flags.append(.harassment)
            confidence = min(confidence, 0.9 - Double(harassmentMatches.count) * 0.03)
        }
        
        // Enhanced spam detection
        let spamIndicators = [
            text.count < 10,
            text.filter({ $0.isUppercase }).count > text.count / 2,
            lowercaseText.contains("click here"),
            lowercaseText.contains("buy now"),
            lowercaseText.contains("limited time"),
            lowercaseText.contains("act now"),
            text.filter({ $0 == "!" }).count > 3,
            text.components(separatedBy: .whitespacesAndNewlines).count < 3
        ]
        let spamScore = spamIndicators.filter { $0 }.count
        if spamScore >= 2 {
            flags.append(.spam)
            confidence = min(confidence, 0.8 - Double(spamScore) * 0.05)
        }
        
        // Enhanced hate speech detection
        let hateSpeechKeywords = [
            "nazi", "hitler", "terrorist", "subhuman", "inferior race",
            "white power", "blood and soil", "jews will not replace us",
            "gas the", "holocaust hoax", "white genocide"
        ]
        let hateSpeechMatches = hateSpeechKeywords.filter { lowercaseText.contains($0) }
        if !hateSpeechMatches.isEmpty {
            flags.append(.hateSpeech)
            confidence = min(confidence, 0.95 - Double(hateSpeechMatches.count) * 0.02)
        }
        
        // Sexual content detection
        let sexualKeywords = [
            "porn", "xxx", "sex", "nude", "naked", "dick", "pussy", "cock",
            "masturbate", "orgasm", "cum", "blowjob", "anal", "vagina"
        ]
        let sexualMatches = sexualKeywords.filter { lowercaseText.contains($0) }
        if sexualMatches.count >= 2 {
            flags.append(.sexualContent)
            confidence = min(confidence, 0.8)
        }
        
        // Violence detection
        let violenceKeywords = [
            "murder", "kill", "stab", "shoot", "bomb", "explosion", "violence",
            "beat up", "assault", "attack", "hurt", "pain", "blood", "death"
        ]
        let violenceMatches = violenceKeywords.filter { lowercaseText.contains($0) }
        if violenceMatches.count >= 2 {
            flags.append(.violentContent)
            confidence = min(confidence, 0.85)
        }
        
        // Misinformation patterns (basic detection)
        let misinformationPatterns = [
            "fake news", "conspiracy", "government lies", "they don't want you to know",
            "big pharma", "wake up sheeple", "do your research", "mainstream media lies"
        ]
        let misinformationMatches = misinformationPatterns.filter { lowercaseText.contains($0) }
        if !misinformationMatches.isEmpty {
            flags.append(.misinformation)
            confidence = min(confidence, 0.7)
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
        
        // Enhanced phone number detection (multiple formats)
        let phonePatterns = [
            #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#, // 123-456-7890, 123.456.7890, 1234567890
            #"\b\(\d{3}\)\s?\d{3}[-.]?\d{4}\b"#, // (123) 456-7890, (123)456-7890
            #"\b\+1[-.]?\d{3}[-.]?\d{3}[-.]?\d{4}\b"#, // +1-123-456-7890
            #"\b1[-.]?\d{3}[-.]?\d{3}[-.]?\d{4}\b"# // 1-123-456-7890
        ]
        
        for pattern in phonePatterns {
            let phoneRegex = try! NSRegularExpression(pattern: pattern)
            let phoneMatches = phoneRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in phoneMatches {
                if let range = Range(match.range, in: text) {
                    let phoneNumber = String(text[range])
                    detections.append(PIIDetection(
                        type: .phoneNumber,
                        location: CGRect.zero,
                        confidence: 0.9,
                        text: phoneNumber
                    ))
                }
            }
        }
        
        // Enhanced email detection
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
        
        // Enhanced social media handle detection
        let socialPatterns = [
            #"@[A-Za-z0-9_]+"#, // @username
            #"\binstagram\.com/[A-Za-z0-9_.]+\b"#, // instagram.com/username
            #"\btwitter\.com/[A-Za-z0-9_]+\b"#, // twitter.com/username
            #"\bfacebook\.com/[A-Za-z0-9.]+\b"#, // facebook.com/username
            #"\btiktok\.com/@[A-Za-z0-9_.]+\b"#, // tiktok.com/@username
            #"\bsnapchat\.com/add/[A-Za-z0-9_.]+\b"# // snapchat.com/add/username
        ]
        
        for pattern in socialPatterns {
            let socialRegex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let socialMatches = socialRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in socialMatches {
                if let range = Range(match.range, in: text) {
                    let handle = String(text[range])
                    detections.append(PIIDetection(
                        type: .socialMedia,
                        location: CGRect.zero,
                        confidence: 0.85,
                        text: handle
                    ))
                }
            }
        }
        
        // Name detection (basic patterns)
        let namePatterns = [
            #"\bmy name is [A-Z][a-z]+ [A-Z][a-z]+\b"#,
            #"\bi'm [A-Z][a-z]+ [A-Z][a-z]+\b"#,
            #"\bcall me [A-Z][a-z]+\b"#
        ]
        
        for pattern in namePatterns {
            let nameRegex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let nameMatches = nameRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in nameMatches {
                if let range = Range(match.range, in: text) {
                    let nameText = String(text[range])
                    detections.append(PIIDetection(
                        type: .name,
                        location: CGRect.zero,
                        confidence: 0.7,
                        text: nameText
                    ))
                }
            }
        }
        
        // Address detection (basic patterns)
        let addressPatterns = [
            #"\b\d+\s+[A-Za-z\s]+\s+(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd)\b"#,
            #"\b\d{5}(-\d{4})?\b"# // ZIP codes
        ]
        
        for pattern in addressPatterns {
            let addressRegex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let addressMatches = addressRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in addressMatches {
                if let range = Range(match.range, in: text) {
                    let addressText = String(text[range])
                    detections.append(PIIDetection(
                        type: .address,
                        location: CGRect.zero,
                        confidence: 0.8,
                        text: addressText
                    ))
                }
            }
        }
        
        // Credit card detection
        let creditCardRegex = try! NSRegularExpression(pattern: #"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b"#)
        let creditCardMatches = creditCardRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in creditCardMatches {
            if let range = Range(match.range, in: text) {
                let cardNumber = String(text[range])
                detections.append(PIIDetection(
                    type: .creditCard,
                    location: CGRect.zero,
                    confidence: 0.9,
                    text: cardNumber
                ))
            }
        }
        
        // SSN detection
        let ssnRegex = try! NSRegularExpression(pattern: #"\b\d{3}[-]?\d{2}[-]?\d{4}\b"#)
        let ssnMatches = ssnRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in ssnMatches {
            if let range = Range(match.range, in: text) {
                let ssn = String(text[range])
                // Additional validation to avoid false positives
                if isValidSSNPattern(ssn) {
                    detections.append(PIIDetection(
                        type: .ssn,
                        location: CGRect.zero,
                        confidence: 0.95,
                        text: ssn
                    ))
                }
            }
        }
        
        return detections
    }
    
    private func isValidSSNPattern(_ ssn: String) -> Bool {
        let digits = ssn.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Basic SSN validation rules
        guard digits.count == 9 else { return false }
        
        let area = String(digits.prefix(3))
        let group = String(digits.dropFirst(3).prefix(2))
        let serial = String(digits.suffix(4))
        
        // Invalid area numbers
        if area == "000" || area == "666" || area.hasPrefix("9") {
            return false
        }
        
        // Invalid group numbers
        if group == "00" {
            return false
        }
        
        // Invalid serial numbers
        if serial == "0000" {
            return false
        }
        
        return true
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