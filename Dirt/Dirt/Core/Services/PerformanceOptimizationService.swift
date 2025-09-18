import Foundation
import SwiftUI
import Combine

/// Performance optimization service for Material Glass components
/// Provides frame rate monitoring, rendering optimization, and performance analytics
@MainActor
class PerformanceOptimizationService: ObservableObject {
    static let shared = PerformanceOptimizationService()
    
    @Published var currentFrameRate: Double = 60.0
    @Published var isOptimizationEnabled = true
    @Published var performanceMode: PerformanceMode = .balanced
    
    private var frameRateMonitor: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var frameRateHistory: [Double] = []
    private let maxHistorySize = 60 // Keep 1 second of history at 60fps
    
    // Performance thresholds
    private let targetFrameRate: Double = 60.0
    private let lowPerformanceThreshold: Double = 45.0
    private let criticalPerformanceThreshold: Double = 30.0
    
    enum PerformanceMode {
        case highPerformance  // Prioritize frame rate over visual effects
        case balanced         // Balance between performance and visual quality
        case highQuality      // Prioritize visual quality over frame rate
        
        var materialComplexity: MaterialComplexity {
            switch self {
            case .highPerformance: return .minimal
            case .balanced: return .standard
            case .highQuality: return .enhanced
            }
        }
        
        var animationDuration: TimeInterval {
            switch self {
            case .highPerformance: return 0.1
            case .balanced: return 0.2
            case .highQuality: return 0.3
            }
        }
        
        var shadowEnabled: Bool {
            switch self {
            case .highPerformance: return false
            case .balanced: return true
            case .highQuality: return true
            }
        }
    }
    
    enum MaterialComplexity {
        case minimal    // Ultra-thin materials only
        case standard   // Thin and regular materials
        case enhanced   // All material types with full effects
        
        var allowedMaterials: [Material] {
            switch self {
            case .minimal: return [.ultraThinMaterial]
            case .standard: return [.ultraThinMaterial, .thinMaterial, .regularMaterial]
            case .enhanced: return [.ultraThinMaterial, .thinMaterial, .regularMaterial, .thickMaterial, .ultraThickMaterial]
            }
        }
    }
    
    private init() {
        setupFrameRateMonitoring()
    }
    
    // MARK: - Frame Rate Monitoring
    
