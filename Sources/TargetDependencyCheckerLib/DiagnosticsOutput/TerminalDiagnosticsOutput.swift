import Foundation
import SwiftSyntax

class TerminalDiagnosticsOutput: DiagnosticsOutput {
    func reportNonDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String) {
        print("""
            Warning: Found import declaration for framework \(importDecl.frameworkName) in target \(target.name) \
            in file \(relativePath), but dependency is not declared in Package.swift manifest, neither \
            directly or indirectly.
            """)
    }
    
    func reportNonDirectDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         file: SourceFile,
                                         relativePath: String) {
        print("""
            Indirect-dependency warning: Found import declaration for \
            framework \(importDecl.frameworkName) in target \(target.name) in file \
            \(relativePath), but dependency is not declared explicitly \
            in Package.swift manifest.
            """)
    }
}
