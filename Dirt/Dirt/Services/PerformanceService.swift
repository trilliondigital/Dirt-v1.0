import Foundation
import SwiftUI
import Combine

// MARK: - Cache Types

protocol Cacheable {
    var cacheKey: String { get }
    var expirationDate: Date { get }
}

struct CacheEntry<T: Codable> {
    let data: T
    let timestamp: Date
    let expirationDate: Date
    
    var isExpired: Bool {
        Date() > expirationDate
    }
}

// MARK: - Performance Cache Service

@MainActor
class PerformanceCacheService: ObservableObject {
    static let shared = PerformanceCacheService()
    
    private var memoryCache: [String: Any] = [:]
    private var diskCacheURL: URL
    private let maxMemoryCacheSize = 50 // MB
    private let defaultCacheExpiration: TimeInterval = 3600 // 1 hour
    
    @Published var cacheStats = CacheStats()
    
    struct CacheStats {
        var memoryHits = 0
        var diskHits = 0
        var misses = 0
        var evictions = 0
        
        var hitRate: Double {
            let total = memoryHits + diskHits + misses
            return total > 0 ? Double(memoryHits + diskHits) / Double(total) : 0
        }
    }
    
    private init() {
        diskCacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DirtCache")
        
        createCacheDirectory()
        startPerformanceMonitoring()
    }
    
    private func createCacheDirectory() {
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache Operations
    
    func store<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval? = nil) {
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultCacheExpiration)
        let entry = CacheEntry(data: data, timestamp: Date(), expirationDate: expirationDate)
        
        // Store in memory cache
        memoryCache[key] = entry
        
        // Store in disk cache
        Task {
            await storeToDisk(entry, forKey: key)
        }
        
        // Clean up if needed
        cleanupMemoryCacheIfNeeded()
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        // Check memory cache first
        if let entry = memoryCache[key] as? CacheEntry<T> {
            if !entry.isExpired {
                cacheStats.memoryHits += 1
                return entry.data
            } else {
                memoryCache.removeValue(forKey: key)
            }
        }
        
        // Check disk cache
        if let entry = retrieveFromDisk(type, forKey: key) {
            if !entry.isExpired {
                // Move back to memory cache
                memoryCache[key] = entry
                cacheStats.diskHits += 1
                return entry.data
            } else {
                // Remove expired entry
                removeFromDisk(key: key)
            }
        }
        
        cacheStats.misses += 1
        return nil
    }
    
    func remove(forKey key: String) {
        memoryCache.removeValue(forKey: key)
        removeFromDisk(key: key)
    }
    
    func clearCache() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: diskCacheURL)
        createCacheDirectory()
        cacheStats = CacheStats()
    }
    
    // MARK: - Disk Cache Operations
    
    private func storeToDisk<T: Codable>(_ entry: CacheEntry<T>, forKey key: String) async {
        let fileURL = diskCacheURL.appendingPathComponent(key.sha256)
        
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("Failed to store to disk cache: \(error)")
        }
    }
    
    private func retrieveFromDisk<T: Codable>(_ type: T.Type, forKey key: String) -> CacheEntry<T>? {
        let fileURL = diskCacheURL.appendingPathComponent(key.sha256)
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CacheEntry<T>.self, from: data)
        } catch {
            return nil
        }
    }
    
    private func removeFromDisk(key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key.sha256)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - Memory Management
    
    private func cleanupMemoryCacheIfNeeded() {
        let memoryUsage = estimateMemoryUsage()
        if memoryUsage > maxMemoryCacheSize * 1024 * 1024 {
            // Remove oldest entries
            let sortedKeys = memoryCache.keys.sorted { key1, key2 in
                let entry1 = memoryCache[key1] as? CacheEntry<Any>
                let entry2 = memoryCache[key2] as? CacheEntry<Any>
                return (entry1?.timestamp ?? Date()) < (entry2?.timestamp ?? Date())
            }
            
            let keysToRemove = sortedKeys.prefix(sortedKeys.count / 2)
            keysToRemove.forEach { memoryCache.removeValue(forKey: $0) }
            cacheStats.evictions += keysToRemove.count
        }
    }
    
    private func estimateMemoryUsage() -> Int {
        // Rough estimation of memory usage
        return memoryCache.count * 1024 // 1KB per entry estimate
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                self.cleanupExpiredEntries()
            }
        }
    }
    
    private func cleanupExpiredEntries() {
        // Clean memory cache
        let expiredKeys = memoryCache.compactMap { key, value -> String? in
            if let entry = value as? CacheEntry<Any>, entry.isExpired {
                return key
            }
            return nil
        }
        
        expiredKeys.forEach { memoryCache.removeValue(forKey: $0) }
        
        // Clean disk cache
        Task {
            await cleanupDiskCache()
        }
    }
    
    private func cleanupDiskCache() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            
            for file in files {
                let data = try? Data(contentsOf: file)
                if let data = data,
                   let entry = try? JSONDecoder().decode(CacheEntry<Data>.self, from: data),
                   entry.isExpired {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup disk cache: \(error)")
        }
    }
}

