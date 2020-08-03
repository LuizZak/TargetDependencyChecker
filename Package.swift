// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TargetDependencyChecker",
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", .revision("swift-5.3-DEVELOPMENT-SNAPSHOT-2020-06-24-a")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "0.0.4")
    ],
    targets: [
        // MARK: -
        .target(
            name: "TargetDependencyCheckerLib",
            dependencies: ["SwiftSyntax"]),
        .target(
            name: "TargetDependencyChecker",
            dependencies: ["TargetDependencyCheckerLib", "ArgumentParser"]),
        
        // MARK: - Test targets
        .testTarget(
            name: "TargetDependencyCheckerLibTests",
            dependencies: ["TargetDependencyCheckerLib", "SwiftSyntax"]),
        .testTarget(
            name: "TargetDependencyCheckerTests",
            dependencies: ["TargetDependencyChecker"]),
    ]
)
