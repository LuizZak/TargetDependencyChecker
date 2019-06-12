import TargetDependencyCheckerLib
import Foundation
import Utility

class Arguments {
    static func parse(arguments: [String]) throws -> Checker.Options {
        let parser
            = ArgumentParser(
                usage: """
                [--package-path|-p <path>] \
                [--output-type|-t terminal | xcode] \
                [--warn-once-per-framework|-o] \
                [--warn-indirect-dependencies|-i]
                """,
                overview: """
                Reports import statements of targets that are not specified as dependencies \
                on a Package.swift manifest with a SwiftPM project.
                """)
        
        // --package-path
        let packagePathArg
            = parser.add(
                option: "--package-path", shortName: "-p",
                kind: String.self,
                usage: """
                Specifies the path for the directory containing a Package.swift \
                manifest for a Swift Package Manager project.
                If not specified, defaults to the current working directory.
                """)
        
        // --warn-indirect-dependencies
        let warnIndirectDependencies
            = parser.add(option: "--warn-indirect-dependencies", shortName: "-i",
                         kind: Bool.self,
                         usage: """
                            When specified, warns when importing a target that is not \
                            a direct dependency into another target.
                            """)
        
        // --warn-once-per-framework
        let warnOncePerFramework
            = parser.add(option: "--warn-once-per-framework", shortName: "-o",
                         kind: Bool.self,
                         usage: """
                            When specified, omits warnings of violations for frameworks \
                            that where already reported in previous files in the \
                            same target.
                            """)
        
        // --output-type terminal | xcode
        let targetArg
            = parser.add(
                option: "--output-target", shortName: "-t",
                kind: OutputType.self,
                usage: """
                Specifies the format of the output.
                Defaults to 'terminal' if not provided.
                
                    terminal
                        Prints output of conversion in a format proper for terminal's standard output.
                    
                    xcode
                        Prints output with leading file/line numbers as warnings that Xcode can detect when used as a build phase.
                
                """)
        
        // --exclude-pattern
        let excludePatternArg
            = parser.add(
                option: "--exclude-pattern", shortName: "-e",
                kind: String.self,
                usage: """
                Provides a file pattern for excluding from analysis all .swift
                files that match a given pattern.
                Pattern is applied to the full path.
                """)

        // --include-pattern
        let includePatternArg
            = parser.add(
                option: "--include-pattern", shortName: "-i",
                kind: String.self,
                usage: """
                Provides a file pattern for analyzing only .swift files that match
                a given pattern.
                Pattern is applied to the full path. --exclude-pattern takes \
                priority over --include-pattern matches.
                """)
        
        let result = try parser.parse(arguments)
        
        var options = Checker.Options()
        
        options.outputType
            = result.get(targetArg) ?? options.outputType
        
        options.warnIndirectDependencies
            = result.get(warnIndirectDependencies) ?? options.warnIndirectDependencies
        
        options.warnOncePerFramework
            = result.get(warnOncePerFramework) ?? options.warnOncePerFramework
        
        options.packageDirectory
            = result.get(packagePathArg).map(URL.init(fileURLWithPath:)) ?? options.packageDirectory
        
        options.excludePattern
            = result.get(excludePatternArg) ?? options.excludePattern
        
        options.includePattern
            = result.get(includePatternArg) ?? options.includePattern
        
        return options
    }
}
