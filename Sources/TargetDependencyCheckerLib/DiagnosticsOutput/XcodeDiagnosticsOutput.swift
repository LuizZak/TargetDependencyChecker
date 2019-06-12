import Foundation
import SwiftSyntax

class XcodeDiagnosticsOutput: DiagnosticsOutput {
    func makeFilePathAndLine(file: URL, importDecl: ImportedFrameworkDeclaration) -> String {
        return "\(file.path):\(importDecl.location.line ?? 0)"
    }
    
    func reportNonDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String) {
        
        let filePathAndLine = makeFilePathAndLine(file: file.path, importDecl: importDecl)
        
        print("""
            \(filePathAndLine): warning: Import of framework \(importDecl.frameworkName) \
            in target \(target.name), but dependency is not declared in \
            Package.swift manifest, neither directly or indirectly.
            """)
    }
    
    func reportNonDirectDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         file: SourceFile,
                                         relativePath: String) {

        let filePathAndLine = makeFilePathAndLine(file: file.path, importDecl: importDecl)
        
        print("""
            \(filePathAndLine): warning: Indirect-dependency: Import of framework \
            \(importDecl.frameworkName) in target \(target.name), but dependency \
            is not declared explicitly in Package.swift manifest.
            """)
    }
}
