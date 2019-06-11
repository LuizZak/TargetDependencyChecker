import Foundation

public enum Checker {
    public struct Options {
        public var warnIndirectDependencies: Bool
        public var packageDirectory: URL?
        public var outputType: OutputType
        
        public init(warnIndirectDependencies: Bool = false,
                    packageDirectory: URL? = nil,
                    outputType: OutputType = .terminal) {
            
            self.warnIndirectDependencies = warnIndirectDependencies
            self.packageDirectory = packageDirectory
            self.outputType = outputType
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let url = options.packageDirectory ?? PackageDiscovery.workDirectory
        
        let packageDiscovery = PackageDiscovery(packageUrl: url)
        
        let packageManager = try packageDiscovery.packageManager()
        
        for target in packageManager.targets {
            let files = try packageManager.sourceFiles(for: target)
            
            for file in files {
                try analyze(file: file,
                            target: target,
                            packageManager: packageManager,
                            options: options)
            }
        }
    }
    
    static func analyze(file: SourceFile,
                        target: Target,
                        packageManager: PackageManager,
                        options: Options) throws {
        
        let diagnosticsTarget = options.outputType.diagnosticsOutput
        
        let rootPath = packageManager.packageRootUrl.path
        let dependencyGraph = try packageManager.dependencyGraph()
        
        let relativePath =
            String(file.path.path.replacingOccurrences(of: rootPath, with: "").drop(while: { $0 == "/" }))
        
        let fileManager = SourceFileManager(sourceFile: file,
                                            fileManagerDelegate: DiskFileManagerDelegate())
        
        let importedFrameworkDeclarations = try fileManager.importedFrameworks()
        
        for importDecl in importedFrameworkDeclarations {
            guard let frameworkTarget = packageManager.target(withName: importDecl.frameworkName) else {
                continue
            }
            
            if !dependencyGraph.hasPath(from: frameworkTarget, to: target) {
                diagnosticsTarget
                    .reportNonDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            }
            
            if options.warnIndirectDependencies && !dependencyGraph.hasEdge(from: frameworkTarget, to: target) {
                diagnosticsTarget
                    .reportNonDirectDependencyImport(
                        importDecl: importDecl,
                        target: target,
                        file: file,
                        relativePath: relativePath)
            }
        }
    }
}

public enum OutputType {
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
