// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "whstats-bar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "whstats-bar", targets: ["whstats-bar"]),
    ],
    targets: [
        .executableTarget(
            name: "whstats-bar"
        ),
    ]
)
