// swift-tools-version:5.2

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
                "AlicerceAnalytics",
                "AlicerceAutoLayout",
                "AlicerceCore",
                "AlicerceDeepLinking",
                "AlicerceExtensions",
                "AlicerceLogging",
                "AlicerceNetwork",
                "AlicerceObservers",
                "AlicercePerformanceMetrics",
                "AlicercePersistence",
                "AlicerceStackOrchestrator",
                "AlicerceView"
            ]
        ),
        .library(name: "AlicerceAnalytics", targets: ["AlicerceAnalytics"]),
        .library(name: "AlicerceAutoLayout", targets: ["AlicerceAutoLayout"]),
        .library(name: "AlicerceCore", targets: ["AlicerceCore"]),
        .library(name: "AlicerceDeepLinking", targets: ["AlicerceDeepLinking"]),
        .library(name: "AlicerceExtensions", targets: ["AlicerceExtensions"]),
        .library(name: "AlicerceLogging", targets: ["AlicerceLogging"]),
        .library(name: "AlicerceNetwork", targets: ["AlicerceNetwork"]),
        .library(name: "AlicerceObservers", targets: ["AlicerceObservers"]),
        .library(name: "AlicercePerformanceMetrics", targets: ["AlicercePerformanceMetrics"]),
        .library(name: "AlicercePersistence", targets: ["AlicercePersistence"]),
        .library(name: "AlicerceStackOrchestrator", targets: ["AlicerceStackOrchestrator"]),
        .library(name: "AlicerceView", targets: ["AlicerceView"])
    ],
    targets: [
        .target(name: "AlicerceAnalytics", dependencies: ["AlicerceCore"], path: "Sources/Analytics"),
        .target(name: "AlicerceAutoLayout", path: "Sources/AutoLayout"),
        .target(
            name: "AlicerceCore",
            dependencies: ["AlicerceExtensions"],
            path: "Sources",
            sources: ["Shared", "Utils"]
        ),
        .target(name: "AlicerceDeepLinking", dependencies: ["AlicerceCore"], path: "Sources/DeepLinking"),
        .target(name: "AlicerceExtensions", path: "Sources/Extensions", sources: ["Foundation", "UIKit"]),
        .target(name: "AlicerceLogging", dependencies: ["AlicerceCore"], path: "Sources/Logging"),
        .target(name: "AlicerceNetwork", dependencies: ["AlicerceCore"], path: "Sources/Network"),
        .target(name: "AlicerceObservers", path: "Sources/Observers"),
        .target(name: "AlicercePerformanceMetrics", dependencies: ["AlicerceCore"], path: "Sources/PerformanceMetrics"),
        .target(
            name: "AlicercePersistence",
            dependencies: ["AlicerceCore", "AlicerceLogging", "AlicercePerformanceMetrics"],
            path: "Sources/Persistence"
        ),
        .target(
            name: "AlicerceStackOrchestrator",
            dependencies: [
                "AlicerceCore",
                "AlicerceLogging",
                "AlicerceNetwork",
                "AlicercePerformanceMetrics",
                "AlicercePersistence"
            ],
            path: "Sources/StackOrchestrator"
        ),
        .target(name: "AlicerceView", path: "Sources/View")
    ],
    swiftLanguageVersions: [ .version("5") ]
)
