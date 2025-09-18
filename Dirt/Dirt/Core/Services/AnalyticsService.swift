import Foundation
import SwiftUI
import Combine

// MARK: - Analytics Event Types

enum AnalyticsEvent {
    case screenView(String)
    case userAction(String, parameters: [String: Any] = [:])
    case error(AppError, context: String)
    case performance(String, duration: TimeInterval)
    case engagement(String, value: Double)
    case conversion(String, parameters: [String: Any] = [:])
    case custom(String, parameters: [String: Any] = [:])
    
    var name: String {
        switch self {
        case .screenView(let screen):
            return "screen_view_\(screen)"
        case .userAction(let action, _):
            return "user_action_\(action)"
        case .error(_, _):
            return "error_occurred"
        case .performance(let metric, _):
            return "performance_\(metric)"
        case .engagement(let type, _):
            return "engagement_\(type)"
        case .conversion(let event, _):
            return "conversion_\(event)"
        case .custom(let name, _):
            return name
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .screenView(let screen):
            return ["screen_name": screen]
        case .userAction(_, let params):
            return params
        case .error(let error, let context):
            return [
                "error_type": String(describing: error),
                "error_message": error.errorDescription ?? "Unknown",
                "context": context,
                "is_retryable": error.isRetryable
            ]
        case .performance(let metric, let duration):
            return ["metric": metric, "duration_ms": duration * 1000]
        case .engagement(let type, let value):
            return ["engagement_type": type, "value": value]
        case .conversion(_, let params):
            return params
        case .custom(_, let params):
            return params
        }
    }
}

// MARK: - User Properties

struct UserProperties {
    var userId: String?
    var userType: String?
    var subscriptionTier: String?
    var appVersion: String
    var deviceModel: String
    var osVersion: String
    var locale: String
    var timezone: String
    var firstLaunchDate: Date?
    var lastActiveDate: Date
    var sessionCount: Int
    var customProperties: [String: Any]
    
    init() {
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        self.deviceModel = UIDevice.current.model
        self.osVersion = UIDevice.current.systemVersion
        self.locale = Locale.current.identifier
        self.timezone = TimeZone.current.identifier
        self.lastActiveDate = Date()
        self.sessionCount = 0
        self.customProperties = [:]
    }
}

// MARK: - Enhanced Analytics Service

