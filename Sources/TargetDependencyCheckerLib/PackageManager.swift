import Foundation

class PackageManager {
    let package: Package
    let packageRootUrl: URL
    var _dependencyGraph: DependencyGraph?
    
    var targets: [Target] {
        return package.targets
    }
    
    init(package: Package, packageRootUrl: URL) {
        self.package = package
        self.packageRootUrl = packageRootUrl
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
        
        let mappedUrls =
            sourceDirectories
                .map(URL.init(fileURLWithPath:))
                .compactMap { URL(string: target.name, relativeTo: $0) }
        
        return mappedUrls.first(where: isDirectory(_:))
    }
    
    func sourceFiles(for target: Target) throws -> [SourceFile] {
        guard let path = sourcePath(for: target) else {
            throw Error.invalidTargetUrl
        }
        
        let files =
            try FileManager
                .default
                .contentsOfDirectory(at: path,
                                     includingPropertiesForKeys: nil,
                                     options: [.skipsHiddenFiles])
        
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

private func isDirectory(_ url: URL) -> Bool {
    var isDir: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
}
