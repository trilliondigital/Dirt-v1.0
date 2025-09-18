import SwiftUI
import UIKit

struct InviteView: View {
    @State private var referralCode: String = "DIRT-8J2X"
    @State private var showCopied: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Invite Friends")
                    .font(.largeTitle).bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Invite friends to Dirt and unlock perks like extra lookups and faster alerts.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Referral Card with glass styling
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                cornerRadius: UICornerRadius.xl,
                padding: UISpacing.lg
            ) {
                VStack(spacing: UISpacing.md) {
                    HStack(spacing: UISpacing.sm) {
                        Text(referralCode)
                            .font(.title2)
                            .fontDesign(.monospaced)
                            .fontWeight(.bold)
                            .foregroundColor(UIColors.label)
                            .padding(UISpacing.sm)
                            .background(MaterialDesignSystem.Glass.ultraThin)
                            .overlay(
                                RoundedRectangle(cornerRadius: UICornerRadius.xs)
                                    .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                            )
                            .cornerRadius(UICornerRadius.xs)
                        
                        GlassButton(
                            "Copy",
                            systemImage: "doc.on.doc",
                            style: .secondary
                        ) {
                            copyCode()
                        }
                    }
                    
                    GlassButton(
                        "Share Invite",
                        systemImage: "square.and.arrow.up",
                        style: .primary
                    ) {
                        share()
                    }
                }
            }
            .padding(.horizontal)
            .glassAppear()
            
            // Benefits with glass card
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                padding: UISpacing.md
            ) {
                VStack(alignment: .leading, spacing: UISpacing.sm) {
                    Text("Benefits")
                        .font(.headline)
                        .foregroundColor(UIColors.label)
                    
                    VStack(alignment: .leading, spacing: UISpacing.xs) {
                        Label("Unlock extra monthly lookups", systemImage: "bolt.fill")
                            .foregroundColor(UIColors.warning)
                        Label("Priority alerts for saved searches", systemImage: "bell.badge.fill")
                            .foregroundColor(UIColors.accentPrimary)
                        Label("Early access to new features", systemImage: "sparkles")
                            .foregroundColor(UIColors.accentSecondary)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            // Share Targets with glass styling
            GlassCard(
                material: MaterialDesignSystem.Context.card,
                padding: UISpacing.md
            ) {
                VStack(alignment: .leading, spacing: UISpacing.sm) {
                    Text("Share via")
                        .font(.headline)
                        .foregroundColor(UIColors.label)
                    
                    HStack(spacing: UISpacing.sm) {
                        ForEach(Array(zip(["message.fill", "envelope.fill", "link"], [UIColors.success, UIColors.accentPrimary, UIColors.secondaryLabel])), id: \.0) { icon, color in
                            Button(action: {
                                // Handle specific share action
                            }) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(color)
                                    .frame(width: 52, height: 52)
                                    .background(MaterialDesignSystem.Glass.ultraThin)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: UICornerRadius.sm)
                                            .stroke(MaterialDesignSystem.GlassBorders.subtle, lineWidth: 1)
                                    )
                                    .cornerRadius(UICornerRadius.sm)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showCopied {
                GlassToast(message: "Copied!", type: .success)
                    .padding(.top, UISpacing.xs)
                    .transition(MaterialMotion.Transition.slideDown)
            }
        }
        .animation(MaterialMotion.Glass.toastAppear, value: showCopied)
    }
    
    private func copyCode() {
        UIPasteboard.general.string = referralCode
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showCopied = false
        }
    }
    
    private func share() {
        let avc = UIActivityViewController(activityItems: ["Join me on Dirt! Use my code: \(referralCode)"], applicationActivities: nil)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(avc, animated: true)
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { InviteView() }
    }
}