@MainActor
final class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isEnabled = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "analyticsEnabled")
        }
    }
    
    @Published var userProperties = UserProperties()
    @Published var sessionMetrics = SessionMetrics()
    
    private let queue = DispatchQueue(label: "analytics.queue", qos: .utility)
    private var eventBuffer: [AnalyticsEventRecord] = []
    private let maxBufferSize = 100
    private let batchUploadInterval: TimeInterval = 30
    private var uploadTimer: Timer?
    private var sessionStartTime = Date()
    
    struct AnalyticsEventRecord: Codable {
        let id: String
        let name: String
        let parameters: [String: String]
        let timestamp: Date
        let sessionId: String
        let userId: String?
    }
    
    struct SessionMetrics {
        var sessionId = UUID().uuidString
        var startTime = Date()
        var screenViews: [String] = []
        var userActions: [String] = []
        var errors: [String] = []
        var totalDuration: TimeInterval = 0
        
        mutating func reset() {
            sessionId = UUID().uuidString
            startTime = Date()
            screenViews.removeAll()
            userActions.removeAll()
            errors.removeAll()
            totalDuration = 0
        }
    }
    
    init() {
        isEnabled = UserDefaults.standard.object(forKey: "analyticsEnabled") as? Bool ?? true
        loadUserProperties()
        startSession()
        setupPeriodicUpload()
    }
    
    // MARK: - Event Tracking
    
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        let record = AnalyticsEventRecord(
            id: UUID().uuidString,
            name: event.name,
            parameters: convertParametersToStrings(event.parameters),
            timestamp: Date(),
            sessionId: sessionMetrics.sessionId,
            userId: userProperties.userId
        )
        
        queue.async { [weak self] in
            self?.addToBuffer(record)
        }
        
        updateSessionMetrics(for: event)
        
        #if DEBUG
        print("[Analytics] \(event.name): \(event.parameters)")
        #endif
    }
    
    func trackScreenView(_ screenName: String) {
        track(.screenView(screenName))
    }
    
    func trackUserAction(_ action: String, parameters: [String: Any] = [:]) {
        track(.userAction(action, parameters: parameters))
    }
    
    func trackError(_ error: AppError, context: String = "") {
        track(.error(error, context: context))
    }
    
    func trackPerformance(_ metric: String, duration: TimeInterval) {
        track(.performance(metric, duration: duration))
    }
    
    func trackEngagement(_ type: String, value: Double) {
        track(.engagement(type, value: value))
    }
    
    func trackConversion(_ event: String, parameters: [String: Any] = [:]) {
        track(.conversion(event, parameters: parameters))
    }
    
    // MARK: - User Properties Management
    
    func setUserId(_ userId: String) {
        userProperties.userId = userId
        saveUserProperties()
    }
    
    func setUserProperty(_ key: String, value: Any) {
        userProperties.customProperties[key] = value
        saveUserProperties()
    }
    
    func setUserProperties(_ properties: [String: Any]) {
        for (key, value) in properties {
            userProperties.customProperties[key] = value
        }
        saveUserProperties()
    }
    
    // MARK: - Session Management
    
    func startSession() {
        sessionStartTime = Date()
        sessionMetrics.reset()
        userProperties.sessionCount += 1
        userProperties.lastActiveDate = Date()
        
        if userProperties.firstLaunchDate == nil {
            userProperties.firstLaunchDate = Date()
        }
        
        saveUserProperties()
        track(.custom("session_start", parameters: ["session_id": sessionMetrics.sessionId]))
    }
    
    func endSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        sessionMetrics.totalDuration = duration
        
        track(.custom("session_end", parameters: [
            "session_id": sessionMetrics.sessionId,
            "duration_seconds": duration,
            "screen_views": sessionMetrics.screenViews.count,
            "user_actions": sessionMetrics.userActions.count,
            "errors": sessionMetrics.errors.count
        ]))
        
        uploadBufferedEvents()
    }
    
    // MARK: - Private Methods
    
    private func updateSessionMetrics(for event: AnalyticsEvent) {
        switch event {
        case .screenView(let screen):
            sessionMetrics.screenViews.append(screen)
        case .userAction(let action, _):
            sessionMetrics.userActions.append(action)
        case .error(_, _):
            sessionMetrics.errors.append(event.name)
        default:
            break
        }
    }
    
    private func addToBuffer(_ record: AnalyticsEventRecord) {
        eventBuffer.append(record)
        
        if eventBuffer.count >= maxBufferSize {
            uploadBufferedEvents()
        }
    }
    
    private func setupPeriodicUpload() {
        uploadTimer = Timer.scheduledTimer(withTimeInterval: batchUploadInterval, repeats: true) { [weak self] _ in
            self?.uploadBufferedEvents()
        }
    }
    
    private func uploadBufferedEvents() {
        guard !eventBuffer.isEmpty else { return }
        
        let eventsToUpload = eventBuffer
        eventBuffer.removeAll()
        
        Task {
            await uploadEvents(eventsToUpload)
        }
    }
    
    private func uploadEvents(_ events: [AnalyticsEventRecord]) async {
        // In a real implementation, you would send these to your analytics backend
        // For now, we'll simulate the upload
        
        do {
            let jsonData = try JSONEncoder().encode(events)
            
            // Simulate network request
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            #if DEBUG
            print("[Analytics] Uploaded \(events.count) events")
            #endif
            
        } catch {
            // Re-add events to buffer if upload fails
            queue.async { [weak self] in
                self?.eventBuffer.append(contentsOf: events)
            }
            
            #if DEBUG
            print("[Analytics] Upload failed: \(error)")
            #endif
        }
    }
    
    private func convertParametersToStrings(_ parameters: [String: Any]) -> [String: String] {
        var stringParams: [String: String] = [:]
        
        for (key, value) in parameters {
            if let stringValue = value as? String {
                stringParams[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                stringParams[key] = numberValue.stringValue
            } else if let boolValue = value as? Bool {
                stringParams[key] = boolValue ? "true" : "false"
            } else {
                stringParams[key] = String(describing: value)
            }
        }
        
        return stringParams
    }
    
    private func loadUserProperties() {
        if let data = UserDefaults.standard.data(forKey: "userProperties"),
           let properties = try? JSONDecoder().decode(UserProperties.self, from: data) {
            userProperties = properties
        }
    }
    
    private func saveUserProperties() {
        if let data = try? JSONEncoder().encode(userProperties) {
            UserDefaults.standard.set(data, forKey: "userProperties")
        }
    }
    
    // MARK: - Analytics Dashboard Data
    
    func getAnalyticsSummary() -> AnalyticsSummary {
        return AnalyticsSummary(
            totalSessions: userProperties.sessionCount,
            averageSessionDuration: sessionMetrics.totalDuration,
            totalScreenViews: sessionMetrics.screenViews.count,
            totalUserActions: sessionMetrics.userActions.count,
            totalErrors: sessionMetrics.errors.count,
            firstLaunchDate: userProperties.firstLaunchDate,
            lastActiveDate: userProperties.lastActiveDate
        )
    }
}

