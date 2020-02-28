import TargetDependencyCheckerLib
import Foundation
import ArgumentParser

struct CheckCommand: ParsableCommand {
    @Option(name: .shortAndLong, help: """
            Specifies the path for the directory containing a Package.swift \
            manifest for a Swift Package Manager project.
            If not specified, defaults to the current working directory.
            """)
    var packagePath: String?
    
    @Option(name: [.long, .customShort("t")], help: """
            Specifies the format of the output.
            Defaults to 'terminal' if not provided.
            
                terminal
                    Prints output of conversion in a format proper for \
            terminal's standard output.
                
                xcode
                    Prints output with leading file/line numbers as warnings \
            that Xcode can detect when used as a build phase.
            
            """)
    var outputType: OutputType?
    
    @Flag(name: [.long, .customShort("o")], help: """
            When specified, omits warnings of violations for frameworks that \
            where already reported in previous files in the same target.
            """)
    var warnOncePerFramework: Bool
    
    @Flag(name: [.long, .customShort("i")], help: """
            When specified, warns when importing a target that is not a direct \
            dependency into another target.
            """)
    var warnIndirectDependencies: Bool
    
    @Option(help: """
            Ignores all includes in the string separated by commas provided to \
            this argument.
            """)
    var ignoreIncludes: String?
    
    func run() throws {
        var options = Checker.Options()
        
        options.packageDirectory = packagePath.map(URL.init(fileURLWithPath:)) ?? options.packageDirectory
        options.outputType = outputType ?? options.outputType
        options.warnOncePerFramework = warnOncePerFramework
        options.warnIndirectDependencies = warnIndirectDependencies
        options.ignoreIncludes = ignoreIncludes.map { $0.components(separatedBy: ",") }.map(Set.init) ?? options.ignoreIncludes
        
        try Checker.main(options: options)
    }
}

extension OutputType: ExpressibleByArgument {
    public init?(argument: String) {
        guard let option = OutputType(rawValue: argument) else {
            return nil
        }
        
        self = option
    }
}
