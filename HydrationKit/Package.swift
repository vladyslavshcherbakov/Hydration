// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HydrationKit",
    platforms: [.iOS(.v16), .watchOS(.v9), .macOS(.v13)],
    products: [
        .library(name: "HydrationDomain", targets: ["HydrationDomain"]),
        .library(name: "HydrationPersistence", targets: ["HydrationPersistence"]),
        .library(name: "HydrationDesignSystem", targets: ["HydrationDesignSystem"]),
        .library(name: "HydrationRouting", targets: ["HydrationRouting"]),
        .library(name: "HydrationPairedDevice", targets: ["HydrationPairedDevice"]),
        .library(name: "HydrationTestSupport", targets: ["HydrationTestSupport"])
    ],
    targets: [
        .target(name: "HydrationDomain"),
        .target(name: "HydrationPersistence", dependencies: ["HydrationDomain"]),
        .target(name: "HydrationDesignSystem", dependencies: ["HydrationDomain"]),
        .target(name: "HydrationRouting", dependencies: ["HydrationDomain"]),
        .target(name: "HydrationPairedDevice", dependencies: ["HydrationDomain"]),
        .target(
            name: "HydrationTestSupport",
            dependencies: ["HydrationDomain", "HydrationPersistence", "HydrationPairedDevice"]
        ),
        .testTarget(
            name: "HydrationDomainTests",
            dependencies: ["HydrationDomain", "HydrationTestSupport"]
        ),
        .testTarget(
            name: "HydrationPairedDeviceTests",
            dependencies: ["HydrationPairedDevice", "HydrationDomain", "HydrationTestSupport"]
        ),
        .testTarget(
            name: "HydrationRoutingTests",
            dependencies: ["HydrationRouting", "HydrationDomain"]
        ),
        .testTarget(
            name: "HydrationPersistenceTests",
            dependencies: ["HydrationPersistence", "HydrationDomain", "HydrationTestSupport"]
        )
    ]
)
