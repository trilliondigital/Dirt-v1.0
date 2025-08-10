import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @State private var page = 0
    @State private var email: String = ""
    @State private var showDone = false
    @State private var selectedInterests: Set<ControlledTag> = []
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var onComplete: (() -> Void)?

    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $page) {
                    purposeView
                        .tag(0)
                    authView
                        .tag(1)
                    interestsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                HStack {
                    if page > 0 {
                        Button("Back") { withAnimation { page -= 1 } }
                    }
                    Spacer()
                    Button(page == 2 ? "Get Started" : "Next") {
                        if page < 2 {
                            withAnimation { page += 1 }
                        } else {
                            showDone = true
                            onboardingCompleted = true
                            onComplete?()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if page < 2 {
                        Button("Skip") {
                            onboardingCompleted = true
                            onComplete?()
                        }
                    }
                }
            }
            .alert("Welcome to Dirt", isPresented: $showDone) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You're set. You can change interests later.")
            }
        }
    }

    private var purposeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Purpose & Community Rules")
                    .font(.title2).bold()
                Text("Dirt helps men share and discover dating insights with privacy-first defaults. Be respectful and constructive.")
                VStack(alignment: .leading, spacing: 8) {
                    Label("No doxxing or PII.", systemImage: "checkmark.seal")
                    Label("Report harmful content.", systemImage: "flag")
                    Label("Blurred media by default.", systemImage: "eye.slash")
                    Label("Select Red/Green signals honestly.", systemImage: "hand.thumbsup")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                Spacer(minLength: 12)
                Text("By continuing you agree to the community rules.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    private var authView: some View {
        VStack(spacing: 16) {
            Text("Sign In")
                .font(.title2).bold()
            Text("Anonymous-first. Use Apple for privacy or email as fallback.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Apple Sign In (stub)
            SignInWithAppleButton(.continue) { request in
                // Configure request scopes if needed
            } onCompletion: { result in
                // Handle success/failure (stub)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .cornerRadius(8)
            .padding(.horizontal)

            // Email fallback (stub)
            HStack {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(.roundedBorder)
                Button("Send Link") {
                    // Stub: send magic link
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private var interestsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick a few interests (optional)")
                    .font(.title3).bold()
                FlowLayout(TagCatalog.all, spacing: 8) { tag in
                    let isOn = selectedInterests.contains(tag)
                    Text(tag.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isOn ? Color.blue.opacity(0.15) : Color(.systemGray6))
                        .cornerRadius(16)
                        .onTapGesture {
                            if isOn { selectedInterests.remove(tag) } else { selectedInterests.insert(tag) }
                        }
                }
                Spacer(minLength: 12)
                Text("These help personalize your Feed.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