// MARK: - Image Cache Service

@MainActor
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    private let cache = PerformanceCacheService.shared
    private let session = URLSession.shared
    
    @Published var loadingImages: Set<String> = []
    
    private init() {}
    
    func loadImage(from url: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = cache.retrieve(Data.self, forKey: "image_\(url)") {
            return UIImage(data: cachedImage)
        }
        
        // Prevent duplicate downloads
        if loadingImages.contains(url) {
            // Wait for existing download
            while loadingImages.contains(url) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            // Check cache again
            if let cachedImage = cache.retrieve(Data.self, forKey: "image_\(url)") {
                return UIImage(data: cachedImage)
            }
        }
        
        loadingImages.insert(url)
        defer { loadingImages.remove(url) }
        
        do {
            guard let imageURL = URL(string: url) else { return nil }
            let (data, _) = try await session.data(from: imageURL)
            
            // Cache the image data
            cache.store(data, forKey: "image_\(url)", expiration: 86400) // 24 hours
            
            return UIImage(data: data)
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
    
    func preloadImages(_ urls: [String]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await self.loadImage(from: url)
                    }
                }
            }
        }
    }
}

// MARK: - Performance Monitor

@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var metrics = PerformanceMetrics()
    
    struct PerformanceMetrics {
        var memoryUsage: Double = 0
        var cpuUsage: Double = 0
        var networkRequests: Int = 0
        var averageResponseTime: TimeInterval = 0
        var frameRate: Double = 60
        var batteryLevel: Float = 1.0
        var thermalState: ProcessInfo.ThermalState = .nominal
    }
    
    private var timer: Timer?
    private var responseTimeHistory: [TimeInterval] = []
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateMetrics()
            }
        }
    }
    
    private func updateMetrics() {
        metrics.memoryUsage = getMemoryUsage()
        metrics.cpuUsage = getCPUUsage()
        metrics.batteryLevel = UIDevice.current.batteryLevel
        metrics.thermalState = ProcessInfo.processInfo.thermalState
        
        // Calculate average response time
        if !responseTimeHistory.isEmpty {
            metrics.averageResponseTime = responseTimeHistory.reduce(0, +) / Double(responseTimeHistory.count)
        }
    }
    
    func recordNetworkRequest(responseTime: TimeInterval) {
        metrics.networkRequests += 1
        responseTimeHistory.append(responseTime)
        
        // Keep only last 100 entries
        if responseTimeHistory.count > 100 {
            responseTimeHistory.removeFirst()
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // MB
        }
        
        return 0
    }
    
    private func getCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // Simplified CPU usage
        }
        
        return 0
    }
}

// MARK: - Lazy Loading Components

struct LazyImage: View {
    let url: String
    let placeholder: Image?
    
    @StateObject private var imageCache = ImageCacheService.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: String, placeholder: Image? = nil) {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                placeholder ?? Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard image == nil && !isLoading else { return }
        
        isLoading = true
        
        Task {
            let loadedImage = await imageCache.loadImage(from: url)
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Performance Settings View

struct PerformanceSettingsView: View {
    @StateObject private var cacheService = PerformanceCacheService.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        List {
            Section("Cache Statistics") {
                HStack {
                    Text("Hit Rate")
                    Spacer()
                    Text("\(Int(cacheService.cacheStats.hitRate * 100))%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Memory Hits")
                    Spacer()
                    Text("\(cacheService.cacheStats.memoryHits)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Disk Hits")
                    Spacer()
                    Text("\(cacheService.cacheStats.diskHits)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Misses")
                    Spacer()
                    Text("\(cacheService.cacheStats.misses)")
                        .foregroundColor(.secondary)
                }
                
                Button("Clear Cache") {
                    cacheService.clearCache()
                }
                .foregroundColor(.red)
            }
            
            Section("Performance Metrics") {
                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text("\(Int(performanceMonitor.metrics.memoryUsage)) MB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Network Requests")
                    Spacer()
                    Text("\(performanceMonitor.metrics.networkRequests)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Avg Response Time")
                    Spacer()
                    Text("\(Int(performanceMonitor.metrics.averageResponseTime * 1000)) ms")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Battery Level")
                    Spacer()
                    Text("\(Int(performanceMonitor.metrics.batteryLevel * 100))%")
                        .foregroundColor(batteryColor)
                }
                
                HStack {
                    Text("Thermal State")
                    Spacer()
                    Text(thermalStateText)
                        .foregroundColor(thermalStateColor)
                }
            }
        }
        .navigationTitle("Performance")
    }
    
    private var batteryColor: Color {
        let level = performanceMonitor.metrics.batteryLevel
        if level > 0.5 { return .green }
        if level > 0.2 { return .orange }
        return .red
    }
    
    private var thermalStateText: String {
        switch performanceMonitor.metrics.thermalState {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private var thermalStateColor: Color {
        switch performanceMonitor.metrics.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}

// MARK: - String Extension for SHA256

extension String {
    var sha256: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
