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
            
            // Referral Card
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text(referralCode)
                        .font(.title2).monospaced().bold()
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: copyCode) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: share) {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                Text("Benefits")
                    .font(.headline)
                Label("Unlock extra monthly lookups", systemImage: "bolt.fill")
                Label("Priority alerts for saved searches", systemImage: "bell.badge.fill")
                Label("Early access to new features", systemImage: "sparkles")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            // Share Targets (placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Share via")
                    .font(.headline)
                HStack(spacing: 12) {
                    ForEach(["message.fill", "envelope.fill", "link"], id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 52, height: 52)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showCopied {
                Text("Copied!")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showCopied)
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
