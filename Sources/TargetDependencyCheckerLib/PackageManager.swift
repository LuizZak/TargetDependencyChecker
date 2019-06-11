import Foundation

class PackageManager {
    let package: Package
    let packageRootUrl: URL
    
    var targets: [Target] {
        return package.targets
    }
    
    init(package: Package, packageRootUrl: URL) {
        self.package = package
        self.packageRootUrl = packageRootUrl
    }
    
    func buildDependencyGraph() throws -> DependencyGraph {
        try DependencyGraph(package: package)
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
