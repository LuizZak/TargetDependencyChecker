import Foundation
import SwiftSyntax

class XcodeDiagnosticsOutput: DiagnosticsOutput {
    func makeFilePathAndLine(file: URL, importDecl: ImportedFrameworkDeclaration) -> String {
        return "\(file.path):\(importDecl.location.line ?? 0)"
    }

    func startReport(_ checker: DependencyChecker) {

    }
    
    func reportNonDependencyImport(_ checker: DependencyChecker,
                                   importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String) {
        
        let filePathAndLine = makeFilePathAndLine(file: file.path, importDecl: importDecl)
        
        print("""
            \(filePathAndLine): error: Import of framework \(importDecl.frameworkName) \
            in target \(target.name), but dependency is not declared in \
            Package.swift manifest, either directly or indirectly.
            """)
    }
    
    func reportNonDirectDependencyImport(_ checker: DependencyChecker,
                                         importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         dependenciesPath: [String],
                                         file: SourceFile,
                                         relativePath: String) {

        let filePathAndLine = makeFilePathAndLine(file: file.path, importDecl: importDecl)
        
        print("""
            \(filePathAndLine): warning: Indirect-dependency: Import of framework \
            \(importDecl.frameworkName) in target \(target.name), but dependency \
            is not declared explicitly in Package.swift manifest.
            """)
    }

    func finishReport(_ checker: DependencyChecker) {
        
    }
}