struct AnalyticsSummary {
    let totalSessions: Int
    let averageSessionDuration: TimeInterval
    let totalScreenViews: Int
    let totalUserActions: Int
    let totalErrors: Int
    let firstLaunchDate: Date?
    let lastActiveDate: Date
}

// MARK: - Analytics View Modifiers

struct AnalyticsScreenTracker: ViewModifier {
    let screenName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.trackScreenView(screenName)
            }
    }
}

struct AnalyticsActionTracker: ViewModifier {
    let action: String
    let parameters: [String: Any]
    let trigger: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                AnalyticsService.shared.trackUserAction(action, parameters: parameters)
            }
    }
}

extension View {
    func trackScreen(_ screenName: String) -> some View {
        modifier(AnalyticsScreenTracker(screenName: screenName))
    }
    
    func trackAction(_ action: String, parameters: [String: Any] = [:], trigger: Bool) -> some View {
        modifier(AnalyticsActionTracker(action: action, parameters: parameters, trigger: trigger))
    }
}

// MARK: - Analytics Settings View

struct AnalyticsSettingsView: View {
    @StateObject private var analytics = AnalyticsService.shared
    
    var body: some View {
        List {
            Section("Privacy") {
                Toggle("Enable Analytics", isOn: $analytics.isEnabled)
                
                Text("Analytics help us improve the app by understanding how you use it. No personal information is collected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if analytics.isEnabled {
                Section("Analytics Summary") {
                    let summary = analytics.getAnalyticsSummary()
                    
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(summary.totalSessions)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Screen Views")
                        Spacer()
                        Text("\(summary.totalScreenViews)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("User Actions")
                        Spacer()
                        Text("\(summary.totalUserActions)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let firstLaunch = summary.firstLaunchDate {
                        HStack {
                            Text("First Launch")
                            Spacer()
                            Text(firstLaunch, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Last Active")
                        Spacer()
                        Text(summary.lastActiveDate, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Analytics")
    }
}

// MARK: - Make UserProperties Codable

extension AnalyticsService.UserProperties: Codable {
    enum CodingKeys: String, CodingKey {
        case userId, userType, subscriptionTier, appVersion, deviceModel
        case osVersion, locale, timezone, firstLaunchDate, lastActiveDate
        case sessionCount, customProperties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        userType = try container.decodeIfPresent(String.self, forKey: .userType)
        subscriptionTier = try container.decodeIfPresent(String.self, forKey: .subscriptionTier)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        deviceModel = try container.decode(String.self, forKey: .deviceModel)
        osVersion = try container.decode(String.self, forKey: .osVersion)
        locale = try container.decode(String.self, forKey: .locale)
        timezone = try container.decode(String.self, forKey: .timezone)
        firstLaunchDate = try container.decodeIfPresent(Date.self, forKey: .firstLaunchDate)
        lastActiveDate = try container.decode(Date.self, forKey: .lastActiveDate)
        sessionCount = try container.decode(Int.self, forKey: .sessionCount)
        
        // Decode custom properties as strings for simplicity
        if let customPropsData = try container.decodeIfPresent([String: String].self, forKey: .customProperties) {
            customProperties = customPropsData
        } else {
            customProperties = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userType, forKey: .userType)
        try container.encodeIfPresent(subscriptionTier, forKey: .subscriptionTier)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(deviceModel, forKey: .deviceModel)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(locale, forKey: .locale)
        try container.encode(timezone, forKey: .timezone)
        try container.encodeIfPresent(firstLaunchDate, forKey: .firstLaunchDate)
        try container.encode(lastActiveDate, forKey: .lastActiveDate)
        try container.encode(sessionCount, forKey: .sessionCount)
        
        // Encode custom properties as strings
        let stringProps = customProperties.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else {
                return String(describing: value)
            }
        }
        try container.encode(stringProps, forKey: .customProperties)
    }
}