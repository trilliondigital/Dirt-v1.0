import SwiftUI

struct LookupWizardView: View {
    @State private var step: Int = 1
    
    // Step 1 inputs
    @State private var phoneNumber: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    
    // Step 2 results (placeholder)
    @State private var premiumLocked: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            Text("Step \(step) of 2")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 6)
            
            if step == 1 { stepOne }
            else { stepTwo }
        }
        .navigationTitle(step == 1 ? "Lookup" : "Lookup Results")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { footer }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private var stepOne: some View {
        Form {
            Section(footer: Text("Use responsibly. No doxxing or sharing of private information."
                                 ).font(.caption).foregroundColor(.secondary)) {
                TextField("Phone Number (optional)", text: $phoneNumber)
                    .keyboardType(.numberPad)
                TextField("First Name (optional)", text: $firstName)
                TextField("Last Name (optional)", text: $lastName)
            }
        }
    }
    
    private var stepTwo: some View {
        List {
            Section(header: Text("Summary")) {
                Label("Reverse image search", systemImage: "person.crop.square")
                    .foregroundColor(.primary)
                Label("Background check", systemImage: "doc.text.magnifyingglass")
                    .foregroundColor(.secondary)
                Label("Known aliases", systemImage: "person.2")
                HStack {
                    Text("Warnings")
                    Spacer()
                    ForEach(["Linked IG", "Possible mismatch"], id: \.self) { chip in
                        Text(chip)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            
            Section(header: Text("Details")) {
                NavigationLink(destination: Text("Public Profiles")) {
                    HStack { Text("Public profiles"); Spacer(); Image(systemName: "chevron.right").foregroundColor(.tertiaryLabel) }
                }
                NavigationLink(destination: Text("Mentions in Posts")) {
                    HStack { Text("Mentions in posts"); Spacer(); Image(systemName: "chevron.right").foregroundColor(.tertiaryLabel) }
                }
                NavigationLink(destination: Text("Community Flags")) {
                    HStack { Text("Community flags"); Spacer(); Image(systemName: "chevron.right").foregroundColor(.tertiaryLabel) }
                }
            }
            
            if premiumLocked {
                Section(footer: Text("Unlock detailed results with Dirt+ to support moderation and safety.")) {
                    Button {
                        // Upsell action
                    } label: {
                        Label("Unlock detailed results — $14.99/mo", systemImage: "lock.fill")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var footer: some View {
        HStack(spacing: 12) {
            if step == 1 {
                Button("Learn more") { /* open docs */ }
                    .buttonStyle(.bordered)
                Button("Continue") { withAnimation { step = 2 } }
                    .buttonStyle(.borderedProminent)
                    .disabled(phoneNumber.isEmpty && firstName.isEmpty && lastName.isEmpty)
            } else {
                Button("Start new lookup") { withAnimation { step = 1; phoneNumber.removeAll(); firstName.removeAll(); lastName.removeAll() } }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

struct LookupWizardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { LookupWizardView() }
    }
}
