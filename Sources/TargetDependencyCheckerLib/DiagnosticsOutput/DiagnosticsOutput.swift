import Foundation
import SwiftSyntax

protocol DiagnosticsOutput {
    /// Reports an import of a target `framework` into another target that is
    /// not a direct or indirect dependency of `target`
    func reportNonDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String)
    
    /// Reports an import of a target `framework` into another target that is
    /// not a direct dependency of `target`
    func reportNonDirectDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         file: SourceFile,
                                         relativePath: String)
    
    /// Called to indicate that the checker has finished analysis.
    func finishReport()
}
