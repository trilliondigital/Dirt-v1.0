import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var pushNotificationService = PushNotificationService.shared
    
    @State private var settings: NotificationSettings
    @State private var showingPermissionAlert = false
    @State private var showingQuietHoursSheet = false
    
    init() {
        _settings = State(initialValue: NotificationManager.shared.getNotificationSettings())
    }
    
    var body: some View {
        List {
            // System Permissions Section
            systemPermissionsSection
            
            // Notification Types Section
            notificationTypesSection
            
            // Preferences Section
            preferencesSection
            
            // Quiet Hours Section
            quietHoursSection
            
            // Actions Section
            actionsSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Notification Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings) { newSettings in
            notificationManager.updateNotificationSettings(newSettings)
        }
        .onAppear {
            settings = notificationManager.getNotificationSettings()
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openSystemSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To receive notifications, please enable them in Settings.")
        }
        .sheet(isPresented: $showingQuietHoursSheet) {
            QuietHoursSettingsView(settings: $settings)
        }
    }
    
    // MARK: - System Permissions Section
    
    private var systemPermissionsSection: some View {
        Section {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(pushNotificationService.authorizationStatus == .authorized ? .green : .red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push Notifications")
                        .font(.body)
                    
                    Text(authorizationStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if pushNotificationService.authorizationStatus != .authorized {
                    Button("Enable") {
                        Task {
                            let granted = await notificationManager.requestNotificationPermission()
                            if !granted {
                                showingPermissionAlert = true
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("System Permissions")
        } footer: {
            Text("Allow the app to send you push notifications for important updates and interactions.")
        }
    }
    
    // MARK: - Notification Types Section
    
    private var notificationTypesSection: some View {
        Section {
            NotificationToggleRow(
                title: "Replies",
                subtitle: "When someone replies to your content",
                icon: "bubble.left",
                isEnabled: $settings.repliesEnabled
            )
            
            NotificationToggleRow(
                title: "Upvotes",
                subtitle: "When your content receives upvotes",
                icon: "arrow.up.circle",
                isEnabled: $settings.upvotesEnabled
            )
            
            NotificationToggleRow(
                title: "Mentions",
                subtitle: "When someone mentions you",
                icon: "at",
                isEnabled: $settings.mentionsEnabled
            )
            
            NotificationToggleRow(
                title: "Milestones",
                subtitle: "When you reach reputation milestones",
                icon: "star.circle",
                isEnabled: $settings.milestonesEnabled
            )
            
            NotificationToggleRow(
                title: "Achievements",
                subtitle: "When you unlock new achievements",
                icon: "trophy",
                isEnabled: $settings.achievementsEnabled
            )
            
            NotificationToggleRow(
                title: "Announcements",
                subtitle: "Community updates and news",
                icon: "megaphone",
                isEnabled: $settings.announcementsEnabled
            )
            
            NotificationToggleRow(
                title: "Recommendations",
                subtitle: "Personalized content suggestions",
                icon: "lightbulb",
                isEnabled: $settings.recommendationsEnabled
            )
            
            NotificationToggleRow(
                title: "Moderation",
                subtitle: "Content moderation updates",
                icon: "shield",
                isEnabled: $settings.moderationEnabled
            )
            
            NotificationToggleRow(
                title: "Feature Unlocks",
                subtitle: "When new features become available",
                icon: "lock.open",
                isEnabled: $settings.featureUnlocksEnabled
            )
        } header: {
            Text("Notification Types")
        } footer: {
            Text("Choose which types of notifications you want to receive.")
        }
        .disabled(!settings.pushNotificationsEnabled)
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            HStack {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upvote Threshold")
                    Text("Notify after receiving this many upvotes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("Upvote Threshold", selection: $settings.upvoteThreshold) {
                    Text("1").tag(1)
                    Text("5").tag(5)
                    Text("10").tag(10)
                    Text("25").tag(25)
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.vertical, 4)
        } header: {
            Text("Preferences")
        } footer: {
            Text("Customize when and how you receive notifications.")
        }
        .disabled(!settings.pushNotificationsEnabled)
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        Section {
            HStack {
                Image(systemName: "moon")
                    .foregroundColor(settings.quietHoursEnabled ? .purple : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiet Hours")
                    if settings.quietHoursEnabled {
                        Text(quietHoursText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.quietHoursEnabled)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                if settings.quietHoursEnabled {
                    showingQuietHoursSheet = true
                }
            }
            
            if settings.quietHoursEnabled {
                Button("Configure Times") {
                    showingQuietHoursSheet = true
                }
                .foregroundColor(.blue)
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("Pause non-urgent notifications during specified hours. Urgent notifications will still be delivered.")
        }
        .disabled(!settings.pushNotificationsEnabled)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            Button("Test Notification") {
                Task {
                    await sendTestNotification()
                }
            }
            .foregroundColor(.blue)
            .disabled(!settings.pushNotificationsEnabled)
            
            Button("Reset to Defaults") {
                settings = NotificationSettings()
            }
            .foregroundColor(.orange)
        } header: {
            Text("Actions")
        }
    }
    
    // MARK: - Computed Properties
    
    private var authorizationStatusText: String {
        switch pushNotificationService.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled in Settings"
        case .notDetermined:
            return "Not Requested"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var quietHoursText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startTime = formatter.string(from: settings.quietHoursStart)
        let endTime = formatter.string(from: settings.quietHoursEnd)
        
        return "\(startTime) - \(endTime)"
    }
    
    // MARK: - Actions
    
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func sendTestNotification() async {
        let currentUserId = UUID() // This would come from your auth service
        
        await pushNotificationService.notifyAnnouncement(
            userId: currentUserId,
            title: "Test Notification",
            message: "This is a test notification to verify your settings are working correctly.",
            deepLinkPath: "/notifications"
        )
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .blue : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quiet Hours Settings View

struct QuietHoursSettingsView: View {
    @Binding var settings: NotificationSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker(
                        "Start Time",
                        selection: $settings.quietHoursStart,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "End Time",
                        selection: $settings.quietHoursEnd,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("Quiet Hours Schedule")
                } footer: {
                    Text("Non-urgent notifications will be silenced during these hours. Urgent notifications like security alerts will still be delivered.")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Status")
                                .font(.headline)
                            
                            Text(settings.isInQuietHours() ? "In quiet hours" : "Not in quiet hours")
                                .font(.subheadline)
                                .foregroundColor(settings.isInQuietHours() ? .orange : .green)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Quiet Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}