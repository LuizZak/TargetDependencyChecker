import TargetDependencyCheckerLib
import Utility

extension OutputType: ArgumentKind {
    public init(argument: String) throws {
        if let value = OutputType(rawValue: argument) {
            self = value
        } else {
            throw ArgumentParserError.invalidValue(
                argument: argument,
                error: ArgumentConversionError.custom("Expected either 'terminal' or 'xcode'")
            )
        }
    }
    
    public static var completion: ShellCompletion {
        return ShellCompletion.values([
            ("terminal", "Prints output of conversion in a format proper for terminal's standard output."),
            ("xcode", """
                Prints output with leading file/line numbers as warnings that \
                Xcode can detect when used as a build phase.
                """)
            ])
    }
}
