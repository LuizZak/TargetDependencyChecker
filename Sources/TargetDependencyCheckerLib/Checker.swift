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
        public var ignoreIncludes: Set<String>
        
        public init(warnIndirectDependencies: Bool = false,
                    warnOncePerFramework: Bool = false,
                    packageDirectory: URL? = nil,
                    outputType: OutputType = .terminal,
                    includePattern: String? = nil,
                    excludePattern: String? = nil,
                    ignoreIncludes: Set<String> = []) {
            
            self.warnIndirectDependencies = warnIndirectDependencies
            self.warnOncePerFramework = warnOncePerFramework
            self.packageDirectory = packageDirectory
            self.outputType = outputType
            self.includePattern = includePattern
            self.excludePattern = excludePattern
            self.ignoreIncludes = ignoreIncludes
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let url = options.packageDirectory ?? workDirectory
        
        let packageDiscovery = PackageDiscovery(packageUrl: url)
        
        let packageManager = try packageDiscovery.packageManager()
        
        let fileManagerDelegate = DiskFileManagerDelegate()
        let delegate = DefaultDependencyCheckerDelegate()
        
        let dependencyChecker =
            DependencyChecker(options: options,
                              packageManager: packageManager,
                              fileManagerDelegate: fileManagerDelegate)

        dependencyChecker.delegate = delegate
        
        try dependencyChecker.inspect()
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
