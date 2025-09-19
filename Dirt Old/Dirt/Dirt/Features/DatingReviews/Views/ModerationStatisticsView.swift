import SwiftUI
import Charts

struct ModerationStatisticsView: View {
    @StateObject private var queueService = ModerationQueueService.shared
    @StateObject private var flaggingService = AutomaticContentFlaggingService.shared
    @StateObject private var statisticsService = ModerationStatisticsService()
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingExportOptions = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range selector
                    timeRangeSelector
                    
                    // Overview cards
                    overviewCardsView
                    
                    // Queue statistics
                    queueStatisticsView
                    
                    // AI flagging statistics
                    aiFlaggingStatisticsView
                    
                    // Moderation trends chart
                    moderationTrendsChart
                    
                    // Flag distribution chart
                    flagDistributionChart
                    
                    // Performance metrics
                    performanceMetricsView
                }
                .padding()
            }
            .navigationTitle("Moderation Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportOptions = true
                    }
                }
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Export Statistics"),
                    buttons: [
                        .default(Text("Export as PDF")) {
                            exportStatistics(format: .pdf)
                        },
                        .default(Text("Export as CSV")) {
                            exportStatistics(format: .csv)
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTimeRange) { _ in
            Task {
                await statisticsService.loadStatistics(for: selectedTimeRange)
            }
        }
    }
    
    // MARK: - Overview Cards
    
    private var overviewCardsView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatisticOverviewCard(
                title: "Total Processed",
                value: "\(statisticsService.totalProcessed)",
                change: statisticsService.totalProcessedChange,
                icon: "doc.text",
                color: .blue
            )
            
            StatisticOverviewCard(
                title: "Auto Approved",
                value: "\(statisticsService.autoApproved)",
                change: statisticsService.autoApprovedChange,
                icon: "checkmark.circle",
                color: .green
            )
            
            StatisticOverviewCard(
                title: "Auto Rejected",
                value: "\(statisticsService.autoRejected)",
                change: statisticsService.autoRejectedChange,
                icon: "xmark.circle",
                color: .red
            )
            
            StatisticOverviewCard(
                title: "Human Review",
                value: "\(statisticsService.humanReview)",
                change: statisticsService.humanReviewChange,
                icon: "person.circle",
                color: .orange
            )
        }
    }
    
    // MARK: - Queue Statistics
    
    private var queueStatisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Queue Status")
                .font(.headline)
            
            let queueStats = queueService.getQueueStatistics()
            
            VStack(spacing: 8) {
                StatisticRow(
                    title: "Items in Queue",
                    value: "\(queueStats.totalItems)",
                    icon: "tray.full"
                )
                
                StatisticRow(
                    title: "High Priority",
                    value: "\(queueStats.highPriorityItems)",
                    icon: "exclamationmark.triangle.fill",
                    valueColor: queueStats.highPriorityItems > 0 ? .red : .primary
                )
                
                StatisticRow(
                    title: "Average Wait Time",
                    value: "\(queueStats.averageWaitTimeMinutes) min",
                    icon: "clock"
                )
                
                StatisticRow(
                    title: "Pending Review",
                    value: "\(queueStats.pendingItems)",
                    icon: "hourglass"
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - AI Flagging Statistics
    
    private var aiFlaggingStatisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Performance")
                .font(.headline)
            
            let aiStats = flaggingService.flaggingStatistics
            
            VStack(spacing: 8) {
                StatisticRow(
                    title: "Auto Approval Rate",
                    value: "\(Int(aiStats.autoApprovalRate * 100))%",
                    icon: "checkmark.circle.fill",
                    valueColor: aiStats.autoApprovalRate > 0.8 ? .green : .orange
                )
                
                StatisticRow(
                    title: "Human Review Rate",
                    value: "\(Int(aiStats.humanReviewRate * 100))%",
                    icon: "person.fill.questionmark",
                    valueColor: aiStats.humanReviewRate < 0.2 ? .green : .orange
                )
                
                StatisticRow(
                    title: "PII Detected",
                    value: "\(aiStats.piiDetected)",
                    icon: "eye.slash.fill"
                )
                
                StatisticRow(
                    title: "Total Flagged",
                    value: "\(aiStats.autoFlagged)",
                    icon: "flag.fill"
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Moderation Trends Chart
    
    private var moderationTrendsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moderation Trends")
                .font(.headline)
            
            Chart(statisticsService.moderationTrends) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Count", dataPoint.approved)
                )
                .foregroundStyle(.green)
                .symbol(Circle())
                
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Count", dataPoint.rejected)
                )
                .foregroundStyle(.red)
                .symbol(Circle())
                
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Count", dataPoint.flagged)
                )
                .foregroundStyle(.orange)
                .symbol(Circle())
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Flag Distribution Chart
    
    private var flagDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Violation Types")
                .font(.headline)
            
            Chart(statisticsService.flagDistribution) { flagData in
                BarMark(
                    x: .value("Count", flagData.count),
                    y: .value("Flag", flagData.flag.description)
                )
                .foregroundStyle(flagColor(for: flagData.flag))
            }
            .frame(height: 300)
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Performance Metrics
    
    private var performanceMetricsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatisticRow(
                    title: "Average Processing Time",
                    value: "\(statisticsService.averageProcessingTime)ms",
                    icon: "speedometer"
                )
                
                StatisticRow(
                    title: "AI Accuracy",
                    value: "\(Int(statisticsService.aiAccuracy * 100))%",
                    icon: "target",
                    valueColor: statisticsService.aiAccuracy > 0.9 ? .green : .orange
                )
                
                StatisticRow(
                    title: "False Positive Rate",
                    value: "\(Int(statisticsService.falsePositiveRate * 100))%",
                    icon: "exclamationmark.triangle",
                    valueColor: statisticsService.falsePositiveRate < 0.1 ? .green : .red
                )
                
                StatisticRow(
                    title: "Appeal Success Rate",
                    value: "\(Int(statisticsService.appealSuccessRate * 100))%",
                    icon: "arrow.clockwise.circle"
                )
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func exportStatistics(format: ExportFormat) {
        Task {
            await statisticsService.exportStatistics(format: format, timeRange: selectedTimeRange)
        }
    }
}

