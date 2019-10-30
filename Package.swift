// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TargetDependencyChecker",
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-syntax", .revision("0.50100.0")),
    ],
    targets: [
        // MARK: -
        .target(
            name: "TargetDependencyCheckerLib",
            dependencies: ["SwiftSyntax"]),
        .target(
            name: "TargetDependencyChecker",
            dependencies: ["TargetDependencyCheckerLib", "Utility"]),
        
        // MARK: - Test targets
        .testTarget(
            name: "TargetDependencyCheckerLibTests",
            dependencies: ["TargetDependencyCheckerLib", "SwiftSyntax"]),
        .testTarget(
            name: "TargetDependencyCheckerTests",
            dependencies: ["TargetDependencyChecker"]),
    ]
)
