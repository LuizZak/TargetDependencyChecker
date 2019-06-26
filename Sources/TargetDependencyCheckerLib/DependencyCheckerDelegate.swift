public protocol DependencyCheckerDelegate: class {
    func dependencyChecker(_ checker: DependencyChecker, isDependencySystemFramework frameworkName: String) -> Bool
}
