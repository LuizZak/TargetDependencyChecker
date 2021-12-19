import Foundation
import SwiftSyntax
import Console

class TerminalDiagnosticsOutput: DiagnosticsOutput {
    private var _warningsCount: Int = 0

    var colorized: Bool

    init(colorized: Bool) {
        self.colorized = colorized
    }

    func reportNonDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String) {
        _warningsCount += 1

        _print("""
            \("Warning:", color: .yellow) Found import declaration for framework \(importDecl.frameworkName, color: .cyan) in target \(target.name, color: .cyan) \
            in file \(relativePath, color: .magenta), but dependency is not declared in Package.swift manifest, neither \
            directly or indirectly.
            """)
    }
    
    func reportNonDirectDependencyImport(importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         file: SourceFile,
                                         relativePath: String) {
        _warningsCount += 1
        
        _print("""
            \("Indirect-dependency warning:", color: .yellow) Found import declaration for \
            framework \(importDecl.frameworkName) in target \(target.name) in file \
            \(relativePath), but dependency is not declared explicitly \
            in Package.swift manifest.
            """)
    }

    func finishReport() {
        _print("Analysis complete! Found \(_warningsCount, color: .cyan) issue(s).")
    }

    private func _print(_ string: ConsoleColorInterpolatedString) {
        print(string.toString(colorized: colorized))
    }
}

private struct ConsoleColorInterpolatedString: ExpressibleByStringInterpolation {
    var result: [(text: String, color: ConsoleColor?)]

    init(stringLiteral value: String) {
        result = [(value, nil)]
    }

    init(stringInterpolation: StringInterpolation) {
        result = stringInterpolation.output
    }

    func toString(colorized: Bool) -> String {
        return result.map {
            if colorized, let color = $0.color {
                return $0.text.terminalColorize(color)
            } else {
                return $0.text
            }
        }.joined()
    }

    struct StringInterpolation: StringInterpolationProtocol {
        var output: [(String, ConsoleColor?)] = []
        var currentColor: ConsoleColor? = nil

        init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity)
        }

        mutating func appendInterpolation(setColor: ConsoleColor?) {
            currentColor = setColor
        }

        mutating func appendLiteral(_ literal: String) {
            _append(literal, color: currentColor)
        }

        mutating func appendInterpolation<T>(_ literal: T, color: ConsoleColor) {
            _append("\(literal)", color: color)
        }

        mutating func appendInterpolation<T>(_ literal: T) {
            _append("\(literal)", color: currentColor)
        }

        private mutating func _append(_ text: String, color: ConsoleColor?) {
            output.append((text, color))
        }
    }
}