// MARK: - Supporting Views

struct StatisticOverviewCard: View {
    let title: String
    let value: String
    let change: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        
                        Text("\(abs(Int(change)))%")
                            .font(.caption)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    let valueColor: Color
    
    init(title: String, value: String, icon: String, valueColor: Color = .primary) {
        self.title = title
        self.value = value
        self.icon = icon
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case day
    case week
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .day:
            return "24h"
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .quarter:
            return "Quarter"
        case .year:
            return "Year"
        }
    }
}

enum ExportFormat {
    case pdf
    case csv
}

struct ModerationTrendData {
    let date: Date
    let approved: Int
    let rejected: Int
    let flagged: Int
}

struct FlagDistributionData {
    let flag: ModerationFlag
    let count: Int
}

// MARK: - Statistics Service

class ModerationStatisticsService: ObservableObject {
    @Published var totalProcessed: Int = 0
    @Published var autoApproved: Int = 0
    @Published var autoRejected: Int = 0
    @Published var humanReview: Int = 0
    
    @Published var totalProcessedChange: Double? = nil
    @Published var autoApprovedChange: Double? = nil
    @Published var autoRejectedChange: Double? = nil
    @Published var humanReviewChange: Double? = nil
    
    @Published var moderationTrends: [ModerationTrendData] = []
    @Published var flagDistribution: [FlagDistributionData] = []
    
    @Published var averageProcessingTime: Int = 0
    @Published var aiAccuracy: Double = 0.0
    @Published var falsePositiveRate: Double = 0.0
    @Published var appealSuccessRate: Double = 0.0
    
    init() {
        loadMockData()
    }
    
    func loadStatistics(for timeRange: TimeRange) async {
        // In production, this would load real statistics from the backend
        await MainActor.run {
            loadMockData()
        }
    }
    
    func exportStatistics(format: ExportFormat, timeRange: TimeRange) async {
        // In production, this would generate and export the statistics
        print("Exporting statistics as \(format) for \(timeRange)")
    }
    
    private func loadMockData() {
        // Mock data for demonstration
        totalProcessed = 1250
        autoApproved = 950
        autoRejected = 180
        humanReview = 120
        
        totalProcessedChange = 12.5
        autoApprovedChange = 8.3
        autoRejectedChange = -5.2
        humanReviewChange = 15.7
        
        // Generate mock trend data
        moderationTrends = (0..<7).map { dayOffset in
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            return ModerationTrendData(
                date: date,
                approved: Int.random(in: 80...150),
                rejected: Int.random(in: 10...30),
                flagged: Int.random(in: 5...20)
            )
        }.reversed()
        
        // Generate mock flag distribution
        flagDistribution = ModerationFlag.allCases.map { flag in
            FlagDistributionData(
                flag: flag,
                count: Int.random(in: 1...50)
            )
        }.sorted { $0.count > $1.count }
        
        averageProcessingTime = 245
        aiAccuracy = 0.92
        falsePositiveRate = 0.08
        appealSuccessRate = 0.35
    }
}

// MARK: - Preview

struct ModerationStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        ModerationStatisticsView()
    }
}