import Foundation
import UserNotifications
import SwiftUI

final class AlertsService: ObservableObject {
    static let shared = AlertsService()
    private init() {}

    @AppStorage("alertsEnabled") private var alertsEnabled: Bool = false

    enum AuthorizationStatus {
        case authorized, denied, notDetermined
    }

    func currentStatus() async -> AuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }

    @MainActor
    func requestAuthorization() async -> AuthorizationStatus {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            alertsEnabled = granted
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            @unknown default: return .denied
            }
        } catch {
            return .denied
        }
    }
}
