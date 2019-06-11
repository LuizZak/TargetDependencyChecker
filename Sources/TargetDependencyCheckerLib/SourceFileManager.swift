import Foundation
import SwiftSyntax

class SourceFileManager {
    let sourceFile: SourceFile
    let fileManagerDelegate: FileManagerDelegate
    
    init(sourceFile: SourceFile, fileManagerDelegate: FileManagerDelegate) {
        self.sourceFile = sourceFile
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    func importedFrameworks() throws -> [String] {
        let source =
            try fileManagerDelegate
                .contentsOfFile(at: sourceFile.path, encoding: .utf8)
        
        let file = try SyntaxParser.parse(source: source)
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
