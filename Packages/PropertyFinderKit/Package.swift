// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PropertyFinderKit",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "Listings", targets: ["Listings"]),
        .library(name: "Settings", targets: ["Settings"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Logger", targets: ["Logger"]),
    ],
    targets: [
        .target(name: "Networking"),
        .target(name: "Logger"),
        .target(name: "Extensions"),
        .target(
            name: "DesignSystem",
            dependencies: ["Extensions"],
            resources: [.process("Resources/Assets.xcassets")]
        ),

        .target(
            name: "Listings",
            dependencies: ["Networking", "Logger", "Extensions", "DesignSystem"],
            path: "Sources/Features/Listings"
        ),
        .target(
            name: "Settings",
            path: "Sources/Features/Settings"
        ),

    ],
    swiftLanguageModes: [.v6]
)
