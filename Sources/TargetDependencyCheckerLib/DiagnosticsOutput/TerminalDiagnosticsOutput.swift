import Foundation
import SwiftSyntax
import Console

class TerminalDiagnosticsOutput: DiagnosticsOutput {
    private var _warningsCount: Int = 0
    private var _printFullPaths: Bool
    private var _colorized: Bool
    
    init(colorized: Bool, printFullPaths: Bool) {
        self._colorized = colorized
        self._printFullPaths = printFullPaths
    }

    func startReport(_ checker: DependencyChecker) {
        _print("Analyzing package \(packageName: checker.packageManager.package.name)...")
    }

    func reportNonDependencyImport(_ checker: DependencyChecker,
                                   importDecl: ImportedFrameworkDeclaration,
                                   target: Target,
                                   file: SourceFile,
                                   relativePath: String) {
        _warningsCount += 1
        
        _print("""
            \(critical: "!Warning!:") \
            \(targetName: target.name): \
            Import of framework \(frameworkName: importDecl.frameworkName) \
            in file \(filePath: _selectPath(file: file, relativePath: relativePath)):\(lineNumber: importDecl.location.line) \
            is not declared as a dependency, either directly or indirectly, in Package.swift manifest.
            """)
    }
    
    func reportNonDirectDependencyImport(_ checker: DependencyChecker,
                                         importDecl: ImportedFrameworkDeclaration,
                                         target: Target,
                                         dependenciesPath: [String],
                                         file: SourceFile,
                                         relativePath: String) {
        _warningsCount += 1
        
        _print("""
            \(warning: "Indirect-dependency") \
            in target \(targetName: target.name): \
            Import of framework \(frameworkName: importDecl.frameworkName) \
            in file \(filePath: _selectPath(file: file, relativePath: relativePath)):\(lineNumber: importDecl.location.line) \
            with \(dependenciesPath.count - 2) level(s) of indirection: \(dependenciesPath: dependenciesPath)
            """)
    }

    func finishReport(_ checker: DependencyChecker) {
        _print("Analysis complete! Found \(_warningsCount, color: .cyan) issue(s).")
    }

    private func _selectPath(file: SourceFile, relativePath: String) -> String {
        _printFullPaths ? file.path.path : relativePath
    }

    private func _print(_ string: ConsoleColorInterpolatedString) {
        print(string.toString(colorized: _colorized))
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
        private let _criticalColor: ConsoleColor = .red
        private let _warningColor: ConsoleColor = .yellow
        private let _projectNameColor: ConsoleColor = .cyan
        private let _frameworkNameColor: ConsoleColor = .cyan
        private let _targetNameColor: ConsoleColor = .cyan
        private let _indirectTargetNameColor: ConsoleColor = .blue
        private let _lineNumberColor: ConsoleColor = .cyan
        private let _filePathColor: ConsoleColor = .magenta
        private let _fileNameColor: ConsoleColor = .cyan

        private var _currentColor: ConsoleColor? = nil

        var output: [(String, ConsoleColor?)] = []

        init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity)
        }

        mutating func appendInterpolation(setColor: ConsoleColor?) {
            _currentColor = setColor
        }

        mutating func appendLiteral(_ literal: String) {
            _append(literal, color: _currentColor)
        }

        mutating func appendInterpolation<T>(_ literal: T) {
            _append("\(literal)", color: _currentColor)
        }

        mutating func appendInterpolation(critical: String) {
            _append(critical, color: _criticalColor)
        }

        mutating func appendInterpolation(warning: String) {
            _append(warning, color: _warningColor)
        }

        mutating func appendInterpolation<T>(frameworkName: T) {
            _append("\(frameworkName)", color: _frameworkNameColor)
        }

        mutating func appendInterpolation<T>(targetName: T) {
            _append("\(targetName)", color: _targetNameColor)
        }

        mutating func appendInterpolation(lineNumber: Int?) {
            _append("\(lineNumber?.description ?? "<unknown>")", color: _lineNumberColor)
        }

        mutating func appendInterpolation(dependenciesPath: [String]) {
            guard dependenciesPath.count > 2 else {
                return
            }
            
            _append("\(dependenciesPath[0])", color: _targetNameColor)

            for dependency in dependenciesPath.dropFirst().dropLast() {
                _append(" -> ", color: nil)
                _append("\(dependency)", color: _indirectTargetNameColor)
            }

            _append(" -> ", color: nil)
            _append("\(dependenciesPath[dependenciesPath.count - 1])", color: _targetNameColor)
        }

        mutating func appendInterpolation<T>(packageName: T) {
            _append("\(packageName)", color: _projectNameColor)
        }

        mutating func appendInterpolation(filePath: String) {
            let url = URL(fileURLWithPath: filePath, relativeTo: nil)

            _append(url.deletingLastPathComponent().relativePath, color: _filePathColor)
            _append("/", color: _filePathColor)
            _append(url.lastPathComponent, color: _fileNameColor)
        }

        mutating func appendInterpolation<T>(_ literal: T, color: ConsoleColor) {
            _append("\(literal)", color: color)
        }

        private mutating func _append(_ text: String, color: ConsoleColor?) {
            output.append((text, color))
        }
    }
}
