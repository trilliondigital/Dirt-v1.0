import Foundation
import Network
import Combine

/// Network connectivity monitoring service
/// Provides real-time network status and connectivity information
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    // MARK: - Connection Quality
    
    var connectionQuality: ConnectionQuality {
        if !isConnected {
            return .none
        }
        
        if isConstrained {
            return .poor
        }
        
        switch connectionType {
        case .wifi, .ethernet:
            return .excellent
        case .cellular:
            return isExpensive ? .fair : .good
        case .unknown:
            return .poor
        }
    }
    
    // MARK: - Utility Methods
    
    func waitForConnection() async {
        while !isConnected {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
    
    func isConnectionSuitableForLargeDownloads() -> Bool {
        return isConnected && !isExpensive && !isConstrained
    }
    
    func isConnectionSuitableForBackgroundTasks() -> Bool {
        return isConnected && connectionQuality != .none
    }
}

// MARK: - Connection Types

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
}

enum ConnectionQuality {
    case none
    case poor
    case fair
    case good
    case excellent
    
    var displayName: String {
        switch self {
        case .none: return "No Connection"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
}

// MARK: - ManagedService Conformance

extension NetworkMonitor: ManagedService {
    func initialize() async throws {
        // Already initialized in init
    }
    
    func cleanup() async {
        monitor.cancel()
    }
}