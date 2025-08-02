// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DirtApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "DirtApp", targets: ["App"])
    ],
    dependencies: [
        // Supabase Swift client
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "1.3.0"),
        // Combine is built-in, no need to add
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"],
            path: "Tests"
        )
    ]
)
