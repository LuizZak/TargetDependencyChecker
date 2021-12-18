import Foundation

public class GraphVizGenerator {
    let packageManager: PackageManager
    let fileManagerDelegate: FileManagerDelegate

    init(packageManager: PackageManager, fileManagerDelegate: FileManagerDelegate) {
        self.packageManager = packageManager
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    public func generateFile(includeIndirect: Bool, includeTests: Bool) throws -> String {
        let inspections = try DependencyChecker.collectInspectionTargets(
            packageManager: packageManager,
            fileManagerDelegate: fileManagerDelegate,
            includePattern: nil,
            excludePattern: nil
        )
        
        let graph = try packageManager.dependencyGraph()
        let graphViz = GraphViz()

        for target in packageManager.targets.sorted(by: { $0.name < $1.name }) {
            if !includeTests && target.type == .test {
                continue
            }

            graphViz.createNode(label: target.name)
        }

        // Add explicit dependencies
        for edge in graph.edges {
            let startIsTest = packageManager.target(withName: edge.start)?.type == .test
            let endIsTest = packageManager.target(withName: edge.end)?.type == .test
            if !includeTests && (startIsTest || endIsTest) {
                continue
            }

            graphViz.addConnection(fromLabel: edge.start, toLabel: edge.end)
        }

        // Add implicit dependencies
        for inspection in inspections {
            if !includeTests && inspection.target.type == .test {
                continue
            }

            let target = inspection.target.name

            var visited: Set<String> = []

            for importDecl in inspection.importedFrameworks {
                let framework = importDecl.frameworkName
                if !includeTests && packageManager.target(withName: framework)?.type == .test {
                    continue
                }
                
                guard visited.insert(framework).inserted else {
                    continue
                }
                guard graph.hasNode(framework) else {
                    continue
                }

                let filePath = importDecl.location.file.map { file in
                    file.replacingOccurrences(of: packageManager.packageRootUrl.path, with: "")
                }

                var include = false
                var color: String? = nil

                if !graph.hasPath(from: framework, to: target) {
                    include = true
                    color = "red"
                } else if includeIndirect && !graph.hasEdge(from: framework, to: target) {
                    include = true
                }

                if include {
                    graphViz.addConnection(fromLabel: framework, toLabel: target, label: "@ \(filePath ?? "<unknown>")", color: color)
                }
            }
        }

        return graphViz.generateFile()
    }
    
    public enum OutputType {
        case terminal
        case file(URL)
        case callback((String) -> Void)
    }

    private class GraphViz {
        typealias NodeId = Int

        private var _nextId: Int = 0

        private var nodes: [Node]
        private var connections: [Connection]

        init() {
            nodes = []
            connections = []
        }

        func generateFile() -> String {
            let out = StringOutput()

            out(lineAndIndent: "digraph {") {
                out(line: "graph [rankdir=LR]")
                out()

                for node in nodes {
                    out(line: #"\#(node.id) [label="\#(node.label)"]"#)
                }

                out()

                for connection in connections.sorted() {
                    let conString = "\(connection.idTo) -> \(connection.idFrom)"
                    var properties: [(name: String, value: String)] = []

                    if let label = connection.label {
                        properties.append(("label", #""\#(label)""#))
                    }
                    if let color = connection.color {
                        properties.append(("color", color))
                    }

                    if !properties.isEmpty {
                        let propString = properties.map { "\($0.name)=\($0.value)" }.joined(separator: ", ")

                        out(line: conString + " [\(propString)]")
                    } else {
                        out(line: conString)
                    }
                }
            }
            out(line: "}")

            return out.buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        @discardableResult
        func createNode(label: String) -> NodeId {
            defer { _nextId += 1 }

            let id = _nextId

            let node = Node(id: id, label: label)
            nodes.append(node)

            return node.id
        }

        func nodeId(forLabel label: String) -> NodeId? {
            nodes.first { $0.label == label }?.id
        }

        func getOrCreate(label: String) -> NodeId {
            if let id = nodeId(forLabel: label) {
                return id
            }

            let id = createNode(label: label)

            return id
        }

        func addConnection(fromLabel: String, toLabel: String, label: String? = nil, color: String? = nil) {
            let from = getOrCreate(label: fromLabel)
            let to = getOrCreate(label: toLabel)

            addConnection(from: from, to: to, label: label, color: color)
        }

        func addConnection(from: NodeId, to: NodeId, label: String? = nil, color: String? = nil) {
            connections.append(.init(idFrom: from, idTo: to, label: label, color: color))
        }

        private struct Node: Comparable {
            var id: NodeId
            var label: String

            static func < (lhs: Self, rhs: Self) -> Bool {
                lhs.label < rhs.label
            }
        }

        private struct Connection: Comparable {
            var idFrom: NodeId
            var idTo: NodeId
            var label: String?
            var color: String?

            static func < (lhs: Self, rhs: Self) -> Bool {
                guard lhs.idTo == rhs.idTo else {
                    return lhs.idTo < rhs.idTo
                }
                guard lhs.idFrom == rhs.idFrom else {
                    return lhs.idFrom < rhs.idFrom
                }
                
                switch (lhs.label, rhs.label) {
                case (nil, nil):
                    return false
                case (let a?, let b?):
                    return a < b
                case (_?, _):
                    return true
                case (_, _?):
                    return false
                }
            }
        }
    }
}

/// Outputs to a string buffer
private final class StringOutput {
    var indentDepth: Int = 0
    var ignoreCallChange = false
    private(set) public var buffer: String = ""
    
    init() {
        
    }

    func callAsFunction() {
        output(line: "")
    }

    func callAsFunction(line: String) {
        output(line: line)
    }

    func callAsFunction(lineAndIndent line: String, _ block: () -> Void) {
        output(line: line)
        indented(perform: block)
    }
    
    func outputRaw(_ text: String) {
        buffer += text
    }
    
    func output(line: String) {
        if !line.isEmpty {
            outputIndentation()
            buffer += line
        }
        
        outputLineFeed()
    }
    
    func outputIndentation() {
        buffer += indentString()
    }
    
    func outputLineFeed() {
        buffer += "\n"
    }
    
    func outputInline(_ content: String) {
        buffer += content
    }
    
    func increaseIndentation() {
        indentDepth += 1
    }
    
    func decreaseIndentation() {
        guard indentDepth > 0 else { return }
        
        indentDepth -= 1
    }
    
    func outputInlineWithSpace(_ content: String) {
        outputInline(content)
        outputInline(" ")
    }
    
    func indented(perform block: () -> Void) {
        increaseIndentation()
        block()
        decreaseIndentation()
    }
    
    private func indentString() -> String {
        return String(repeating: " ", count: 4 * indentDepth)
    }
}
