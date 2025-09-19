import SwiftUI

struct CommentCard: View {
    let comment: Comment
    @State private var hasUpvoted = false
    @State private var showingReportSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Comment Header
            HStack(spacing: 12) {
                // Author Avatar
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(comment.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // More actions
                Menu {
                    Button("Report Comment", role: .destructive) {
                        showingReportSheet = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Comment Content
            Text(comment.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Comment Actions
            HStack(spacing: 16) {
                // Upvote
                Button(action: { hasUpvoted.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: hasUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                            .font(.subheadline)
                        Text("\(comment.upvotes)")
                            .font(.caption)
                    }
                    .foregroundColor(hasUpvoted ? .green : .secondary)
                }
                
                // Reply (placeholder)
                Button("Reply") {
                    // TODO: Implement reply functionality
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingReportSheet) {
            ReportCommentSheet(comment: comment)
        }
    }
}

// MARK: - Report Comment Sheet
struct ReportCommentSheet: View {
    let comment: Comment
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalInfo = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Why are you reporting this comment?")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        ReportReasonRow(
                            reason: reason,
                            isSelected: selectedReason == reason,
                            action: { selectedReason = reason }
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Information (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Provide more details...", text: $additionalInfo, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                Button("Submit Report") {
                    submitReport()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(selectedReason == nil)
            }
            .padding()
            .navigationTitle("Report Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func submitReport() {
        // TODO: Submit report to backend
        print("Reporting comment for: \(selectedReason?.rawValue ?? "unknown")")
        dismiss()
    }
}

enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment"
    case inappropriate = "Inappropriate Content"
    case misinformation = "Misinformation"
    case other = "Other"
    
    var description: String {
        switch self {
        case .spam:
            return "Repetitive or promotional content"
        case .harassment:
            return "Bullying or targeted harassment"
        case .inappropriate:
            return "Offensive or inappropriate content"
        case .misinformation:
            return "False or misleading information"
        case .other:
            return "Other reason not listed above"
        }
    }
}

struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: isSelected ? 0 : 1)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(reason.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            CommentCard(
                comment: Comment(
                    postId: UUID(),
                    authorId: UUID(),
                    content: "Great story! Thanks for sharing your experience. This really gives me hope for my own dating journey.",
                    upvotes: 5
                )
            )
            
            CommentCard(
                comment: Comment(
                    postId: UUID(),
                    authorId: UUID(),
                    content: "What app did you use? I'm curious about your approach.",
                    createdAt: Date().addingTimeInterval(-3600),
                    upvotes: 2
                )
            )
        }
        .padding()
    }
}