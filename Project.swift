import ProjectDescription

let project = Project(
    name: "Tahudu",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [.local(path: "Packages/PropertyFinderKit")],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_APPROACHABLE_CONCURRENCY": "NO",
        "SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT": "NO",
        "GENERATE_INFOPLIST_FILE": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "MARKETING_VERSION": "1.0",
        "CURRENT_PROJECT_VERSION": "1",
    ]),
    targets: [
        .target(
            name: "Tahudu",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "ae.propertyfinder.Tahudu",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .file(path: "Tahudu/Info.plist"),
            sources: ["Tahudu/**/*.swift"],
            resources: ["Tahudu/Assets/**", "Tahudu/LaunchScreen.storyboard", "Tahudu/PrivacyInfo.xcprivacy"],
            dependencies: [
                .package(product: "Listings"),
                .package(product: "Settings"),
                .package(product: "DesignSystem"),
                .package(product: "Networking"),
                .package(product: "Logger"),
            ],
            settings: .settings(base: [
                "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
                "SWIFT_EMIT_LOC_STRINGS": "NO",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "",
                "ENABLE_PREVIEWS": "YES",
                "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
                "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
                "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
            ])
        ),
    ],
    schemes: [
        .scheme(
            name: "Tahudu",
            buildAction: .buildAction(targets: ["Tahudu"]),
            runAction: .runAction(configuration: .debug),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(configuration: .release),
            analyzeAction: .analyzeAction(configuration: .debug)
        ),
    ]
)
