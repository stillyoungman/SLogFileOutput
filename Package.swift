// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SLogFileOutput",
    platforms: [.macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)],
    products: [
        .library(
            name: "SLogFileOutput",
            targets: ["SLogFileOutput"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stillyoungman/SLog.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "SLogFileOutput",
            dependencies: [
                "SLog"
            ])
    ]
)
