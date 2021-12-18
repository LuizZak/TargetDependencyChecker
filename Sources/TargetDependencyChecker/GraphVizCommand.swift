import Foundation
import ArgumentParser
import TargetDependencyCheckerLib

struct GraphVizCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "graph",
        discussion: """
        Produces a GraphViz .dot file describing the internal dependency graph \
        of a Swift Package Manager project.
        """)
        
    @Option(name: .shortAndLong, help: """
            Specifies the path for the directory containing a Package.swift \
            manifest for a Swift Package Manager project.
            If not specified, defaults to the current working directory.
            """)
    var packagePath: String?
    
    @Option(name: .shortAndLong, help: """
            A .dot file to write the results to, relative to the current working \
            directory. If not provided, prints the result to stdout, instead.
            """)
    var output: String?
    
    @Flag(name: .shortAndLong, help: """
        Whether to include indirect dependencies via `import` statements on \
        target's files.
        """)
    var includeIndirect: Bool = false

    @Flag(name: [.long, .customShort("t")], help: """
        Whether to include test targets in the graph.
        """)
    var includeTests: Bool = false

    func run() throws {
        var options = GraphVizEntryPoint.Options()
        
        options.packageDirectory = packagePath.map(URL.init(fileURLWithPath:)) ?? options.packageDirectory
        
        if let output = output {
            options.outputType = .file(URL(fileURLWithPath: output, relativeTo: workDirectory()))
        }

        options.includeIndirect = includeIndirect
        options.includeTests = includeTests
        
        try GraphVizEntryPoint.main(options: options)
    }
}
