import SwiftUI

struct AnnouncementRowView: View {
    let announcement: CommunityAnnouncement
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDismiss: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    announcementIcon
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        // Title and priority
                        HStack {
                            Text(announcement.title)
                                .font(.subheadline)
                                .fontWeight(announcement.isRead ? .medium : .semibold)
                                .foregroundColor(announcement.isRead ? .secondary : .primary)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            priorityBadge
                        }
                        
                        // Message
                        Text(announcement.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        // Footer
                        HStack {
                            // Type and time
                            Label(announcement.type.displayName, systemImage: announcement.type.iconName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(announcement.timeAgo)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Unread indicator
                            if !announcement.isRead {
                                Circle()
                                    .fill(priorityColor)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                
                // Action button (if available)
                if announcement.actionURL != nil {
                    HStack {
                        Spacer()
                        
                        Button("View Details") {
                            onTap()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                // Expiration warning
                if let expiresAt = announcement.expiresAt {
                    let timeUntilExpiration = expiresAt.timeIntervalSince(Date())
                    if timeUntilExpiration > 0 && timeUntilExpiration < 86400 { // Less than 24 hours
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text("Expires in \(timeUntilExpirationText(expiresAt))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColorForAnnouncement)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColorForAnnouncement, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Dismiss", role: .destructive) {
                onDismiss()
            }
            
            if !announcement.isRead {
                Button("Mark Read") {
                    onMarkAsRead()
                }
                .tint(.blue)
            }
        }
    }
    
    // MARK: - Components
    
    private var announcementIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 44, height: 44)
            
            Image(systemName: announcement.type.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconForegroundColor)
        }
    }
    
    private var priorityBadge: some View {
        Group {
            if announcement.priority == .high || announcement.priority == .urgent {
                Text(announcement.priority.displayName.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(priorityColor)
                    )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconBackgroundColor: Color {
        Color(announcement.type.color).opacity(0.2)
    }
    
    private var iconForegroundColor: Color {
        Color(announcement.type.color)
    }
    
    private var priorityColor: Color {
        Color(announcement.priority.color)
    }
    
    private var backgroundColorForAnnouncement: Color {
        if announcement.isRead {
            return Color.clear
        }
        
        switch announcement.priority {
        case .low:
            return Color.gray.opacity(0.05)
        case .medium:
            return Color.blue.opacity(0.05)
        case .high:
            return Color.orange.opacity(0.05)
        case .urgent:
            return Color.red.opacity(0.05)
        }
    }
    
    private var borderColorForAnnouncement: Color {
        if announcement.isRead {
            return Color.gray.opacity(0.2)
        }
        
        switch announcement.priority {
        case .low:
            return Color.gray.opacity(0.3)
        case .medium:
            return Color.blue.opacity(0.3)
        case .high:
            return Color.orange.opacity(0.3)
        case .urgent:
            return Color.red.opacity(0.3)
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeUntilExpirationText(_ expiresAt: Date) -> String {
        let timeInterval = expiresAt.timeIntervalSince(Date())
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Announcements List View

struct AnnouncementsListView: View {
    @StateObject private var communityAnnouncementService = CommunityAnnouncementService.shared
    @State private var selectedType: AnnouncementType? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Type filter
                if !AnnouncementType.allCases.isEmpty {
                    typeFilterScrollView
                }
                
                // Announcements list
                if filteredAnnouncements.isEmpty {
                    emptyState
                } else {
                    announcementsList
                }
            }
            .navigationTitle("Announcements")
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if communityAnnouncementService.unreadAnnouncementCount > 0 {
                        Button("Mark All Read") {
                            communityAnnouncementService.markAllAnnouncementsAsRead()
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    // MARK: - Type Filter
    
    private var typeFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    count: communityAnnouncementService.getActiveAnnouncements().count,
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }
                
                ForEach(AnnouncementType.allCases, id: \.self) { type in
                    let count = communityAnnouncementService.getAnnouncementsByType(type).count
                    if count > 0 {
                        FilterChip(
                            title: type.displayName,
                            count: count,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Announcements List
    
    private var announcementsList: some View {
        List {
            ForEach(filteredAnnouncements) { announcement in
                AnnouncementRowView(
                    announcement: announcement,
                    onTap: {
                        handleAnnouncementTap(announcement)
                    },
                    onMarkAsRead: {
                        communityAnnouncementService.markAnnouncementAsRead(announcement.id)
                    },
                    onDismiss: {
                        communityAnnouncementService.dismissAnnouncement(announcement.id)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Announcements")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Community announcements will appear here when available.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredAnnouncements: [CommunityAnnouncement] {
        let activeAnnouncements = communityAnnouncementService.getActiveAnnouncements()
        
        if let selectedType = selectedType {
            return activeAnnouncements.filter { $0.type == selectedType }
        }
        
        return activeAnnouncements
    }
    
    // MARK: - Helper Methods
    
    private func handleAnnouncementTap(_ announcement: CommunityAnnouncement) {
        communityAnnouncementService.markAnnouncementAsRead(announcement.id)
        
        // Handle action URL if available
        if let actionURL = announcement.actionURL {
            handleDeepLink(actionURL)
        }
    }
    
    private func handleDeepLink(_ path: String) {
        // This would integrate with your app's navigation system
        print("Deep link: \(path)")
    }
}

// MARK: - Preview

struct AnnouncementRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AnnouncementRowView(
                announcement: CommunityAnnouncement(
                    title: "New Feature: Enhanced Notifications",
                    message: "We've improved our notification system with better categorization and smart filtering. You can now customize your notification preferences more granularly.",
                    type: .featureUpdate,
                    priority: .medium,
                    actionURL: "/features/notifications"
                ),
                onTap: {},
                onMarkAsRead: {},
                onDismiss: {}
            )
            
            AnnouncementRowView(
                announcement: CommunityAnnouncement(
                    title: "Community Event: Dating Success Stories",
                    message: "Join us this weekend for a special event where community members share their dating success stories and tips!",
                    type: .event,
                    priority: .high,
                    expiresAt: Calendar.current.date(byAdding: .hour, value: 6, to: Date()),
                    actionURL: "/events/success-stories",
                    isRead: false
                ),
                onTap: {},
                onMarkAsRead: {},
                onDismiss: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}