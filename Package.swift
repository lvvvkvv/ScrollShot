// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "LongShot", platforms: [.macOS(.v14)], products: [.executable(name: "LongShot", targets: ["LongShot"])], targets: [
    .target(name: "LongShotCore"),
    .executableTarget(name: "LongShot", dependencies: ["LongShotCore"]),
    .executableTarget(name: "CoreChecks", dependencies: ["LongShotCore"], path: "Tests/LongShotCoreTests")
])
