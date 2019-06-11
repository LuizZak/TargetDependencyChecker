import Foundation
import SwiftSyntax

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
        
        let file = try SyntaxParser.parse(source: source)
        let sourceLocationConverter =
            SourceLocationConverter(file: sourceFile.path.path, tree: file)
        
        var visitor = ImportVisitor(sourceLocationConverter: sourceLocationConverter)
        file.walk(&visitor)
        
        return visitor.imports
    }
    
    private class ImportVisitor: SyntaxVisitor {
        let sourceLocationConverter: SourceLocationConverter
        var imports: [ImportedFrameworkDeclaration] = []
        
        init(sourceLocationConverter: SourceLocationConverter) {
            self.sourceLocationConverter = sourceLocationConverter
        }
        
        func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.attributes == nil && node.path.count == 1 {
                let location =
                    node.startLocation(converter: sourceLocationConverter,
                                       afterLeadingTrivia: true)
                
                let decl =
                    ImportedFrameworkDeclaration(
                        frameworkName: node.path.description,
                        importDeclSyntax: node,
                        location: location)
                
                imports.append(decl)
            }
            
            return .visitChildren
        }
    }
}

struct ImportedFrameworkDeclaration {
    var frameworkName: String
    var importDeclSyntax: ImportDeclSyntax
    var location: SourceLocation
}
