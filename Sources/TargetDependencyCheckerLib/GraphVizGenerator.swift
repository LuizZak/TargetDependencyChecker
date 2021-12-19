import Foundation

public class GraphVizGenerator {
    let packageManager: PackageManager
    let fileManagerDelegate: FileManagerDelegate

    init(packageManager: PackageManager, fileManagerDelegate: FileManagerDelegate) {
        self.packageManager = packageManager
        self.fileManagerDelegate = fileManagerDelegate
    }
    
    public func generateFile(includeIndirect: Bool, includeTests: Bool, includeFolderHierarchy: Bool) throws -> String {
        let rootPathComponents = packageManager.packageRootUrl.pathComponents

        func hierarchyFor(target: Target) -> [String] {
            if !includeFolderHierarchy {
                return []
            }

            guard let path = packageManager.sourcePath(for: target) else {
                return []
            }

            let components = path.pathComponents
            var index = 0
            for i in 0..<rootPathComponents.count {
                index = i

                if rootPathComponents[i] != components[i] {
                    break
                }
            }

            return Array(components[index..<components.count - 1])
        }

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

            graphViz.createNode(label: target.name, groups: hierarchyFor(target: target))
        }

        // Add explicit dependencies
        for edge in graph.edges {
            // Ignore targets that are not defined within this package
            guard let start = packageManager.target(withName: edge.start) else {
                continue
            }
            guard let end = packageManager.target(withName: edge.end) else {
                continue
            }

            if !includeTests && (start.type == .test || end.type == .test) {
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
                guard visited.insert(framework).inserted else {
                    continue
                }

                guard let frameworkTarget = packageManager.target(withName: framework) else {
                    continue
                }
                if !includeTests && frameworkTarget.type == .test {
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
}
