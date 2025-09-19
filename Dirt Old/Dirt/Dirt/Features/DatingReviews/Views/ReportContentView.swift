import SwiftUI

struct ReportContentView: View {
    let contentId: UUID
    let contentType: ContentType
    let contentPreview: String?
    
    @StateObject private var reportingService = ReportingService.shared
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isAnonymous = true
    @State private var isSubmitting = false
    @State private var showingConfirmation = false
    @State private var submissionResult: ReportSubmissionResult?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content preview
                    contentPreviewSection
                    
                    // Report reason selection
                    reportReasonSection
                    
                    // Additional details
                    additionalDetailsSection
                    
                    // Anonymous reporting toggle
                    anonymousReportingSection
                    
                    // Submit button
                    submitButtonSection
                }
                .padding()
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showingConfirmation) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                if let result = submissionResult {
                    if result.success {
                        Text("Thank you for your report. Our moderation team will review it shortly.")
                    } else {
                        Text(result.error ?? "Failed to submit report. Please try again.")
                    }
                }
            }
        }
    }
    
    // MARK: - Content Preview Section
    
    private var contentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Being Reported")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(contentType.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                if let preview = contentPreview {
                    Text("Preview:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(preview)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .lineLimit(5)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Report Reason Section
    
    private var reportReasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why are you reporting this content?")
                .font(.headline)
            
            Text("Select the reason that best describes the issue:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                ForEach(ReportReason.allCases, id: \.self) { reason in
                    ReportReasonRow(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        onTap: {
                            selectedReason = reason
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Additional Details Section
    
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Details (Optional)")
                .font(.headline)
            
            Text("Provide any additional context that might help our moderation team:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(
                "Describe the issue in more detail...",
                text: $additionalDetails,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(5...10)
        }
    }
    
    // MARK: - Anonymous Reporting Section
    
    private var anonymousReportingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reporting Options")
                .font(.headline)
            
            Toggle(isOn: $isAnonymous) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Submit Anonymously")
                        .font(.body)
                    
                    Text("Your identity will not be shared with anyone, including moderators")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Submit Button Section
    
    private var submitButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: submitReport) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Submit Report")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? Color.red : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canSubmit || isSubmitting)
            
            // Reporting guidelines
            VStack(alignment: .leading, spacing: 8) {
                Text("Reporting Guidelines")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
   