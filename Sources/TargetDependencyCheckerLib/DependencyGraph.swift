class DependencyGraph: DirectedGraph {
    private(set) var nodes: Set<Target> = []
    private(set) var edges: Set<Edge> = []
    
    init(package: Package) throws {
        nodes = Set(package.targets)
        try createGraphEdges()
    }
    
    @inlinable
    func startNode(for edge: Edge) -> Target {
        return edge.start
    }
    
    @inlinable
    func endNode(for edge: Edge) -> Target {
        return edge.end
    }
    
    @inlinable
    func edges(from node: Target) -> Set<Edge> {
        return edges.filter { $0.start == node }
    }
    
    @inlinable
    func edges(towards node: Target) -> Set<Edge> {
        return edges.filter { $0.end == node }
    }
    
    @inlinable
    func edge(from start: Target, to end: Target) -> Edge? {
        return edges.first(where: { $0.start == start && $0.end == end })
    }
}

// MARK: - Higher level methods
extension DependencyGraph {
    func targetsDepending(on target: Target) -> Set<Target> {
        return nodesConnected(from: target)
    }
    
    func dependencies(of target: Target) -> Set<Target> {
        return nodesConnected(towards: target)
    }
    
    func targetsDepending(on targetName: String) -> Set<Target> {
        return Set(edges.lazy.filter { $0.start.name == targetName }.map { $0.end })
    }
    
    func dependencies(of targetName: String) -> Set<Target> {
        return Set(edges.lazy.filter { $0.end.name == targetName }.map { $0.start })
    }
}

private extension DependencyGraph {
    func targetNamed(_ name: String) -> Target? {
        return nodes.first { $0.name == name }
    }
    
    func createGraphEdges() throws {
        for target in nodes {
            for dependency in target.dependencies {
                guard let dependencyTarget = targetNamed(dependency.name) else {
                    continue
                }
                guard self.edge(from: dependencyTarget, to: target) == nil else {
                    continue
                }
                
                createEdge(from: dependencyTarget, to: target)
            }
        }
        
        if topologicalSorted() == nil {
            throw Error.cyclicDependency
        }
    }
    
    func createEdge(from start: Target, to end: Target) {
        let edge = Edge(start: start, end: end)
        edges.insert(edge)
    }
}

extension DependencyGraph {
    class Edge: DirectedGraphEdge {
        var start: Target
        var end: Target
        
        init(start: Target, end: Target) {
            self.start = start
            self.end = end
        }
    }
}

extension DependencyGraph {
    enum Error: Swift.Error {
        case cyclicDependency
    }
}

extension Target: DirectedGraphNode { }
