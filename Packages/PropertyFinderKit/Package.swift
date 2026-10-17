// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PropertyFinderKit",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "Listings", targets: ["Listings"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Logger", targets: ["Logger"]),
    ],
    targets: [
        // MARK: Shared modules

        .target(name: "Networking"),
        .target(name: "Logger"),
        .target(name: "Extensions"),
        .target(
            name: "DesignSystem",
            dependencies: ["Extensions"],
            resources: [.process("Resources/Assets.xcassets")]
        ),

        // MARK: Features

        .target(
            name: "Listings",
            dependencies: ["Networking", "Logger", "Extensions", "DesignSystem"],
            path: "Sources/Features/Listings"
        ),

        // MARK: Tests

        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
        .testTarget(
            name: "ListingsTests",
            dependencies: ["Listings", "Networking", "Logger"],
            path: "Tests/Features/ListingsTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
