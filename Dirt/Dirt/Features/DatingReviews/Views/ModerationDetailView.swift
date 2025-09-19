import SwiftUI

struct ModerationDetailView: View {
    let queueItem: ModerationQueueItem
    
    @StateObject private var queueService = ModerationQueueService.shared
    @StateObject private var moderationService = ModerationService()
    
    @State private var selectedAction: ModerationActionType?
    @State private var actionReason = ""
    @State private var actionNotes = ""
    @State private var showingActionSheet = false
    @State private var showingUserProfile = false
    @State private var showingAppealDialog = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Content header
                contentHeaderView
                
                // Content display
                contentDisplayView
                
                // Moderation analysis
                moderationAnalysisView
                
                // PII detection results
                if !queueItem.moderationResult.detectedPII.isEmpty {
                    piiDetectionView
                }
                
                // User context
                userContextView
                
                // Action buttons
                actionButtonsView
            }
            .padding()
        }
        .navigationTitle("Content Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu("Actions") {
                    Button("View User Profile") {
                        showingUserProfile = true
                    }
                    
                    Button("View Content History") {
                        // Navigate to user's content history
                    }
                    
                    Button("Appeal Process") {
                        showingAppealDialog = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView(userId: queueItem.authorId)
        }
        .alert("Appeal Process", isPresented: $showingAppealDialog) {
            Button("Start Appeal") {
                startAppealProcess()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will start the appeal process for this content moderation decision.")
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Moderation Action"),
                message: Text("Choose an action for this content"),
                buttons: [
                    .default(Text("Approve")) {
                        selectedAction = .approve
                        performModerationAction()
                    },
                    .destructive(Text("Reject")) {
                        selectedAction = .reject
                        performModerationAction()
                    },
                    .default(Text("Flag for Review")) {
                        selectedAction = .flag
                        performModerationAction()
                    },
                    .default(Text("Edit Content")) {
                        selectedAction = .edit
                        // Show edit interface
                    },
                    .destructive(Text("Ban User")) {
                        selectedAction = .ban
                        performModerationAction()
                    },
                    .default(Text("Warn User")) {
                        selectedAction = .warn
                        performModerationAction()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - Content Header
    
    private var contentHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PriorityBadge(priority: queueItem.priority)
                
                Spacer()
                
                Text(queueItem.contentType.rawValue.capitalized)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(queueItem.createdAt, style: .date)
                        .font(.body)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(queueItem.reportCount)")
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Content Display
    
    private var contentDisplayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
            
            if let content = queueItem.content {
                Text(content)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            // Display images if any
            if !queueItem.imageUrls.isEmpty {
                Text("Images (\(queueItem.imageUrls.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(queueItem.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.secondary)
                                    )
                            }
                            .frame(width: 120, height: 120)
                            .cornerRadius(8)
                            .clipped()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Moderation Analysis
    
    private var moderationAnalysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Confidence:")
                    Spacer()
                    Text("\(Int(queueItem.moderationResult.confidence * 100))%")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Severity:")
                    Spacer()
                    Text(queueItem.moderationResult.severity.rawValue.capitalized)
                        .fontWeight(.medium)
                        .foregroundColor(severityColor(queueItem.moderationResult.severity))
                }
                
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(queueItem.moderationResult.status.rawValue.capitalized)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(queueItem.moderationResult.status))
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(8)
            
            // Detected flags
            if !queueItem.moderationResult.flags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Violations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(queueItem.moderationResult.flags, id: \.self) { flag in
                            HStack {
                                Image(systemName: flagIcon(for: flag))
                                    .foregroundColor(flagColor(for: flag))
                                
                                Text(flag.description)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(flagColor(for: flag).opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
            
            // AI reason
            if let reason = queueItem.moderationResult.reason {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Reasoning")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - PII Detection View
    
    private var piiDetectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Personal Information Detected")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            ForEach(queueItem.moderationResult.detectedPII, id: \.text) { pii in
                HStack {
                    VStack(alignment: .leading) {
                        Text(pii.type.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let text = pii.text {
                            Text(text)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(Int(pii.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - User Context
    
    private var userContextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Context")
                .font(.headline)
            
            HStack {
                Button("View Profile") {
                    showingUserProfile = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("User ID")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(queueItem.authorId.uuidString.prefix(8))
                        .font(.caption)
                        .fontFamily(.monospaced)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Quick actions
            HStack(spacing: 12) {
                Button("Approve") {
                    selectedAction = .approve
                    actionReason = "Content approved by human moderator"
                    performModerationAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("Reject") {
                    selectedAction = .reject
                    actionReason = "Content rejected by human moderator"
                    performModerationAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            // More actions
            Button("More Actions") {
                showingActionSheet = true
            }
            .buttonStyle(.bordered)
            
            // Action reason input
            VStack(alignment: .leading, spacing: 8) {
                Text("Action Reason")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter reason for action...", text: $actionReason)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Additional notes (optional)", text: $actionNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func severityColor(_ severity: ModerationSeverity) -> Color {
        switch severity {
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
    
    private func statusColor(_ status: ModerationStatus) -> Color {
        switch status {
        case .approved:
            return .green
        case .rejected:
            return .red
        case .flagged:
            return .orange
        case .pending:
            return .blue
        case .appealed:
            return .purple
        case .underReview:
            return .yellow
        }
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
    
    private func flagIcon(for flag: ModerationFlag) -> String {
        switch flag {
        case .personalInformation:
            return "person.fill.xmark"
        case .inappropriateContent:
            return "exclamationmark.triangle"
        case .spam:
            return "envelope.badge.fill"
        case .harassment:
            return "person.2.slash"
        case .violentContent:
            return "hand.raised.fill"
        case .hateSpeech:
            return "bubble.left.and.exclamationmark.bubble.right"
        case .sexualContent:
            return "eye.slash"
        case .misinformation:
            return "questionmark.circle"
        case .copyrightViolation:
            return "c.circle"
        case .other:
            return "exclamationmark.circle"
        }
    }
    
    private func performModerationAction() {
        guard let action = selectedAction else { return }
        
        Task {
            await queueService.updateQueueItem(
                itemId: queueItem.id,
                action: action,
                moderatorId: UUID(), // Current moderator ID
                reason: actionReason.isEmpty ? "No reason provided" : actionReason,
                notes: actionNotes.isEmpty ? nil : actionNotes
            )
            
            // Navigate back after action
            await MainActor.run {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func startAppealProcess() {
        // In production, this would start the appeal workflow
        print("Starting appeal process for content: \(queueItem.contentId)")
    }
}

// MARK: - Supporting Views

struct UserProfileView: View {
    let userId: UUID
    
    var body: some View {
        NavigationView {
            VStack {
                Text("User Profile")
                    .font(.title)
                
                Text("User ID: \(userId.uuidString)")
                    .font(.caption)
                    .fontFamily(.monospaced)
                
                // In production, this would show actual user profile data
                Text("User profile information would be displayed here")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct ModerationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockResult = ModerationResult(
            contentId: UUID(),
            contentType: .post,
            status: .pending,
            flags: [.inappropriateContent, .personalInformation],
            confidence: 0.85,
            severity: .high,
            reason: "Inappropriate content and personal information detected",
            detectedPII: [
                PIIDetection(
                    type: .phoneNumber,
                    location: CGRect.zero,
                    confidence: 0.9,
                    text: "555-123-4567"
                )
            ],
            createdAt: Date(),
            reviewedAt: nil,
            reviewedBy: nil,
            notes: nil
        )
        
        let mockItem = ModerationQueueItem(
            id: UUID(),
            contentId: UUID(),
            contentType: .post,
            authorId: UUID(),
            content: "This is some problematic content that needs moderation review. Contact me at 555-123-4567.",
            imageUrls: [],
            moderationResult: mockResult,
            reportCount: 2,
            priority: .high,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        NavigationView {
            ModerationDetailView(queueItem: mockItem)
        }
    }
}