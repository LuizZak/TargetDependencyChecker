public protocol DependencyCheckerDelegate: AnyObject {
    func dependencyChecker(_ checker: DependencyChecker, isDependencySystemFramework frameworkName: String) -> Bool
}
