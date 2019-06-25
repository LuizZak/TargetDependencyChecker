import Foundation

public enum Checker {
    static var workDirectory: URL {
        var buffer: [Int8] = Array(repeating: 0, count: 1024)
        guard getcwd(&buffer, buffer.count) != nil else {
            fatalError("Error fetching work directory")
        }
        
        return URL(fileURLWithPath: String(cString: buffer))
    }
    
    public struct Options {
        public var warnIndirectDependencies: Bool
        public var warnOncePerFramework: Bool
        public var packageDirectory: URL?
        public var outputType: OutputType
        public var includePattern: String?
        public var excludePattern: String?
        
        public init(warnIndirectDependencies: Bool = false,
                    warnOncePerFramework: Bool = false,
                    packageDirectory: URL? = nil,
                    outputType: OutputType = .terminal,
                    includePattern: String? = nil,
                    excludePattern: String? = nil) {
            
            self.warnIndirectDependencies = warnIndirectDependencies
            self.warnOncePerFramework = warnOncePerFramework
            self.packageDirectory = packageDirectory
            self.outputType = outputType
            self.includePattern = includePattern
            self.excludePattern = excludePattern
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let url = options.packageDirectory ?? workDirectory
        
        let packageDiscovery = PackageDiscovery(packageUrl: url)
        
        let packageManager = try packageDiscovery.packageManager()
        
        var visitedImports: Set<ImportVisit> = []
        
        let inspections =
            try collectInspectionTargets(
                packageManager: packageManager,
                includePattern: options.includePattern,
                excludePattern: options.excludePattern)
        
        for inspection in inspections {
            try inspect(inspection: inspection,
                        packageManager: packageManager,
                        options: options,
                        visitedImports: &visitedImports)
        }
    }
    
    static func collectInspectionTargets(packageManager: PackageManager,
                                         includePattern: String?,
                                         excludePattern: String?) throws -> [ImportInspection] {
        
        let fileManagerDelegate = DiskFileManagerDelegate()
        
        var inspectionTargets: [ImportInspection] = []
        
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
                operationQueue.addOperation {
                    let fileManager =
                        SourceFileManager(sourceFile: file,
                                          fileManagerDelegate: fileManagerDelegate)
                    
                    do {
                        let importedFrameworkDeclarations = try fileManager.importedFrameworks()
                        
                        let inspection =
                            ImportInspection(file: file,
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
    
    static func inspect(inspection: ImportInspection,
                        packageManager: PackageManager,
                        options: Options,
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
            guard let frameworkTarget = packageManager.target(withName: importDecl.frameworkName) else {
                continue
            }
            
            if options.warnOncePerFramework {
                let importVisit = ImportVisit(framework: importDecl.frameworkName, target: target)
                if !visitedImports.insert(importVisit).inserted {
                    continue
                }
            }
            
            if !dependencyGraph.hasPath(from: frameworkTarget.name, to: target.name) {
                diagnosticsTarget
                    .reportNonDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            } else if options.warnIndirectDependencies && !dependencyGraph.hasEdge(from: frameworkTarget.name, to: target.name) {
                diagnosticsTarget
                    .reportNonDirectDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            }
        }
    }
    
    struct ImportInspection {
        var file: SourceFile
        var target: Target
        var importedFrameworks: [ImportedFrameworkDeclaration]
    }
    
    struct ImportVisit: Hashable {
        var framework: String
        var target: Target
    }
}

public enum OutputType: String {
    case terminal
    case xcode
    
    var diagnosticsOutput: DiagnosticsOutput {
        switch self {
        case .terminal:
            return TerminalDiagnosticsOutput()
        case .xcode:
            return XcodeDiagnosticsOutput()
        }
    }
}
