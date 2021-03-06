import Foundation

public class DependencyChecker {
    let options: Checker.Options
    let packageManager: PackageManager
    let fileManagerDelegate: FileManagerDelegate
    
    public weak var delegate: DependencyCheckerDelegate?
    
    init(options: Checker.Options, packageManager: PackageManager, fileManagerDelegate: FileManagerDelegate) {
        self.options = options
        self.packageManager = packageManager
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    func inspect() throws {
        var visitedImports: Set<ImportVisit> = []
        
        let inspections =
            try collectInspectionTargets(includePattern: options.includePattern,
                                         excludePattern: options.excludePattern)
        
        for inspection in inspections {
            try inspect(inspection: inspection, visitedImports: &visitedImports)
        }
    }
    
    func collectInspectionTargets(includePattern: String?,
                                  excludePattern: String?) throws -> [FileImportInspection] {
        
        var inspectionTargets: [FileImportInspection] = []
        
        let operationQueue = OperationQueue()
        let inspectionTargetsMutex = Mutex()
        var error: Error?
        let errorMutex = Mutex()
        
        for target in packageManager.targets {
            let files =
                try packageManager
                    .sourceFiles(for: target,
                                 includePattern: includePattern,
                                 excludePattern: excludePattern)
            
            for file in files {
                operationQueue.addOperation { [fileManagerDelegate] in
                    let fileManager =
                        SourceFileManager(sourceFile: file,
                                          fileManagerDelegate: fileManagerDelegate)
                    
                    do {
                        let importedFrameworkDeclarations = try fileManager.importedFrameworks()
                        
                        let inspection =
                            FileImportInspection(file: file,
                                             target: target,
                                             importedFrameworks: importedFrameworkDeclarations)
                        
                        inspectionTargetsMutex.locking {
                            inspectionTargets.append(inspection)
                        }
                    } catch let e {
                        errorMutex.locking {
                            error = e
                        }
                    }
                }
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if let error = error {
            throw error
        }
        
        // Sort files by path to result in a predictable diagnostical output
        return inspectionTargets.sorted(by: { $0.file.path.path < $1.file.path.path })
    }
    
    func inspect(inspection: FileImportInspection,
                 visitedImports: inout Set<ImportVisit>) throws {
        
        let file = inspection.file
        let target = inspection.target
        let importedFrameworkDeclarations = inspection.importedFrameworks
        
        let diagnosticsTarget = options.outputType.diagnosticsOutput
        
        let rootPath = packageManager.packageRootUrl.path
        let dependencyGraph = try packageManager.dependencyGraph()
        
        let relativePath =
            String(file.path.path.replacingOccurrences(of: rootPath, with: "").drop(while: { $0 == "/" }))
        
        for importDecl in importedFrameworkDeclarations {
            // Ignore system frameworks that are implicitly imported.
            if delegate?.dependencyChecker(self, isDependencySystemFramework: importDecl.frameworkName) == true {
                continue
            }
            if options.ignoreIncludes.contains(importDecl.frameworkName) {
                continue
            }
            
            if options.warnOncePerFramework {
                let importVisit = ImportVisit(framework: importDecl.frameworkName, target: target)
                if !visitedImports.insert(importVisit).inserted {
                    continue
                }
            }
            
            if !dependencyGraph.hasPath(from: importDecl.frameworkName, to: target.name) {
                diagnosticsTarget
                    .reportNonDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            } else if options.warnIndirectDependencies && !dependencyGraph.hasEdge(from: importDecl.frameworkName, to: target.name) {
                diagnosticsTarget
                    .reportNonDirectDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            }
        }
    }
    
    struct FileImportInspection {
        var file: SourceFile
        var target: Target
        var importedFrameworks: [ImportedFrameworkDeclaration]
    }
    
    struct ImportVisit: Hashable {
        var framework: String
        var target: Target
    }
}
