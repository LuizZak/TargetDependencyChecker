import Foundation

public enum GraphVizEntryPoint {
    public struct Options {
        /// Specifies the path for the directory containing a Package.swift
        /// manifest for a Swift Package Manager project.
        public var packageDirectory: URL?

        /// Specifies the format of the output- either a file or `stdout`.
        public var outputType: OutputType
        
        /// Whether to include indirect dependencies via `import` statements on
        /// target's files.
        public var includeIndirect: Bool

        /// Whether to include test targets in the graph.
        public var includeTests: Bool
        
        public init(packageDirectory: URL? = nil,
                    outputType: OutputType = .terminal,
                    includeIndirect: Bool = false,
                    includeTests: Bool = false) {
            
            self.packageDirectory = packageDirectory
            self.outputType = outputType
            self.includeIndirect = includeIndirect
            self.includeTests = includeTests
        }
    }
    
    public static func main(options: Options = Options()) throws {
        let url = options.packageDirectory ?? workDirectory()
        
        let packageDiscovery = PackageDiscovery(packageUrl: url)
        
        let packageManager = try packageDiscovery.packageManager()
        let fileManagerDelegate = DiskFileManagerDelegate()
        
        let sut = GraphVizGenerator(packageManager: packageManager, fileManagerDelegate: fileManagerDelegate)

        let graphViz = try sut.generateFile(
            includeIndirect: options.includeIndirect,
            includeTests: options.includeTests
        )

        switch options.outputType {
        case .terminal:
            print(graphViz)

        case .file(let targetFilePath):
            let data = graphViz.data(using: .utf8)!

            try fileManagerDelegate.writeContents(data, toFileURL: targetFilePath)
        }
    }
    
    public enum OutputType {
        case terminal
        case file(URL)
    }
}
