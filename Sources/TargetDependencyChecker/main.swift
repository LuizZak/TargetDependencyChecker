import Foundation
import Utility
import TargetDependencyCheckerLib

func main() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())

    let options = try Arguments.parse(arguments: arguments)
    
    try Checker.main(options: options)
}

try main()
