// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SLogFileBackend",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)],
    products: [
        .library(
            name: "SLogFileBackend",
            targets: ["SLogFileBackend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stillyoungman/SLog.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SLogFileBackend",
            dependencies: [
                "SLog"
            ])
    ]
)
