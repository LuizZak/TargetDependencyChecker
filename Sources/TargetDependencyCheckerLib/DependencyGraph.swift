class DependencyGraph: DirectedGraph {
    private(set) var nodes: Set<String> = []
    private(set) var edges: Set<Edge> = []
    
    init(package: Package) throws {
        nodes = Set(package.targets.map { $0.name })
        try createGraphEdges(targets: package.targets)
    }
    
    @inlinable
    func startNode(for edge: Edge) -> String {
        return edge.start
    }
    
    @inlinable
    func endNode(for edge: Edge) -> String {
        return edge.end
    }
    
    @inlinable
    func edges(from node: String) -> Set<Edge> {
        return edges.filter { $0.start == node }
    }
    
    @inlinable
    func edges(towards node: String) -> Set<Edge> {
        return edges.filter { $0.end == node }
    }
    
    @inlinable
    func edge(from start: String, to end: String) -> Edge? {
        return edges.first(where: { $0.start == start && $0.end == end })
    }
}

// MARK: - Higher level methods
extension DependencyGraph {
    func targetsDepending(on targetName: String) -> Set<String> {
        return Set(edges.lazy.filter { $0.start == targetName }.map { $0.end })
    }
    
    func dependencies(of targetName: String) -> Set<String> {
        return Set(edges.lazy.filter { $0.end == targetName }.map { $0.start })
    }
}

private extension DependencyGraph {
    func createGraphEdges(targets: [Target]) throws {
        for target in targets {
            for dependency in target.dependencies {
                guard self.edge(from: dependency.name, to: target.name) == nil else {
                    continue
                }
                
                createEdge(from: dependency.name, to: target.name)
            }
        }
        
        if topologicalSorted() == nil {
            throw Error.cyclicDependency
        }
    }
    
    func createEdge(from start: String, to end: String) {
        let edge = Edge(start: start, end: end)
        edges.insert(edge)
    }
}

extension DependencyGraph {
    class Edge: Hashable {
        var start: String
        var end: String
        
        init(start: String, end: String) {
            self.start = start
            self.end = end
        }
        
        static func == (lhs: Edge, rhs: Edge) -> Bool {
            return lhs === rhs
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }
    }
}

extension DependencyGraph {
    enum Error: Swift.Error {
        case cyclicDependency
    }
}
