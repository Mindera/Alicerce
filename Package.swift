// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Alicerce",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "Alicerce",
            targets: [
                "Analytics",
                "Core",
                "DeepLinking",
                "Extensions",
                "Logging",
                "Network",
                "Observers",
                "PerformanceMetrics",
                "Persistence",
                "Resource",
                "Stores",
                "View"]
        ),
        .library(name: "AlicerceAnalytics", targets: ["Analytics"]),
        .library(name: "AlicerceCore", targets: ["Core"]),
        .library(name: "AlicerceDeepLinking", targets: ["DeepLinking"]),
        .library(name: "AlicerceExtensions", targets: ["Extensions"]),
        .library(name: "AlicerceLogging", targets: ["Logging"]),
        .library(name: "AlicerceNetwork", targets: ["Network"]),
        .library(name: "AlicerceObservers", targets: ["Observers"]),
        .library(name: "AlicercePerformanceMetrics", targets: ["PerformanceMetrics"]),
        .library(name: "AlicercePersistence", targets: ["Persistence"]),
        .library(name: "AlicerceResource", targets: ["Resource"]),
        .library(name: "AlicerceStores", targets: ["Stores"]),
        .library(name: "AlicerceView", targets: ["View"]),
    ],
    targets: [
        .target(name: "Analytics", dependencies: ["Core"]),
        .target(name: "Core", dependencies: ["Extensions"], path: "Sources", sources: ["Shared", "Utils"]),
        .target(name: "DeepLinking", dependencies: ["Core"]),
        .target(name: "Extensions"),
        .target(name: "Logging", dependencies: ["Core"]),
        .target(name: "Network", dependencies: ["Resource"]),
        .target(name: "Observers", dependencies: ["Core"]),
        .target(name: "PerformanceMetrics", dependencies: ["Core"]),
        .target(name: "Persistence", dependencies: ["Core", "Logging", "PerformanceMetrics"]),
        .target(name: "Resource", dependencies: ["Core"]),
        .target(
            name: "Stores",
            dependencies: ["Core", "Logging", "Network", "PerformanceMetrics", "Persistence", "Resource"]
        ),
        .target(name: "View", dependencies: ["Core"])
    ],
    swiftLanguageVersions: [ .version("5") ]
)
