// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Dirt",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "Dirt",
            targets: ["Dirt"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Dirt",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Dirt/Dirt"
        )
    ]
)
