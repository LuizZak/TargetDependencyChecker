import Foundation
import SwiftSyntax
import SwiftParser

class SourceFileManager {
    let sourceFile: SourceFile
    let fileManagerDelegate: FileManagerDelegate
    
    init(sourceFile: SourceFile, fileManagerDelegate: FileManagerDelegate) {
        self.sourceFile = sourceFile
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    func importedFrameworks() throws -> [ImportedFrameworkDeclaration] {
        let source =
            try fileManagerDelegate
                .contentsOfFile(at: sourceFile.path, encoding: .utf8)
        
        let file = SwiftParser.Parser.parse(source: source)
        let sourceLocationConverter =
            SourceLocationConverter(fileName: sourceFile.path.path, tree: file)
        
        let visitor = ImportVisitor(sourceLocationConverter: sourceLocationConverter)
        visitor.walk(file)
        
        return visitor.imports
    }
    
    private class ImportVisitor: SyntaxVisitor {
        let sourceLocationConverter: SourceLocationConverter
        var imports: [ImportedFrameworkDeclaration] = []
        
        init(sourceLocationConverter: SourceLocationConverter) {
            self.sourceLocationConverter = sourceLocationConverter
            super.init(viewMode: .fixedUp)
        }
        
        override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
            if let importDecl = node.item.as(ImportDeclSyntax.self) {
                inspectImport(importDecl)
            }
            
            return .skipChildren
        }
        
        func inspectImport(_ node: ImportDeclSyntax) {
            if node.attributes.count == 0 && node.path.count == 1 {
                let location =
                    node.startLocation(converter: sourceLocationConverter,
                                       afterLeadingTrivia: true)
                
                let decl =
                    ImportedFrameworkDeclaration(
                        frameworkName: node.path.description,
                        importDeclSyntax: node,
                        location: location
                    )
                
                imports.append(decl)
            }
        }
    }
}
