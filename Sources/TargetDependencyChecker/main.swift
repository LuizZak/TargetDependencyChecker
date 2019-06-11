import TargetDependencyCheckerLib

func main() throws {
    let arguments = CommandLine.arguments.dropFirst()

    var options = Checker.Options()
    
    if arguments.contains("--warn-indirect-dependencies") {
        options.warnIndirectDependencies = true
    }
    
    try Checker.main(options: options)
}

try main()
