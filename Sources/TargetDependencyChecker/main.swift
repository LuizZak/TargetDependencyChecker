import ArgumentParser

struct SwiftRewriterCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "TargetDependencyChecker",
        discussion: """
        Tools for inspecting dependency checkers in Swift Package Manager projects.
        """,
        subcommands: [CheckCommand.self, GraphVizCommand.self],
        defaultSubcommand: CheckCommand.self)
    
    func run() throws {
        
    }
}

SwiftRewriterCommand.main()
