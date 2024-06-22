// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "WrappingStack",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "WrappingStack",
            targets: ["WrappingStack"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WrappingStack",
            dependencies: []
        ),
    ]
)
