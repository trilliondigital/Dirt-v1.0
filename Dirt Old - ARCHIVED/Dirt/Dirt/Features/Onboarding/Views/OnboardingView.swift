import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject private var supabase: SupabaseManager
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.services) private var services
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
                        GlassButton(
                            "Back",
                            style: .secondary
                        ) {
                            withAnimation(MaterialMotion.Spring.standard) { 
                                page -= 1 
                            }
                        }
                    }
                    
                    Spacer()
                    
                    GlassButton(
                        page == 2 ? "Get Started" : "Next",
                        style: .primary
                    ) {
                        if page < 2 {
                            withAnimation(MaterialMotion.Spring.standard) { 
                                page += 1 
                            }
                        } else {
                            Task {
                                do {
                                    try await services.interestsService.save(interests: Array(selectedInterests).map { $0.rawValue })
                                } catch {
                                    // non-fatal
                                }
                                showDone = true
                                onboardingCompleted = true
                                onComplete?()
                                MaterialHaptics.success()
                                toastCenter.show(.success, "You're set!")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .background(MaterialDesignSystem.Context.navigation.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if page < 2 {
                        GlassButton(
                            "Skip",
                            style: .subtle
                        ) {
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
            VStack(spacing: UISpacing.lg) {
                GlassCard(
                    material: MaterialDesignSystem.Context.card,
                    padding: UISpacing.lg
                ) {
                    VStack(alignment: .leading, spacing: UISpacing.md) {
                        Text("Purpose & Community Rules")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                        
                        Text("Dirt helps men share and discover dating insights with privacy-first defaults. Be respectful and constructive.")
                            .font(.subheadline)
                            .foregroundColor(UIColors.secondaryLabel)
                        
                        VStack(alignment: .leading, spacing: UISpacing.xs) {
                            Label("No doxxing or PII.", systemImage: "checkmark.seal")
                                .foregroundColor(UIColors.success)
                            Label("Report harmful content.", systemImage: "flag")
                                .foregroundColor(UIColors.warning)
                            Label("Blurred media by default.", systemImage: "eye.slash")
                                .foregroundColor(UIColors.accentPrimary)
                            Label("Select Red/Green signals honestly.", systemImage: "hand.thumbsup")
                                .foregroundColor(UIColors.accentSecondary)
                        }
                        .font(.subheadline)
                        
                        Text("By continuing you agree to the community rules.")
                            .font(.footnote)
                            .foregroundColor(UIColors.secondaryLabel)
                            .padding(.top, UISpacing.sm)
                    }
                }
                .glassAppear()
            }
            .padding()
        }
    }

    private var authView: some View {
        VStack(spacing: UISpacing.lg) {
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                padding: UISpacing.lg
            ) {
                VStack(spacing: UISpacing.md) {
                    Text("Sign In")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(UIColors.label)
                    
                    Text("Anonymous-first. Use Apple for privacy or email as fallback.")
                        .font(.subheadline)
                        .foregroundColor(UIColors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .glassAppear()

            // Apple Sign In
            SignInWithAppleButton(.continue) { request in
                // Configure request scopes if needed
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                       let tokenData = credential.identityToken,
                       let token = String(data: tokenData, encoding: .utf8) {
                        Task { @MainActor in
                            do {
                                try await supabase.signInWithApple(idToken: token, nonce: nil)
                                HapticFeedback.notification(type: .success)
                                toastCenter.show(.success, "Signed in with Apple")
                            } catch {
                                HapticFeedback.notification(type: .error)
                                toastCenter.show(.error, NSLocalizedString("Something went wrong. Please try again.", comment: ""))
                            }
                        }
                    } else {
                        HapticFeedback.notification(type: .error)
                        toastCenter.show(.error, "Apple sign-in failed")
                    }
                case .failure:
                    HapticFeedback.notification(type: .error)
                    toastCenter.show(.error, NSLocalizedString("Something went wrong. Please try again.", comment: ""))
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .cornerRadius(8)
            .padding(.horizontal)

            // Email fallback with glass styling
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                padding: UISpacing.md
            ) {
                HStack(spacing: UISpacing.sm) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(UISpacing.sm)
                        .background(MaterialDesignSystem.Glass.ultraThin)
                        .overlay(
                            RoundedRectangle(cornerRadius: UICornerRadius.xs)
                                .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                        )
                        .cornerRadius(UICornerRadius.xs)
                    
                    GlassButton(
                        "Send Link",
                        style: .secondary
                    ) {
                        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !e.isEmpty else { return }
                        Task { @MainActor in
                            do {
                                try await supabase.signInWithEmailMagicLink(email: e)
                                MaterialHaptics.light()
                                toastCenter.show(.info, "Check your email for the link")
                            } catch {
                                MaterialHaptics.error()
                                toastCenter.show(.error, NSLocalizedString("Something went wrong. Please try again.", comment: ""))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private var interestsView: some View {
        ScrollView {
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                padding: UISpacing.lg
            ) {
                VStack(alignment: .leading, spacing: UISpacing.md) {
                    Text("Pick a few interests (optional)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(UIColors.label)
                    
                    FlowLayout(TagCatalog.all, spacing: UISpacing.xs) { tag in
                        let isOn = selectedInterests.contains(tag)
                        
                        Button(action: {
                            withAnimation(MaterialMotion.Spring.quick) {
                                if isOn { 
                                    selectedInterests.remove(tag) 
                                } else { 
                                    selectedInterests.insert(tag) 
                                }
                            }
                            MaterialHaptics.selection()
                        }) {
                            Text(tag.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isOn ? UIColors.accentPrimary : UIColors.label)
                                .padding(.horizontal, UISpacing.sm)
                                .padding(.vertical, UISpacing.xs)
                                .background(
                                    isOn ? 
                                    MaterialDesignSystem.GlassColors.primary : 
                                    MaterialDesignSystem.Glass.ultraThin
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: UICornerRadius.xl)
                                        .stroke(
                                            isOn ? 
                                            MaterialDesignSystem.GlassBorders.accent : 
                                            MaterialDesignSystem.GlassBorders.subtle,
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(UICornerRadius.xl)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .glassSelection(isSelected: isOn)
                    }
                    
                    Text("These help personalize your Feed.")
                        .font(.footnote)
                        .foregroundColor(UIColors.secondaryLabel)
                        .padding(.top, UISpacing.sm)
                }
            }
            .padding()
            .glassAppear()
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
