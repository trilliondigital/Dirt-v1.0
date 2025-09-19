import SwiftUI

struct ReportSheet: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalInfo = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Report Post")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help us keep the community safe by reporting content that violates our guidelines.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Post Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reporting:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text(post.content)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Report Reasons
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why are you reporting this post?")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                ReportReasonRow(
                                    reason: reason,
                                    isSelected: selectedReason == reason,
                                    action: { selectedReason = reason }
                                )
                            }
                        }
                    }
                    
                    // Additional Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Information")
                            .font(.headline)
                        
                        Text("Provide any additional context that might help us understand the issue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Optional: Provide more details...", text: $additionalInfo, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(4...8)
                    }
                    
                    // Warning
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Important")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("False reports may result in restrictions on your account. Only report content that genuinely violates our community guidelines.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Submitting report...")
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        )
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        Task {
            // Simulate API call
            await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // TODO: Submit report to backend
            print("Reporting post '\(post.title)' for: \(reason.rawValue)")
            if !additionalInfo.isEmpty {
                print("Additional info: \(additionalInfo)")
            }
            
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
        }
    }
}

#Preview {
    ReportSheet(
        post: Post(
            authorId: UUID(),
            title: "Sample Post Title",
            content: "This is a sample post content that might be reported for various reasons.",
            category: .general,
            sentiment: .neutral
        )
    )
}