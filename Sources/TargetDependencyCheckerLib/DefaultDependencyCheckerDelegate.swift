import Foundation

private let systemFrameworks: Set<String> = [
    "Foundation",
    "ObjectiveC",
    "Darwin",
    "Glibc",
    "XCTest",
    "Dispatch"
]

public class DefaultDependencyCheckerDelegate: DependencyCheckerDelegate {
    public func dependencyChecker(_ checker: DependencyChecker,
                                  isDependencySystemFramework frameworkName: String) -> Bool {
        
        return systemFrameworks.contains(frameworkName)
    }
}
