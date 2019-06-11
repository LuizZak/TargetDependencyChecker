import Foundation
import SwiftSyntax

class SourceFileManager {
    let sourceFile: SourceFile
    
    init(sourceFile: SourceFile) {
        self.sourceFile = sourceFile
    }
    
    func importedFrameworks() throws -> [String] {
        let file = try SyntaxParser.parse(sourceFile.path)
        var visitor = ImportVisitor()
        file.walk(&visitor)
        
        return visitor.imports
    }
    
    private class ImportVisitor: SyntaxVisitor {
        var imports: [String] = []
        
        func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.attributes == nil && node.path.count == 1 {
                imports.append(node.path.description)
            }
            
            return .visitChildren
        }
    }
}
