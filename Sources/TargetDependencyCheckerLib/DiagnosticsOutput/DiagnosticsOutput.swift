import Foundation
import SwiftSyntax

protocol DiagnosticsOutput {
    /// Called to indicate that the checker has started an analysis.
    func startReport(_ checker: DependencyChecker)

    /// Reports an import of a target `framework` into another target that is
    /// not a direct or indirect dependency of `target`
    func reportNonDependencyImport(
        _ checker: DependencyChecker,
        importDecl: ImportedFrameworkDeclaration,
        target: Target,
        file: SourceFile,
        relativePath: String
    )
    
    /// Reports an import of a target `framework` into another target that is
    /// not a direct dependency of `target`
    func reportNonDirectDependencyImport(
        _ checker: DependencyChecker,
        importDecl: ImportedFrameworkDeclaration,
        target: Target,
        file: SourceFile,
        relativePath: String
    )
    
    /// Called to indicate that the checker has finished analysis.
    func finishReport(_ checker: DependencyChecker)
}
