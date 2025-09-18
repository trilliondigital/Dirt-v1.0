import SwiftUI
import UIKit

// Centralized helper for sample/filler avatars
struct AvatarProvider {
    // Add images with these names to Assets.xcassets to prefer local, offline avatars
    // Example: Avatars/avatar_girl_1, avatar_girl_2, ...
    static let localNames: [String] = [
        "avatar_girl_1",
        "avatar_girl_2",
        "avatar_girl_3",
        "avatar_girl_4",
        "avatar_girl_5",
        "avatar_girl_6",
        "avatar_girl_7",
        "avatar_girl_8"
    ]

    // Fallback remote placeholders (royalty-free portrait sources). Swap any time.
    // These are only used if the local asset with the chosen name is not present.
    static let urls: [URL] = [
        URL(string: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1524502397800-2eeaad7c3fe5?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1544005316-04ce1f3a06b0?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1549351512-c5e12b12c270?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1515468381879-40d0ded81016?q=80&w=256&auto=format&fit=crop")!,
        URL(string: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=256&auto=format&fit=crop")!
    ]

    static func localName(for index: Int) -> String? {
        guard !localNames.isEmpty else { return nil }
        return localNames[index % localNames.count]
    }

    static func url(for index: Int) -> URL? {
        guard !urls.isEmpty else { return nil }
        return urls[index % urls.count]
    }
}

// Safe array indexing helper
extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

// Reusable avatar view that tries local asset first, then remote, then a default
struct AvatarView: View {
    let index: Int
    let size: CGFloat

    init(index: Int, size: CGFloat = 64) {
        self.index = index
        self.size = size
    }

    var body: some View {
        ZStack {
            if let name = AvatarProvider.localName(for: index), UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let url = AvatarProvider.url(for: index) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        defaultCircle
                    case .empty:
                        ProgressView().frame(width: size, height: size)
                    @unknown default:
                        defaultCircle
                    }
                }
            } else {
                defaultCircle
            }
        }
        .frame(width: size, height: size)
    }

    private var defaultCircle: some View {
        Circle()
            .fill(LinearGradient(colors: [.pink.opacity(0.7), .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.4))
            )
            .frame(width: size, height: size)
    }
}