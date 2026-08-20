// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LazyExperimentation",
    platforms: [.iOS(.v12), .macOS(.v10_15), .tvOS(.v12), .watchOS(.v5), .visionOS(.v1)],
    products: [
        .library(name: "LazyExperimentation", targets: ["LazyExperimentation"])
    ],
    dependencies: [
        .package(url: "https://github.com/growthbook/growthbook-swift.git", exact: "1.2.0")
    ],
    targets: [
        .target(
            name: "LazyExperimentation",
            dependencies: [.product(name: "GrowthBook-IOS", package: "growthbook-swift")]
        ),
        .testTarget(
            name: "LazyExperimentationTests",
            dependencies: ["LazyExperimentation"]
        )
    ]
)
