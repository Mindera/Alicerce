import PackageDescription

let package = Package(
    name: "Alicerce",
    dependencies: [
        .package(url: "https://github.com/antitypical/Result.git", from: "4.0.0")
    ]
)
