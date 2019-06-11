import Foundation
import TargetDependencyCheckerLib

func main() throws {
    let arguments = CommandLine.arguments.dropFirst()

    var options = Checker.Options()
    
    if arguments.contains("--warn-indirect-dependencies") {
        options.warnIndirectDependencies = true
    }
    if arguments.contains("--warn-once-per-framework") {
        options.warnOncePerFramework = true
    }
    if let index = arguments.firstIndex(of: "--package-path") {
        if arguments.count <= index {
            print("error: expected path for framework after --package-path")
            exit(1)
        }
        
        let path = arguments[index + 1]
        options.packageDirectory = URL(fileURLWithPath: path)
    }
    if let index = arguments.firstIndex(of: "--output-type") {
        if arguments.count <= index {
            print("error: expected either 'terminal' or 'xcode' after --output-type")
            exit(1)
        }
        
        let type = arguments[index + 1]
        switch type {
        case "terminal":
            options.outputType = .terminal
        case "xcode":
            options.outputType = .xcode
            
        default:
            print("error: expected either 'terminal' or 'xcode' after --output-type")
            exit(1)
        }
    }
    
    try Checker.main(options: options)
}

try main()
