import Foundation

public enum DependencyCheckerEntryPoint {
    public struct Options {
        /// When specified, warns when importing a target that is not a direct
        /// dependency into another target.
        public var warnIndirectDependencies: Bool
        
        /// When specified, omits warnings of violations for frameworks that
        /// where already reported in previous files in the same target.
        public var warnOncePerFramework: Bool
        
        /// Specifies the path for the directory containing a Package.swift
        /// manifest for a Swift Package Manager project.
        public var packageDirectory: URL?
        
        /// Specifies the format of the output.
        public var outputType: OutputType

        /// Whether to colorize terminal output.
        public var colorized: Bool

        /// Whether to print full file paths when producing terminal output.
        public var printFullPaths: Bool
        
        // TODO: Tie in `includePattern` and `excludePattern` to command line
        // arguments
        public var includePattern: String?
        public var excludePattern: String?
        
        /// Ignores all includes in the string separated by commas provided to
        /// this argument.
        public var ignoreIncludes: Set<String>
        
        public init(warnIndirectDependencies: Bool = false,
                    warnOncePerFramework: Bool = false,
                    packageDirectory: URL? = nil,
                    outputType: OutputType = .terminal,
                    colorized: Bool = true,
                    printFullPaths: Bool = false,
                    includePattern: String? = nil,
                    excludePattern: String? = nil,
                    ignoreIncludes: Set<String> = []) {
            
            self.warnIndirectDependencies = warnIndirectDependencies
            self.warnOncePerFramework = warnOncePerFramework
            self.packageDirectory = packageDirectory
            self.outputType = outputType
            self.colorized = colorized
            self.printFullPaths = printFullPaths
            self.includePattern = includePattern
            self.excludePattern = excludePattern
            self.ignoreIncludes = ignoreIncludes
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let url = options.packageDirectory ?? workDirectory()
        
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
    
    public enum OutputType: String {
        case terminal
        case xcode

        func diagnosticsOutput(colorized: Bool, printFullPaths: Bool) -> DiagnosticsOutput {
            switch self {
            case .terminal:
                return TerminalDiagnosticsOutput(colorized: colorized, printFullPaths: printFullPaths)
            case .xcode:
                return XcodeDiagnosticsOutput()
            }
        }
    }
}
