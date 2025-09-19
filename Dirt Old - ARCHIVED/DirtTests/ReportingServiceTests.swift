import XCTest
@testable import Dirt

class ReportingServiceTests: XCTestCase {
    
    var reportingService: ReportingService!
    
    override func setUp() {
        super.setUp()
        reportingService = ReportingService.shared
        
        // Clear existing reports for clean tests
        reportingService.reports.removeAll()
    }
    
    override func tearDown() {
        reportingService.reports.removeAll()
        reportingService = nil
        super.tearDown()
    }
    
    // MARK: - Report Submission Tests
    
    func testSubmitValidReport() async {
        let contentId = UUID()
        let reporterId = UUID()
        
        let result = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment,
            additionalDetails: "This content contains harassment",
            isAnonymous: false
        )
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.reportId)
        XCTAssertNil(result.error)
        
        let reports = reportingService.getReportsForContent(contentId: contentId)
        XCTAssertEqual(reports.count, 1)
        
        let report = reports.first!
        XCTAssertEqual(report.contentId, contentId)
        XCTAssertEqual(report.contentType, .post)
        XCTAssertEqual(report.reporterId, reporterId)
        XCTAssertEqual(report.reason, .harassment)
        XCTAssertEqual(report.additionalDetails, "This content contains harassment")
        XCTAssertFalse(report.isAnonymous)
        XCTAssertEqual(report.status, .pending)
    }
    
    func testSubmitAnonymousReport() async {
        let contentId = UUID()
        
        let result = await reportingService.submitReport(
            contentId: contentId,
            contentType: .review,
            reporterId: nil,
            reason: .spam,
            isAnonymous: true
        )
        
        XCTAssertTrue(result.success)
        
        let reports = reportingService.getReportsForContent(contentId: contentId)
        XCTAssertEqual(reports.count, 1)
        
        let report = reports.first!
        XCTAssertNil(report.reporterId)
        XCTAssertTrue(report.isAnonymous)
    }
    
    func testSubmitDuplicateReport() async {
        let contentId = UUID()
        let reporterId = UUID()
        
        // Submit first report
        let firstResult = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment
        )
        
        XCTAssertTrue(firstResult.success)
        
        // Submit duplicate report (same user, same content, same reason, same day)
        let duplicateResult = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment
        )
        
        XCTAssertFalse(duplicateResult.success)
        XCTAssertNotNil(duplicateResult.error)
        XCTAssertTrue(duplicateResult.error?.contains("already reported") == true)
    }
    
    // MARK: - Report Retrieval Tests
    
    func testGetReportsForContent() async {
        let contentId = UUID()
        let reporterId1 = UUID()
        let reporterId2 = UUID()
        
        // Submit multiple reports for the same content
        await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId1,
            reason: .harassment
        )
        
        await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId2,
            reason: .spam
        )
        
        let reports = reportingService.getReportsForContent(contentId: contentId)
        XCTAssertEqual(reports.count, 2)
        XCTAssertTrue(reports.allSatisfy { $0.contentId == contentId })
    }
    
    func testGetReportsByUser() async {
        let reporterId = UUID()
        let contentId1 = UUID()
        let contentId2 = UUID()
        
        // Submit multiple reports by the same user
        await reportingService.submitReport(
            contentId: contentId1,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment
        )
        
        await reportingService.submitReport(
            contentId: contentId2,
            contentType: .review,
            reporterId: reporterId,
            reason: .spam
        )
        
        let userReports = reportingService.getReportsByUser(userId: reporterId)
        XCTAssertEqual(userReports.count, 2)
        XCTAssertTrue(userReports.allSatisfy { $0.reporterId == reporterId })
    }
    
    func testGetPendingReports() async {
        let contentId1 = UUID()
        let contentId2 = UUID()
        let moderatorId = UUID()
        
        // Submit reports
        let result1 = await reportingService.submitReport(
            contentId: contentId1,
            contentType: .post,
            reporterId: UUID(),
            reason: .harassment
        )
        
        let result2 = await reportingService.submitReport(
            contentId: contentId2,
            contentType: .post,
            reporterId: UUID(),
            reason: .spam
        )
        
        // Review one report
        await reportingService.reviewReport(
            reportId: result1.reportId!,
            moderatorId: moderatorId,
            resolution: .actionTaken
        )
        
        let pendingReports = reportingService.getPendingReports()
        XCTAssertEqual(pendingReports.count, 1)
        XCTAssertEqual(pendingReports.first?.contentId, contentId2)
    }
    
    // MARK: - Report Review Tests
    
    func testReviewReportActionTaken() async {
        let contentId = UUID()
        let reporterId = UUID()
        let moderatorId = UUID()
        
        let result = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment
        )
        
        let reviewSuccess = await reportingService.reviewReport(
            reportId: result.reportId!,
            moderatorId: moderatorId,
            resolution: .actionTaken,
            notes: "Content removed for harassment"
        )
        
        XCTAssertTrue(reviewSuccess)
        
        let reports = reportingService.getReportsForContent(contentId: contentId)
        let reviewedReport = reports.first!
        
        XCTAssertEqual(reviewedReport.status, .reviewed)
        XCTAssertEqual(reviewedReport.resolution, .actionTaken)
        XCTAssertEqual(reviewedReport.reviewedBy, moderatorId)
        XCTAssertEqual(reviewedReport.resolutionNotes, "Content removed for harassment")
        XCTAssertNotNil(reviewedReport.reviewedAt)
    }
    
    func testReviewReportFalseReport() async {
        let contentId = UUID()
        let reporterId = UUID()
        let moderatorId = UUID()
        
        let result = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment
        )
        
        let reviewSuccess = await reportingService.reviewReport(
            reportId: result.reportId!,
            moderatorId: moderatorId,
            resolution: .falseReport,
            notes: "Report was not valid"
        )
        
        XCTAssertTrue(reviewSuccess)
        
        let reports = reportingService.getReportsForContent(contentId: contentId)
        let reviewedReport = reports.first!
        
        XCTAssertEqual(reviewedReport.resolution, .falseReport)
    }
    
    func testReviewNonexistentReport() async {
        let nonexistentReportId = UUID()
        let moderatorId = UUID()
        
        let reviewSuccess = await reportingService.reviewReport(
            reportId: nonexistentReportId,
            moderatorId: moderatorId,
            resolution: .actionTaken
        )
        
        XCTAssertFalse(reviewSuccess)
    }
    
    // MARK: - Reporting Limits Tests
    
    func testReportingLimitsNormalUser() {
        let userId = UUID()
        
        let limitStatus = reportingService.checkReportingLimits(userId: userId)
        
        XCTAssertTrue(limitStatus.canReport)
        XCTAssertEqual(limitStatus.remainingReports, 10) // Daily limit
        XCTAssertEqual(limitStatus.dailyLimit, 10)
        XCTAssertFalse(limitStatus.isAbusive)
        XCTAssertEqual(limitStatus.falseReportRate, 0.0)
    }
    
    func testReportingLimitsExceeded() async {
        let userId = UUID()
        let contentId = UUID()
        
        // Submit maximum reports for the day
        for i in 0..<10 {
            await reportingService.submitReport(
                contentId: UUID(),
                contentType: .post,
                reporterId: userId,
                reason: .spam
            )
        }
        
        let limitStatus = reportingService.checkReportingLimits(userId: userId)
        
        XCTAssertFalse(limitStatus.canReport)
        XCTAssertEqual(limitStatus.remainingReports, 0)
    }
    
    // MARK: - Analytics Tests
    
    func testGetReportingAnalytics() async {
        let contentId1 = UUID()
        let contentId2 = UUID()
        let reporterId1 = UUID()
        let reporterId2 = UUID()
        let moderatorId = UUID()
        
        // Submit various reports
        let result1 = await reportingService.submitReport(
            contentId: contentId1,
            contentType: .post,
            reporterId: reporterId1,
            reason: .harassment
        )
        
        let result2 = await reportingService.submitReport(
            contentId: contentId2,
            contentType: .review,
            reporterId: reporterId2,
            reason: .spam,
            isAnonymous: true
        )
        
        // Review one report
        await reportingService.reviewReport(
            reportId: result1.reportId!,
            moderatorId: moderatorId,
            resolution: .actionTaken
        )
        
        let analytics = await reportingService.getReportingAnalytics(timeRange: .day)
        
        XCTAssertEqual(analytics.timeRange, .day)
        XCTAssertEqual(analytics.totalReports, 2)
        XCTAssertEqual(analytics.uniqueContentReported, 2)
        XCTAssertEqual(analytics.uniqueReporters, 1) // One anonymous report
        XCTAssertEqual(analytics.anonymousReports, 1)
        
        XCTAssertEqual(analytics.reasonDistribution[.harassment], 1)
        XCTAssertEqual(analytics.reasonDistribution[.spam], 1)
        
        XCTAssertEqual(analytics.resolutionDistribution[.actionTaken], 1)
        
        XCTAssertGreaterThanOrEqual(analytics.averageResolutionTimeHours, 0)
    }
    
    func testGetMultipleReportedContent() async {
        let contentId = UUID()
        
        // Submit multiple reports for the same content
        for i in 0..<5 {
            await reportingService.submitReport(
                contentId: contentId,
                contentType: .post,
                reporterId: UUID(),
                reason: .harassment
            )
        }
        
        let multipleReported = reportingService.getMultipleReportedContent(threshold: 3)
        
        XCTAssertEqual(multipleReported.count, 1)
        
        let reportedContent = multipleReported.first!
        XCTAssertEqual(reportedContent.contentId, contentId)
        XCTAssertEqual(reportedContent.totalReports, 5)
        XCTAssertEqual(reportedContent.pendingReports, 5)
        XCTAssertEqual(reportedContent.mostCommonReason, .harassment)
    }
    
    func testGetMultipleReportedContentBelowThreshold() async {
        let contentId = UUID()
        
        // Submit only 2 reports (below threshold of 3)
        for i in 0..<2 {
            await reportingService.submitReport(
                contentId: contentId,
                contentType: .post,
                reporterId: UUID(),
                reason: .spam
            )
        }
        
        let multipleReported = reportingService.getMultipleReportedContent(threshold: 3)
        
        XCTAssertTrue(multipleReported.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteReportingWorkflow() async {
        let contentId = UUID()
        let reporterId = UUID()
        let moderatorId = UUID()
        
        // 1. Submit report
        let submitResult = await reportingService.submitReport(
            contentId: contentId,
            contentType: .post,
            reporterId: reporterId,
            reason: .harassment,
            additionalDetails: "User is being harassed in comments"
        )
        
        XCTAssertTrue(submitResult.success)
        XCTAssertNotNil(submitResult.reportId)
        
        // 2. Verify report is pending
        let pendingReports = reportingService.getPendingReports()
        XCTAssertEqual(pendingReports.count, 1)
        XCTAssertEqual(pendingReports.first?.id, submitResult.reportId)
        
        // 3. Review report
        let reviewResult = await reportingService.reviewReport(
            reportId: submitResult.reportId!,
            moderatorId: moderatorId,
            resolution: .actionTaken,
            notes: "Content removed and user warned"
        )
        
        XCTAssertTrue(reviewResult)
        
        // 4. Verify report is no longer pending
        let remainingPendingReports = reportingService.getPendingReports()
        XCTAssertTrue(remainingPendingReports.isEmpty)
        
        // 5. Verify report status updated
        let reports = reportingService.getReportsForContent(contentId: contentId)
        let reviewedReport = reports.first!
        
        XCTAssertEqual(reviewedReport.status, .reviewed)
        XCTAssertEqual(reviewedReport.resolution, .actionTaken)
        XCTAssertEqual(reviewedReport.reviewedBy, moderatorId)
        XCTAssertNotNil(reviewedReport.reviewedAt)
    }
    
    func testMultipleReportsAutomaticActions() async {
        let contentId = UUID()
        
        // Submit multiple reports to trigger automatic actions
        for i in 0..<6 {
            await reportingService.submitReport(
                contentId: contentId,
                contentType: .post,
                reporterId: UUID(),
                reason: .harassment
            )
        }
        
        // Verify content appears in multiple reported list
        let multipleReported = reportingService.getMultipleReportedContent(threshold: 5)
        XCTAssertEqual(multipleReported.count, 1)
        XCTAssertEqual(multipleReported.first?.contentId, contentId)
        XCTAssertEqual(multipleReported.first?.totalReports, 6)
    }
}

// MARK: - Performance Tests

extension ReportingServiceTests {
    
    func testReportSubmissionPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Report submission performance")
            
            Task {
                for _ in 0..<10 {
                    _ = await reportingService.submitReport(
                        contentId: UUID(),
                        contentType: .post,
                        reporterId: UUID(),
                        reason: .spam
                    )
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testAnalyticsPerformance() {
        // Add many reports first
        let expectation1 = XCTestExpectation(description: "Add reports")
        
        Task {
            for _ in 0..<100 {
                _ = await reportingService.submitReport(
                    contentId: UUID(),
                    contentType: .post,
                    reporterId: UUID(),
                    reason: ReportReason.allCases.randomElement()!
                )
            }
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 10.0)
        
        // Measure analytics performance
        measure {
            let expectation2 = XCTestExpectation(description: "Analytics performance")
            
            Task {
                _ = await reportingService.getReportingAnalytics(timeRange: .month)
                expectation2.fulfill()
            }
            
            wait(for: [expectation2], timeout: 5.0)
        }
    }
}