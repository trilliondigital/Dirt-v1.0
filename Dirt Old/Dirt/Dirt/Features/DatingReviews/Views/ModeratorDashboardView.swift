import SwiftUI

struct ModeratorDashboardView: View {
    @StateObject private var queueService = ModerationQueueService.shared
    @StateObject private var moderationService = ModerationService()
    
    @State private var selectedFilter: ModerationFilter = .all
    @State private var selectedPriority: ModerationPriority? = nil
    @State private var selectedContentType: ContentType? = nil
    @State private var showingStatistics = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with statistics
                moderationHeaderView
                
                // Filters
                moderationFiltersView
                
                // Queue list
                moderationQueueListView
            }
            .navigationTitle("Moderation Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Statistics") {
                        showingStatistics = true
                    }
                }
            }
            .sheet(isPresented: $showingStatistics) {
                ModerationStatisticsView()
            }
            .refreshable {
                await refreshQueue()
            }
        }
    }
    
    // MARK: - Header View
    
    private var moderationHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                StatisticCard(
                    title: "Total Items",
                    value: "\(queueService.queueStatistics.totalItems)",
                    color: .blue
                )
                
                StatisticCard(
                    title: "High Priority",
                    value: "\(queueService.queueStatistics.highPriorityItems)",
                    color: .red
                )
                
                StatisticCard(
                    title: "Avg Wait",
                    value: "\(queueService.queueStatistics.averageWaitTimeMinutes)m",
                    color: .orange
                )
            }
            .padding(.horizontal)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search content...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Filters View
    
    private var moderationFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Filter by status
                FilterPill(
                    title: "All",
                    isSelected: selectedFilter == .all,
                    action: { selectedFilter = .all }
                )
                
                FilterPill(
                    title: "Pending",
                    isSelected: selectedFilter == .pending,
                    action: { selectedFilter = .pending }
                )
                
                FilterPill(
                    title: "Flagged",
                    isSelected: selectedFilter == .flagged,
                    action: { selectedFilter = .flagged }
                )
                
                FilterPill(
                    title: "High Priority",
                    isSelected: selectedFilter == .highPriority,
                    action: { selectedFilter = .highPriority }
                )
                
                // Filter by content type
                ForEach(ContentType.allCases, id: \.self) { contentType in
                    FilterPill(
                        title: contentType.rawValue.capitalized,
                        isSelected: selectedContentType == contentType,
                        action: {
                            selectedContentType = selectedContentType == contentType ? nil : contentType
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Queue List View
    
    private var moderationQueueListView: some View {
        List {
            ForEach(filteredQueueItems, id: \.id) { item in
                NavigationLink(destination: ModerationDetailView(queueItem: item)) {
                    ModerationQueueItemRow(item: item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Approve") {
                        Task {
                            await approveItem(item)
                        }
                    }
                    .tint(.green)
                    
                    Button("Reject") {
                        Task {
                            await rejectItem(item)
                        }
                    }
                    .tint(.red)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Flag") {
                        Task {
                            await flagItem(item)
                        }
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Computed Properties
    
    private var filteredQueueItems: [ModerationQueueItem] {
        var items = queueService.queueItems
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .pending:
            items = items.filter { $0.moderationResult.status == .pending }
        case .flagged:
            items = items.filter { $0.moderationResult.status == .flagged }
        case .highPriority:
            items = items.filter { $0.isHighPriority }
        }
        
        // Apply content type filter
        if let contentType = selectedContentType {
            items = items.filter { $0.contentType == contentType }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content?.localizedCaseInsensitiveContains(searchText) == true ||
                item.moderationResult.reason?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return items
    }
    
    // MARK: - Actions
    
    private func refreshQueue() async {
        // In production, this would refresh from server
        await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for demo
    }
    
    private func approveItem(_ item: ModerationQueueItem) async {
        await queueService.updateQueueItem(
            itemId: item.id,
            action: .approve,
            moderatorId: UUID(), // Current moderator ID
            reason: "Content approved by moderator"
        )
    }
    
    private func rejectItem(_ item: ModerationQueueItem) async {
        await queueService.updateQueueItem(
            itemId: item.id,
            action: .reject,
            moderatorId: UUID(), // Current moderator ID
            reason: "Content rejected by moderator"
        )
    }
    
    private func flagItem(_ item: ModerationQueueItem) async {
        await queueService.updateQueueItem(
            itemId: item.id,
            action: .flag,
            moderatorId: UUID(), // Current moderator ID
            reason: "Content flagged for additional review"
        )
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ModerationQueueItemRow: View {
    let item: ModerationQueueItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with priority and content type
            HStack {
                PriorityBadge(priority: item.priority)
                
                Text(item.contentType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(timeAgoString(from: item.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content preview
            if let content = item.content {
                Text(content)
                    .font(.body)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Flags and reason
            if !item.moderationResult.flags.isEmpty {
                HStack {
                    ForEach(item.moderationResult.flags.prefix(3), id: \.self) { flag in
                        Text(flag.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(flagColor(for: flag).opacity(0.2))
                            .foregroundColor(flagColor(for: flag))
                            .cornerRadius(4)
                    }
                    
                    if item.moderationResult.flags.count > 3 {
                        Text("+\(item.moderationResult.flags.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // PII detection indicator
            if !item.moderationResult.detectedPII.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("\(item.moderationResult.detectedPII.count) PII detected")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func flagColor(for flag: ModerationFlag) -> Color {
        switch flag.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct PriorityBadge: View {
    let priority: ModerationPriority
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            Text(priority.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
}

// MARK: - Filter Enum

enum ModerationFilter: CaseIterable {
    case all
    case pending
    case flagged
    case highPriority
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .pending:
            return "Pending"
        case .flagged:
            return "Flagged"
        case .highPriority:
            return "High Priority"
        }
    }
}

// MARK: - Preview

struct ModeratorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ModeratorDashboardView()
    }
}