import Foundation

class PackageManager {
    let package: Package
    let packageRootUrl: URL
    let fileManagerDelegate: FileManagerDelegate
    
    var _dependencyGraph: DependencyGraph?
    
    var targets: [Target] {
        return package.targets
    }
    
    init(package: Package,
         packageRootUrl: URL,
         fileManagerDelegate: FileManagerDelegate) {
        
        self.package = package
        self.packageRootUrl = packageRootUrl
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    func target(withName name: String) -> Target? {
        return targets.first(where: { $0.name == name })
    }
    
    func dependencyGraph() throws -> DependencyGraph {
        if let graph = _dependencyGraph {
            return graph
        }
        
        let graph = try DependencyGraph(package: package)
        _dependencyGraph = graph
        return graph
    }
    
    func sourcePath(for target: Target) -> URL? {
        if let path = target.path {
            return URL(string: path, relativeTo: packageRootUrl)
        }
        
        let sourceDirectories: [String]
        
        switch target.type {
        case .regular:
            sourceDirectories = PackageManager.predefinedSourceDirectories
            
        case .test:
            sourceDirectories = PackageManager.predefinedTestDirectories
        }
        
        let mappedUrls: [URL] =
            sourceDirectories
                .map { path in
                    packageRootUrl.appendingPathComponent(path, isDirectory: true)
                }
                .compactMap {
                    return URL(string: target.name, relativeTo: $0)
                }
        
        return mappedUrls.first(where: fileManagerDelegate.isDirectory(_:))
    }
    
    func sourceFiles(for target: Target,
                     includePattern: String? = nil,
                     excludePattern: String? = nil) throws -> [SourceFile] {
        
        guard let path = sourcePath(for: target) else {
            throw Error.invalidTargetUrl
        }
        
        let files =
            try fileManagerDelegate
                .allFilesInUrl(path,
                               includePattern: includePattern,
                               excludePattern: excludePattern)
        
        return files.filter({ $0.pathExtension == "swift" }).map(SourceFile.init)
    }
    
    enum Error: Swift.Error {
        case invalidTargetUrl
    }
}

private extension PackageManager {
    /// Predefined source directories, in order of preference.
    static let predefinedSourceDirectories = ["Sources", "Source", "src", "srcs"]
    
    /// Predefined test directories, in order of preference.
    static let predefinedTestDirectories = ["Tests", "Sources", "Source", "src", "srcs"]
}