    private func setupFrameRateMonitoring() {
        frameRateMonitor = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        frameRateMonitor?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrameRate(displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        
        if lastTimestamp == 0 {
            lastTimestamp = currentTime
            return
        }
        
        frameCount += 1
        let deltaTime = currentTime - lastTimestamp
        
        // Update frame rate every second
        if deltaTime >= 1.0 {
            let fps = Double(frameCount) / deltaTime
            
            DispatchQueue.main.async {
                self.currentFrameRate = fps
                self.frameRateHistory.append(fps)
                
                // Keep history size manageable
                if self.frameRateHistory.count > self.maxHistorySize {
                    self.frameRateHistory.removeFirst()
                }
                
                // Auto-adjust performance mode based on frame rate
                self.adjustPerformanceModeIfNeeded(fps: fps)
            }
            
            frameCount = 0
            lastTimestamp = currentTime
        }
    }
    
    private func adjustPerformanceModeIfNeeded(fps: Double) {
        guard isOptimizationEnabled else { return }
        
        if fps < criticalPerformanceThreshold && performanceMode != .highPerformance {
            performanceMode = .highPerformance
            NotificationCenter.default.post(name: .performanceModeChanged, object: performanceMode)
        } else if fps < lowPerformanceThreshold && performanceMode == .highQuality {
            performanceMode = .balanced
            NotificationCenter.default.post(name: .performanceModeChanged, object: performanceMode)
        } else if fps > targetFrameRate - 5 && performanceMode == .highPerformance {
            // Only upgrade performance mode if we've had good performance for a while
            let recentFrameRates = Array(frameRateHistory.suffix(30)) // Last 0.5 seconds
            if recentFrameRates.allSatisfy({ $0 > targetFrameRate - 5 }) {
                performanceMode = .balanced
                NotificationCenter.default.post(name: .performanceModeChanged, object: performanceMode)
            }
        }
    }
    
    // MARK: - Performance Optimization
    
    /// Get optimized material for current performance mode
    func optimizedMaterial(for requestedMaterial: Material) -> Material {
        let allowedMaterials = performanceMode.materialComplexity.allowedMaterials
        
        // If requested material is allowed, use it
        if allowedMaterials.contains(requestedMaterial) {
            return requestedMaterial
        }
        
        // Otherwise, return the closest allowed material
        switch requestedMaterial {
        case .ultraThickMaterial, .thickMaterial:
            return allowedMaterials.contains(.regularMaterial) ? .regularMaterial : .thinMaterial
        case .regularMaterial:
            return allowedMaterials.contains(.thinMaterial) ? .thinMaterial : .ultraThinMaterial
        case .thinMaterial:
            return .ultraThinMaterial
        default:
            return .ultraThinMaterial
        }
    }
    
    /// Get optimized animation duration for current performance mode
    func optimizedAnimationDuration(for requestedDuration: TimeInterval) -> TimeInterval {
        let modeDuration = performanceMode.animationDuration
        return min(requestedDuration, modeDuration)
    }
    
    /// Check if shadows should be enabled for current performance mode
    var shouldEnableShadows: Bool {
        return performanceMode.shadowEnabled
    }
    
    /// Get optimized corner radius (simpler shapes for better performance)
    func optimizedCornerRadius(for requestedRadius: CGFloat) -> CGFloat {
        switch performanceMode {
        case .highPerformance:
            return min(requestedRadius, 8.0) // Limit to simple radii
        case .balanced:
            return requestedRadius
        case .highQuality:
            return requestedRadius
        }
    }
    
    // MARK: - Performance Analytics
    
    var averageFrameRate: Double {
        guard !frameRateHistory.isEmpty else { return 60.0 }
        return frameRateHistory.reduce(0, +) / Double(frameRateHistory.count)
    }
    
    var frameRateStability: Double {
        guard frameRateHistory.count > 1 else { return 1.0 }
        
        let mean = averageFrameRate
        let variance = frameRateHistory.map { pow($0 - mean, 2) }.reduce(0, +) / Double(frameRateHistory.count)
        let standardDeviation = sqrt(variance)
        
        // Return stability as a value between 0 and 1 (1 = perfectly stable)
        return max(0, 1 - (standardDeviation / mean))
    }
    
    var performanceGrade: PerformanceGrade {
        let avgFps = averageFrameRate
        let stability = frameRateStability
        
        if avgFps >= 55 && stability >= 0.9 {
            return .excellent
        } else if avgFps >= 45 && stability >= 0.8 {
            return .good
        } else if avgFps >= 30 && stability >= 0.7 {
            return .fair
        } else {
            return .poor
        }
    }
    
    enum PerformanceGrade: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        frameRateMonitor?.invalidate()
    }
    
    func stopMonitoring() {
        frameRateMonitor?.invalidate()
        frameRateMonitor = nil
    }
    
    func startMonitoring() {
        guard frameRateMonitor == nil else { return }
        setupFrameRateMonitoring()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let performanceModeChanged = Notification.Name("performanceModeChanged")
}

// MARK: - ManagedService Conformance

extension PerformanceOptimizationService: ManagedService {
    func initialize() async throws {
        startMonitoring()
    }
    
    func cleanup() async {
        stopMonitoring()
    }
}

// MARK: - Performance-Optimized View Modifiers

/// View modifier that applies performance optimizations to Material Glass components
struct PerformanceOptimizedGlassModifier: ViewModifier {
    @StateObject private var performanceService = PerformanceOptimizationService.shared
    
    let requestedMaterial: Material
    let requestedCornerRadius: CGFloat
    let requestedShadowRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                performanceService.optimizedMaterial(for: requestedMaterial),
                in: RoundedRectangle(cornerRadius: performanceService.optimizedCornerRadius(for: requestedCornerRadius))
            )
            .shadow(
                color: performanceService.shouldEnableShadows ? .black.opacity(0.1) : .clear,
                radius: performanceService.shouldEnableShadows ? requestedShadowRadius : 0
            )
    }
}

extension View {
    /// Apply performance-optimized glass styling
    func performanceOptimizedGlass(
        material: Material = .thinMaterial,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 8
    ) -> some View {
        modifier(PerformanceOptimizedGlassModifier(
            requestedMaterial: material,
            requestedCornerRadius: cornerRadius,
            requestedShadowRadius: shadowRadius
        ))
    }
}