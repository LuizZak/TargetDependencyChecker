import Foundation

public class DefaultDependencyCheckerDelegate: DependencyCheckerDelegate {
    public func dependencyChecker(
        _ checker: DependencyChecker,
        isDependencySystemFramework frameworkName: String
    ) -> Bool {
        
        return SystemFrameworks.frameworks.contains(frameworkName)
    }
}
