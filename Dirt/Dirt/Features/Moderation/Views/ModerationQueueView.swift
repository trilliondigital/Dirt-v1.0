import SwiftUI

struct ModerationQueueView: View {
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.services) private var services
    @State private var reports: [ReportRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: ReportStatus? = .pending

    var body: some View {
        VStack(spacing: 8) {
            // Status filter
            Picker("Status", selection: Binding(
                get: { selectedFilter ?? ReportStatus.pending },
                set: { selectedFilter = $0 }
            )) {
                Text("Pending").tag(ReportStatus.pending)
                Text("Reviewed").tag(ReportStatus.reviewed)
                Text("Actioned").tag(ReportStatus.actioned)
                Text("Dismissed").tag(ReportStatus.dismissed)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .accessibilityLabel(Text("Status"))

            List {
                if let errorMessage = errorMessage {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Button("Retry") { Task { await load() } }
                                .buttonStyle(.bordered)
                                .accessibilityLabel(Text("Retry"))
                        }
                        .padding(.vertical, 8)
                    }
                }

                ForEach(filteredReports()) { report in
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
            .listStyle(PlainListStyle())
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
            reports = try await services.moderationService.fetchQueue(page: 1, pageSize: 25)
            isLoading = false
            toastCenter.show(.info, NSLocalizedString("Queue updated", comment: ""))
            services.analyticsService.log("moderation_queue_loaded", ["count": "\(reports.count)"])
        } catch {
            errorMessage = services.errorPresenter.message(for: error)
            isLoading = false
            HapticFeedback.notification(type: .error)
            toastCenter.show(.error, errorMessage ?? NSLocalizedString("Something went wrong. Please try again.", comment: ""))
            services.analyticsService.log("moderation_queue_load_failed")
        }
    }

    @MainActor
    private func update(reportId: UUID, status: ReportStatus) async {
        // Optimistic update with rollback on failure
        guard let idx = reports.firstIndex(where: { $0.id == reportId }) else { return }
        let original = reports[idx]
        reports[idx].status = status
        do {
            let server = try await services.moderationService.updateReportStatus(reportId: reportId, status: status)
            reports[idx] = server
            HapticFeedback.notification(type: .success)
            let msg = String(format: NSLocalizedString("Marked %@", comment: ""), status.rawValue)
            toastCenter.show(.success, msg)
            services.analyticsService.log("moderation_update_success", ["status": status.rawValue])
        } catch {
            reports[idx] = original
            errorMessage = services.errorPresenter.message(for: error)
            HapticFeedback.notification(type: .error)
            toastCenter.show(.error, errorMessage ?? NSLocalizedString("Something went wrong. Please try again.", comment: ""))
            services.analyticsService.log("moderation_update_failed", ["status": status.rawValue])
        }
    }

    private func filteredReports() -> [ReportRecord] {
        guard let filter = selectedFilter else { return reports }
        // If "All" is desired, set selectedFilter to nil externally.
        return reports.filter { $0.status == filter }
    }
}

private struct ReportRow: View {
    let report: ReportRecord
    var onAction: (ReportStatus) -> Void
    @Environment(\.services) private var services
    @State private var preview: PostDetailData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Post \(report.postId.uuidString.prefix(8)) • \(report.reason)")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("\(report.createdAt, style: .relative) • status: \(report.status.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let preview {
                        Text(preview.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Loading preview…")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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
        .task {
            if preview == nil {
                preview = try? await services.postService.fetchPost(by: report.postId)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Post \(report.postId.uuidString.prefix(8))"))
    }
}

struct ModerationQueueView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ModerationQueueView() }
    }
}
