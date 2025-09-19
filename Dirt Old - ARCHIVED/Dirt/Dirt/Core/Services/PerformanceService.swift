import Foundation
import Combine

/// Performance monitoring and caching service
/// Provides performance metrics, caching, and optimization features
@MainActor
class PerformanceCacheService: ObservableObject {
    static let shared = PerformanceCacheService()
    
    @Published var isMonitoring = false
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    private var cache: [String: Any] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    private let maxCacheSize = 100
    
    private init() {}
    
    // MARK: - Performance Monitoring
    
    func startMonitoring() {
        isMonitoring = true
        performanceMetrics.startTime = Date()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        performanceMetrics.endTime = Date()
    }
    
    func recordMetric(_ name: String, value: Double) {
        performanceMetrics.customMetrics[name] = value
    }
    
    // MARK: - Caching
    
    func cache<T>(_ value: T, forKey key: String) {
        if cache.count >= maxCacheSize {
            clearOldestCacheEntry()
        }
        
        cache[key] = value
        cacheTimestamps[key] = Date()
    }
    
    func getCachedValue<T>(forKey key: String, type: T.Type) -> T? {
        guard let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheTimeout else {
            removeFromCache(key: key)
            return nil
        }
        
        return cache[key] as? T
    }
    
    func removeFromCache(key: String) {
        cache.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
    }
    
    func clearCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    private func clearOldestCacheEntry() {
        guard let oldestKey = cacheTimestamps.min(by: { $0.value < $1.value })?.key else {
            return
        }
        removeFromCache(key: oldestKey)
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    var startTime: Date?
    var endTime: Date?
    var customMetrics: [String: Double] = [:]
    
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
}

// MARK: - ManagedService Conformance

extension PerformanceCacheService: ManagedService {
    func initialize() async throws {
        startMonitoring()
    }
    
    func cleanup() async {
        stopMonitoring()
        clearCache()
    }
}