import Foundation
import Combine

// MARK: - Reporting Service
class ReportingService: ObservableObject {
    static let shared = ReportingService()
    
    @Published var reports: [ContentReport] = []
    @Published var reportingStatistics = ReportingStatistics()
    
    private let moderationService = ModerationService.shared
    private let queueService = ModerationQueueService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadMockReports()
    }
    
    // MARK: - Public API
    
    /// Submits a report for content
    func submitReport(
        contentId: UUID,
        contentType: ContentType,
        reporterId: UUID?,
        reason: ReportReason,
        additionalDetails: String? = nil,
        isAnonymous: Bool = true
    ) async -> ReportSubmissionResult {
        
        // Validate report
        let validationResult = validateReport(
            contentId: contentId,
            reporterId: reporterId,
            reason: reason
        )
        
        guard validationResult.isValid else {
            return ReportSubmissionResult(
                success: false,
                reportId: nil,
                error: validationResult.error
            )
        }
        
        // Create report
        let report = ContentReport(
            id: UUID(),
            contentId: contentId,
            contentType: contentType,
            reporterId: isAnonymous ? nil : reporterId,
            reason: reason,
            additionalDetails: additionalDetails,
            status: .pending,
            submittedAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            resolution: nil,
            resolutionNotes: nil,
            isAnonymous: isAnonymous
        )
        
        // Add to reports list
        await MainActor.run {
            reports.append(report)
            updateReportingStatistics()
        }
        
        // Process the report
        await processReport(report)
        
        // Check for automatic actions
        await checkForAutomaticActions(contentId: contentId)
        
        return ReportSubmissionResult(
            success: true,
            reportId: report.id,
            error: nil
        )
    }
    
    /// Gets reports for a specific content item
    func getReportsForContent(contentId: UUID) -> [ContentReport] {
        return reports.filter { $0.contentId == contentId }
    }
    
    /// Gets reports submitted by a specific user
    func getReportsByUser(userId: UUID) -> [ContentReport] {
        return reports.filter { $0.reporterId == userId }
    }
    
    /// Gets pending reports for moderation review
    func getPendingReports(limit: Int = 50) -> [ContentReport] {
        return reports
            .filter { $0.status == .pending }
            .sorted { $0.submittedAt > $1.submittedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Reviews a report (moderator action)
    func reviewReport(
        reportId: UUID,
        moderatorId: UUID,
        resolution: ReportResolution,
        notes: String? = nil
    ) async -> Bool {
        
        guard let index = reports.firstIndex(where: { $0.id == reportId }) else {
            return false
        }
        
        let report = reports[index]
        
        // Update report status
        let updatedReport = ContentReport(
            id: report.id,
            contentId: report.contentId,
            contentType: report.contentType,
            reporterId: report.reporterId,
            reason: report.reason,
            additionalDetails: report.additionalDetails,
            status: .reviewed,
            submittedAt: report.submittedAt,
            reviewedAt: Date(),
            reviewedBy: moderatorId,
            resolution: resolution,
            resolutionNotes: notes,
            isAnonymous: report.isAnonymous
        )
        
        await MainActor.run {
            reports[index] = updatedReport
            updateReportingStatistics()
        }
        
        // Apply resolution actions
        await applyReportResolution(updatedReport)
        
        // Notify reporter if not anonymous
        if let reporterId = report.reporterId, !report.isAnonymous {
            await notifyReporterOfResolution(reporterId: reporterId, report: updatedReport)
        }
        
        return true
    }
    
    /// Gets reporting analytics for moderators
    func getReportingAnalytics(timeRange: TimeRange) async -> ReportingAnalytics {
        let startDate = getStartDate(for: timeRange)
        let reportsInRange = reports.filter { $0.submittedAt >= startDate }
        
        let totalReports = reportsInRange.count
        let uniqueContentReported = Set(reportsInRange.map { $0.contentId }).count
        let uniqueReporters = Set(reportsInRange.compactMap { $0.reporterId }).count
        let anonymousReports = reportsInRange.filter { $0.isAnonymous }.count
        
        // Calculate reason distribution
        let reasonDistribution = Dictionary(grouping: reportsInRange, by: { $0.reason })
            .mapValues { $0.count }
        
        // Calculate resolution distribution
        let resolvedReports = reportsInRange.filter { $0.status == .reviewed }
        let resolutionDistribution = Dictionary(grouping: resolvedReports, by: { $0.resolution })
            .compactMapValues { reports in
                reports.compactMap { $0.resolution }.count
            }
        
        // Calculate average resolution time
        let resolutionTimes = resolvedReports.compactMap { report -> TimeInterval? in
            guard let reviewedAt = report.reviewedAt else { return nil }
            return reviewedAt.timeIntervalSince(report.submittedAt)
        }
        
        let averageResolutionTime = resolutionTimes.isEmpty ? 0 : resolutionTimes.reduce(0, +) / Double(resolutionTimes.count)
        
        return ReportingAnalytics(
            timeRange: timeRange,
            totalReports: totalReports,
            uniqueContentReported: uniqueContentReported,
            uniqueReporters: uniqueReporters,
            anonymousReports: anonymousReports,
            reasonDistribution: reasonDistribution,
            resolutionDistribution: resolutionDistribution,
            averageResolutionTimeHours: averageResolutionTime / 3600,
            falseReportRate: calculateFalseReportRate(reports: resolvedReports)
        )
    }
    
    /// Checks if user has exceeded reporting limits
    func checkReportingLimits(userId: UUID) -> ReportingLimitStatus {
        let userReports = getReportsByUser(userId: userId)
        let recentReports = userReports.filter { report in
            Calendar.current.isDate(report.submittedAt, inSameDayAs: Date())
        }
        
        let dailyLimit = 10
        let remainingReports = max(0, dailyLimit - recentReports.count)
        
        // Check for abuse patterns
        let falseReports = userReports.filter { report in
            report.resolution == .falseReport
        }.count
        
        let totalReports = userReports.count
        let falseReportRate = totalReports > 0 ? Double(falseReports) / Double(totalReports) : 0.0
        
        let isAbusive = falseReportRate > 0.5 && totalReports >= 5
        
        return ReportingLimitStatus(
            canReport: remainingReports > 0 && !isAbusive,
            remainingReports: remainingReports,
            dailyLimit: dailyLimit,
            isAbusive: isAbusive,
            falseReportRate: falseReportRate
        )
    }
    
    /// Gets content that has been reported multiple times
    func getMultipleReportedContent(threshold: Int = 3) -> [MultipleReportedContent] {
        let contentReports = Dictionary(grouping: reports, by: { $0.contentId })
        
        return contentReports.compactMap { (contentId, reports) -> MultipleReportedContent? in
            guard reports.count >= threshold else { return nil }
            
            let pendingReports = reports.filter { $0.status == .pending }
            let reasonCounts = Dictionary(grouping: reports, by: { $0.reason })
                .mapValues { $0.count }
            
            return MultipleReportedContent(
                contentId: contentId,
                contentType: reports.first?.contentType ?? .post,
                totalReports: reports.count,
                pendingReports: pendingReports.count,
                mostCommonReason: reasonCounts.max(by: { $0.value < $1.value })?.key ?? .other,
                firstReportedAt: reports.map { $0.submittedAt }.min() ?? Date(),
                lastReportedAt: reports.map { $0.submittedAt }.max() ?? Date()
            )
        }.sorted { $0.totalReports > $1.totalReports }
    }
    
    // MARK: - Private Methods
    
    private func validateReport(
        contentId: UUID,
        reporterId: UUID?,
        reason: ReportReason
    ) -> ReportValidationResult {
        
        // Check if user can report (if not anonymous)
        if let reporterId = reporterId {
            let limitStatus = checkReportingLimits(userId: reporterId)
            if !limitStatus.canReport {
                let error = limitStatus.isAbusive ? 
                    "Account restricted due to false reporting" : 
                    "Daily reporting limit exceeded"
                return ReportValidationResult(isValid: false, error: error)
            }
            
            // Check for duplicate reports
            let existingReports = reports.filter { report in
                report.contentId == contentId &&
                report.reporterId == reporterId &&
                report.reason == reason &&
                Calendar.current.isDate(report.submittedAt, inSameDayAs: Date())
            }
            
            if !existingReports.isEmpty {
                return ReportValidationResult(
                    isValid: false,
                    error: "You have already reported this content for this reason today"
                )
            }
        }
        
        return ReportValidationResult(isValid: true, error: nil)
    }
    
    private func processReport(_ report: ContentReport) async {
        // Add to moderation queue if high priority
        if report.reason.priority == .high || report.reason.priority == .critical {
            await addToModerationQueue(report: report)
        }
        
        // Log the report for analytics
        await logReportForAnalytics(report)
    }
    
    private func addToModerationQueue(report: ContentReport) async {
        // Create a moderation result for the report
        let moderationResult = ModerationResult(
            contentId: report.contentId,
            contentType: report.contentType,
            status: .flagged,
            flags: [report.reason.moderationFlag],
            confidence: 0.8, // User reports have high confidence
            severity: report.reason.severity,
            reason: "User reported: \(report.reason.description)",
            detectedPII: [],
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: report.additionalDetails
        )
        
        await queueService.addToQueue(
            contentId: report.contentId,
            contentType: report.contentType,
            authorId: UUID(), // Would get actual author ID in production
            content: nil,
            moderationResult: moderationResult,
            reportCount: getReportsForContent(contentId: report.contentId).count
        )
    }
    
    private func checkForAutomaticActions(contentId: UUID) async {
        let contentReports = getReportsForContent(contentId: contentId)
        let reportCount = contentReports.count
        
        // Automatic actions based on report count and severity
        if reportCount >= 5 {
            // Hide content temporarily
            await hideContentTemporarily(contentId: contentId)
        }
        
        if reportCount >= 10 {
            // Escalate to high priority moderation
            await escalateToHighPriority(contentId: contentId)
        }
        
        // Check for harassment patterns
        let harassmentReports = contentReports.filter { 
            $0.reason == .harassment || $0.reason == .hateSpeech 
        }
        
        if harassmentReports.count >= 3 {
            await applyAutomaticUserRestriction(contentId: contentId)
        }
    }
    
    private func applyReportResolution(_ report: ContentReport) async {
        guard let resolution = report.resolution else { return }
        
        switch resolution {
        case .actionTaken:
            // Content was removed or user was penalized
            await logResolutionAction(report: report, action: "Content moderated")
            
        case .noActionNeeded:
            // Report was valid but no action needed
            await logResolutionAction(report: report, action: "No action required")
            
        case .falseReport:
            // Report was false, may penalize reporter
            await handleFalseReport(report)
            
        case .duplicate:
            // Duplicate report, no additional action
            await logResolutionAction(report: report, action: "Duplicate report")
        }
    }
    
    private func handleFalseReport(_ report: ContentReport) async {
        guard let reporterId = report.reporterId else { return }
        
        // Check if user has pattern of false reporting
        let userReports = getReportsByUser(userId: reporterId)
        let falseReports = userReports.filter { $0.resolution == .falseReport }
        
        if falseReports.count >= 3 {
            // Apply reporting restriction
            await moderationService.applyUserPenalty(
                userId: reporterId,
                penalty: .restrictedPosting(days: 7),
                reason: "Pattern of false reporting",
                moderatorId: report.reviewedBy ?? UUID()
            )
        }
        
        await logResolutionAction(report: report, action: "False report penalty considered")
    }
    
    private func hideContentTemporarily(contentId: UUID) async {
        // In production, this would hide the content from public view
        print("🚫 Content \(contentId) hidden due to multiple reports")
    }
    
    private func escalateToHighPriority(contentId: UUID) async {
        // In production, this would update the moderation queue priority
        print("⚡ Content \(contentId) escalated to high priority")
    }
    
    private func applyAutomaticUserRestriction(contentId: UUID) async {
        // In production, this would apply temporary restrictions to the content author
        print("⚠️ Automatic user restriction applied for content \(contentId)")
    }
    
    private func logReportForAnalytics(_ report: ContentReport) async {
        // In production, this would log to analytics system
        print("📊 Report logged for analytics: \(report.id)")
    }
    
    private func logResolutionAction(report: ContentReport, action: String) async {
        // In production, this would log the resolution action
        print("📝 Report resolution: \(report.id) - \(action)")
    }
    
    private func notifyReporterOfResolution(reporterId: UUID, report: ContentReport) async {
        // In production, this would send a notification to the reporter
        print("📱 Notified reporter \(reporterId) of resolution for report \(report.id)")
    }
    
    private func updateReportingStatistics() {
        let totalReports = reports.count
        let pendingReports = reports.filter { $0.status == .pending }.count
        let resolvedReports = reports.filter { $0.status == .reviewed }.count
        let anonymousReports = reports.filter { $0.isAnonymous }.count
        
        reportingStatistics = ReportingStatistics(
            totalReports: totalReports,
            pendingReports: pendingReports,
            resolvedReports: resolvedReports,
            anonymousReports: anonymousReports,
            averageResolutionTimeHours: calculateAverageResolutionTime()
        )
    }
    
    private func calculateAverageResolutionTime() -> Double {
        let resolvedReports = reports.filter { 
            $0.status == .reviewed && $0.reviewedAt != nil 
        }
        
        guard !resolvedReports.isEmpty else { return 0 }
        
        let totalTime = resolvedReports.reduce(0.0) { total, report in
            guard let reviewedAt = report.reviewedAt else { return total }
            return total + reviewedAt.timeIntervalSince(report.submittedAt)
        }
        
        return totalTime / Double(resolvedReports.count) / 3600 // Convert to hours
    }
    
    private func calculateFalseReportRate(reports: [ContentReport]) -> Double {
        guard !reports.isEmpty else { return 0 }
        
        let falseReports = reports.filter { $0.resolution == .falseReport }.count
        return Double(falseReports) / Double(reports.count)
    }
    
    private func getStartDate(for timeRange: TimeRange) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    private func loadMockReports() {
        // Load mock reports for development
        let mockReports = [
            createMockReport(reason: .harassment, contentType: .post, isAnonymous: true),
            createMockReport(reason: .spam, contentType: .review, isAnonymous: false),
            createMockReport(reason: .inappropriateContent, contentType: .comment, isAnonymous: true),
            createMockReport(reason: .personalInformation, contentType: .image, isAnonymous: false),
            createMockReport(reason: .hateSpeech, contentType: .post, isAnonymous: true)
        ]
        
        reports = mockReports
        updateReportingStatistics()
    }
    
    private func createMockReport(
        reason: ReportReason,
        contentType: ContentType,
        isAnonymous: Bool
    ) -> ContentReport {
        return ContentReport(
            id: UUID(),
            contentId: UUID(),
            contentType: contentType,
            reporterId: isAnonymous ? nil : UUID(),
            reason: reason,
            additionalDetails: "Mock report details for \(reason.description)",
            status: .pending,
            submittedAt: Date().addingTimeInterval(-Double.random(in: 0...86400)),
            reviewedAt: nil,
            reviewedBy: nil,
            resolution: nil,
            resolutionNotes: nil,
            isAnonymous: isAnonymous
        )
    }
}

// MARK: - Supporting Types

struct ContentReport: Identifiable, Codable {
    let id: UUID
    let contentId: UUID
    let contentType: ContentType
    let reporterId: UUID?
    let reason: ReportReason
    let additionalDetails: String?
    let status: ReportStatus
    let submittedAt: Date
    let reviewedAt: Date?
    let reviewedBy: UUID?
    let resolution: ReportResolution?
    let resolutionNotes: String?
    let isAnonymous: Bool
}

enum ReportReason: String, CaseIterable, Codable {
    case harassment = "harassment"
    case spam = "spam"
    case inappropriateContent = "inappropriate_content"
    case hateSpeech = "hate_speech"
    case personalInformation = "personal_information"
    case violentContent = "violent_content"
    case sexualContent = "sexual_content"
    case misinformation = "misinformation"
    case copyrightViolation = "copyright_violation"
    case impersonation = "impersonation"
    case other = "other"
    
    var description: String {
        switch self {
        case .harassment:
            return "Harassment or Bullying"
        case .spam:
            return "Spam"
        case .inappropriateContent:
            return "Inappropriate Content"
        case .hateSpeech:
            return "Hate Speech"
        case .personalInformation:
            return "Personal Information"
        case .violentContent:
            return "Violent Content"
        case .sexualContent:
            return "Sexual Content"
        case .misinformation:
            return "Misinformation"
        case .copyrightViolation:
            return "Copyright Violation"
        case .impersonation:
            return "Impersonation"
        case .other:
            return "Other"
        }
    }
    
    var priority: ModerationPriority {
        switch self {
        case .harassment, .hateSpeech, .violentContent:
            return .critical
        case .personalInformation, .sexualContent:
            return .high
        case .inappropriateContent, .misinformation, .impersonation:
            return .medium
        case .spam, .copyrightViolation, .other:
            return .low
        }
    }
    
    var severity: ModerationSeverity {
        switch self {
        case .harassment, .hateSpeech, .violentContent:
            return .critical
        case .personalInformation, .sexualContent:
            return .high
        case .inappropriateContent, .misinformation:
            return .medium
        case .spam, .copyrightViolation, .impersonation, .other:
            return .low
        }
    }
    
    var moderationFlag: ModerationFlag {
        switch self {
        case .harassment:
            return .harassment
        case .spam:
            return .spam
        case .inappropriateContent:
            return .inappropriateContent
        case .hateSpeech:
            return .hateSpeech
        case .personalInformation:
            return .personalInformation
        case .violentContent:
            return .violentContent
        case .sexualContent:
            return .sexualContent
        case .misinformation:
            return .misinformation
        case .copyrightViolation:
            return .copyrightViolation
        case .impersonation, .other:
            return .other
        }
    }
}

enum ReportStatus: String, Codable {
    case pending = "pending"
    case reviewed = "reviewed"
    case dismissed = "dismissed"
}

enum ReportResolution: String, Codable {
    case actionTaken = "action_taken"
    case noActionNeeded = "no_action_needed"
    case falseReport = "false_report"
    case duplicate = "duplicate"
}

struct ReportSubmissionResult {
    let success: Bool
    let reportId: UUID?
    let error: String?
}

struct ReportValidationResult {
    let isValid: Bool
    let error: String?
}

struct ReportingLimitStatus {
    let canReport: Bool
    let remainingReports: Int
    let dailyLimit: Int
    let isAbusive: Bool
    let falseReportRate: Double
}

struct ReportingStatistics {
    let totalReports: Int
    let pendingReports: Int
    let resolvedReports: Int
    let anonymousReports: Int
    let averageResolutionTimeHours: Double
    
    init(
        totalReports: Int = 0,
        pendingReports: Int = 0,
        resolvedReports: Int = 0,
        anonymousReports: Int = 0,
        averageResolutionTimeHours: Double = 0
    ) {
        self.totalReports = totalReports
        self.pendingReports = pendingReports
        self.resolvedReports = resolvedReports
        self.anonymousReports = anonymousReports
        self.averageResolutionTimeHours = averageResolutionTimeHours
    }
}

struct ReportingAnalytics {
    let timeRange: TimeRange
    let totalReports: Int
    let uniqueContentReported: Int
    let uniqueReporters: Int
    let anonymousReports: Int
    let reasonDistribution: [ReportReason: Int]
    let resolutionDistribution: [ReportResolution: Int]
    let averageResolutionTimeHours: Double
    let falseReportRate: Double
}

struct MultipleReportedContent {
    let contentId: UUID
    let contentType: ContentType
    let totalReports: Int
    let pendingReports: Int
    let mostCommonReason: ReportReason
    let firstReportedAt: Date
    let lastReportedAt: Date
}