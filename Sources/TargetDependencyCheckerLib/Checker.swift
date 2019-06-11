import Foundation

public enum Checker {
    public struct Options {
        public var warnIndirectDependencies: Bool
        
        public init(warnIndirectDependencies: Bool = false) {
            self.warnIndirectDependencies = warnIndirectDependencies
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let packageDiscovery = PackageDiscovery()
        
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
        
        let rootPath = packageManager.packageRootUrl.path
        let dependencyGraph = try packageManager.dependencyGraph()
        
        let relativePath = file.path.path.replacingOccurrences(of: rootPath, with: "").drop(while: { $0 == "/" })
        
        let fileManager = SourceFileManager(sourceFile: file,
                                            fileManagerDelegate: DiskFileManagerDelegate())
        
        let importedFrameworks = try fileManager.importedFrameworks()
        
        for framework in importedFrameworks {
            guard let frameworkTarget = packageManager.target(withName: framework) else {
                continue
            }
            
            if !dependencyGraph.hasPath(from: frameworkTarget, to: target) {
                print("""
                    Warning: Found import declaration for framework \(framework) in target \(target.name) \
                    in file \(relativePath), but dependency is not declared in Package.swift manifest, neither \
                    directly or indirectly.
                    """)
            }
            
            if options.warnIndirectDependencies && !dependencyGraph.hasEdge(from: frameworkTarget, to: target) {
                print("""
                    Indirect-dependency warning: Found import declaration for \
                    framework \(framework) in target \(target.name) in file \
                    \(relativePath), but dependency is not declared explicitly \
                    in Package.swift manifest.
                    """)
            }
        }
    }
}
