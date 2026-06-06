// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FinderHistory",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FinderHistory", targets: ["FinderHistory"])
    ],
    targets: [
        .target(
            name: "FinderHistoryCore",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "FinderHistory",
            dependencies: ["FinderHistoryCore"]
        ),
        .testTarget(
            name: "FinderHistoryCoreTests",
            dependencies: ["FinderHistoryCore"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
