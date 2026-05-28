// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FocusGlass",
    defaultLocalization: "ru",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FocusGlass",
            targets: ["FocusGlassApp"]
        ),
        .library(
            name: "FocusGlassCore",
            targets: ["FocusGlassCore"]
        )
    ],
    targets: [
        .target(
            name: "FocusGlassCore"
        ),
        .executableTarget(
            name: "FocusGlassApp",
            dependencies: ["FocusGlassCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FocusGlassCoreTests",
            dependencies: ["FocusGlassCore"]
        ),
        .testTarget(
            name: "FocusGlassAppTests",
            dependencies: ["FocusGlassApp"]
        )
    ]
)
