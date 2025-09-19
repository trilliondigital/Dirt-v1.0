import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var preferences: NotificationPreferences
    @State private var showingQuietHoursDetail = false
    
    init() {
        _preferences = State(initialValue: PushNotificationService.shared.preferences)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Master toggle
                masterToggleSection
                
                // Category preferences
                if preferences.isEnabled {
                    categoryPreferencesSection
                    
                    // Type preferences
                    typePreferencesSection
                    
                    // Quiet hours
                    quietHoursSection
                    
                    // Display preferences
                    displayPreferencesSection
                    
                    // Advanced settings
                    advancedSettingsSection
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingQuietHoursDetail) {
                QuietHoursDetailView(preferences: $preferences)
            }
        }
    }
    
    // MARK: - Master Toggle Section
    
    private var masterToggleSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $preferences.isEnabled)
                .onChange(of: preferences.isEnabled) { enabled in
                    if !enabled {
                        // Disable all categories when master toggle is off
                        for category in NotificationCategory.allCases {
                            preferences.categoryPreferences[category] = false
                        }
                    } else {
                        // Enable all categories when master toggle is on
                        for category in NotificationCategory.allCases {
                            preferences.categoryPreferences[category] = true
                        }
                    }
                }
        } footer: {
            if !preferences.isEnabled {
                Text("You won't receive any notifications when this is disabled.")
            } else {
                Text("You can customize which types of notifications you receive below.")
            }
        }
    }
    
    // MARK: - Category Preferences Section
    
    private var categoryPreferencesSection: some View {
        Section("Notification Categories") {
            ForEach(NotificationCategory.allCases, id: \.self) { category in
                Toggle(isOn: Binding(
                    get: { preferences.categoryPreferences[category] ?? false },
                    set: { enabled in
                        preferences.categoryPreferences[category] = enabled
                        
                        // Update all types in this category
                        let typesInCategory = NotificationType.allCases.filter { $0.category == category }
                        for type in typesInCategory {
                            preferences.typePreferences[type] = enabled
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.displayName)
                            .font(.body)
                        
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Type Preferences Section
    
    private var typePreferencesSection: some View {
        Section("Specific Notifications") {
            ForEach(NotificationType.allCases, id: \.self) { type in
                let categoryEnabled = preferences.categoryPreferences[type.category] ?? false
                
                Toggle(isOn: Binding(
                    get: { preferences.typePreferences[type] ?? false },
                    set: { preferences.typePreferences[type] = $0 }
                )) {
                    HStack {
                        Image(systemName: type.iconName)
                            .foregroundColor(categoryEnabled ? .blue : .gray)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.body)
                            
                            Text(priorityDescription(for: type.priority))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        priorityBadge(for: type.priority)
                    }
                }
                .disabled(!categoryEnabled)
            }
        } footer: {
            Text("Individual notification types can only be enabled if their category is enabled.")
        }
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        Section("Quiet Hours") {
            Toggle("Enable Quiet Hours", isOn: $preferences.quietHoursEnabled)
            
            if preferences.quietHoursEnabled {
                Button {
                    showingQuietHoursDetail = true
                } label: {
                    HStack {
                        Text("Schedule")
                        
                        Spacer()
                        
                        Text(quietHoursText)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
        } footer: {
            if preferences.quietHoursEnabled {
                Text("During quiet hours, only urgent notifications will be delivered.")
            } else {
                Text("Notifications will be delivered at any time when quiet hours are disabled.")
            }
        }
    }
    
    // MARK: - Display Preferences Section
    
    private var displayPreferencesSection: some View {
        Section("Display") {
            Toggle("Sound", isOn: $preferences.soundEnabled)
            Toggle("Badge", isOn: $preferences.badgeEnabled)
            Toggle("Show Previews", isOn: $preferences.previewEnabled)
        } footer: {
            Text("These settings control how notifications appear on your device.")
        }
    }
    
    // MARK: - Advanced Settings Section
    
    private var advancedSettingsSection: some View {
        Section("Advanced") {
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .foregroundColor(.blue)
            
            Button("Clear All Notifications") {
                clearAllNotifications()
            }
            .foregroundColor(.red)
        } footer: {
            Text("Reset will restore all notification settings to their default values.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var quietHoursText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startTime = Calendar.current.date(bySettingHour: preferences.quietHoursStart, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: preferences.quietHoursEnd, minute: 0, second: 0, of: Date()) ?? Date()
        
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    // MARK: - Helper Methods
    
    private func priorityDescription(for priority: NotificationPriority) -> String {
        switch priority {
        case .low:
            return "Low priority, silent delivery"
        case .medium:
            return "Normal priority with sound"
        case .high:
            return "High priority, time sensitive"
        case .urgent:
            return "Urgent, bypasses quiet hours"
        }
    }
    
    private func priorityBadge(for priority: NotificationPriority) -> some View {
        Text(priority.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(colorForPriority(priority))
            )
    }
    
    private func colorForPriority(_ priority: NotificationPriority) -> Color {
        switch priority {
        case .low:
            return .gray
        case .medium:
            return .blue
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
    
    private func savePreferences() {
        pushNotificationService.updatePreferences(preferences)
    }
    
    private func resetToDefaults() {
        preferences = NotificationPreferences()
    }
    
    private func clearAllNotifications() {
        pushNotificationService.clearAllNotifications()
    }
}

// MARK: - Quiet Hours Detail View

struct QuietHoursDetailView: View {
    @Binding var preferences: NotificationPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    DatePicker(
                        "Start Time",
                        selection: Binding(
                            get: {
                                Calendar.current.date(bySettingHour: preferences.quietHoursStart, minute: 0, second: 0, of: Date()) ?? Date()
                            },
                            set: { date in
                                preferences.quietHoursStart = Calendar.current.component(.hour, from: date)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "End Time",
                        selection: Binding(
                            get: {
                                Calendar.current.date(bySettingHour: preferences.quietHoursEnd, minute: 0, second: 0, of: Date()) ?? Date()
                            },
                            set: { date in
                                preferences.quietHoursEnd = Calendar.current.component(.hour, from: date)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                } footer: {
                    Text("During quiet hours, only urgent notifications will be delivered. All other notifications will be held until quiet hours end.")
                }
                
                Section("Preview") {
                    HStack {
                        Text("Current Status:")
                        
                        Spacer()
                        
                        if preferences.isInQuietHours() {
                            Label("Quiet Hours Active", systemImage: "moon.fill")
                                .foregroundColor(.orange)
                        } else {
                            Label("Normal Hours", systemImage: "sun.max.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Quiet Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}