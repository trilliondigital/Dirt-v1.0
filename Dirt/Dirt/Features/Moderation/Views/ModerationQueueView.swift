import SwiftUI

struct ModerationQueueView: View {
    @State private var reports: [ReportRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage = errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
            }

            ForEach(reports) { report in
                NavigationLink(destination: PostDetailLoaderView(postId: report.postId)) {
                    ReportRow(report: report, onAction: { status in
                        HapticFeedback.impact(style: .light)
                        Task { await update(reportId: report.id, status: status) }
                    })
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
        .overlay {
            if isLoading {
                ProgressView().controlSize(.regular)
            } else if reports.isEmpty && errorMessage == nil {
                VStack(spacing: 8) {
                    Image(systemName: "tray").foregroundColor(.gray)
                    Text("No reports in queue").foregroundColor(.gray)
                }
            }
        }
        .refreshable { await load() }
        .navigationTitle("Moderation Queue")
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            reports = try await ModerationService.shared.fetchQueue(page: 1, pageSize: 25)
            isLoading = false
        } catch {
            errorMessage = "Failed to fetch queue"
            isLoading = false
        }
    }

    @MainActor
    private func update(reportId: UUID, status: ReportStatus) async {
        do {
            let updated = try await ModerationService.shared.updateReportStatus(reportId: reportId, status: status)
            if let idx = reports.firstIndex(where: { $0.id == reportId }) {
                reports[idx] = updated
            }
        } catch {
            errorMessage = "Failed to update status"
        }
    }
}

private struct ReportRow: View {
    let report: ReportRecord
    var onAction: (ReportStatus) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Post \(report.postId.uuidString.prefix(8)) • \(report.reason)")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("\(report.createdAt, style: .relative) • status: \(report.status.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Menu {
                    Button("Mark Reviewed") { onAction(.reviewed) }
                    Button("Mark Actioned") { onAction(.actioned) }
                    Button("Dismiss") { onAction(.dismissed) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button("Reviewed") { onAction(.reviewed) }
                Button("Actioned") { onAction(.actioned) }
                Button("Dismiss") { onAction(.dismissed) }
            }
        }
        .padding()
        .cardBackground()
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct ModerationQueueView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ModerationQueueView() }
    }
}
