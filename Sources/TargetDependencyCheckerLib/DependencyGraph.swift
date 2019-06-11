class DependencyGraph: DirectedGraph {
    private(set) var nodes: [Target] = []
    private(set) var edges: [Edge] = []
    
    init(package: Package) throws {
        nodes = package.targets
        try createGraphEdges()
    }
    
    @inlinable
    func areNodesEqual(_ node1: Target, _ node2: Target) -> Bool {
        return node1.name == node2.name
    }
    
    @inlinable
    func startNode(for edge: Edge) -> Target {
        return nodes[edge.startIndex]
    }
    
    @inlinable
    func endNode(for edge: Edge) -> Target {
        return nodes[edge.endIndex]
    }
    
    @inlinable
    func edges(from node: Target) -> [Edge] {
        guard let index = nodeIndex(for: node.name) else {
            return []
        }
        
        return edges.filter { $0.startIndex == index }
    }
    
    @inlinable
    func edges(towards node: Target) -> [Edge] {
        guard let index = nodeIndex(for: node.name) else {
            return []
        }
        
        return edges.filter { $0.endIndex == index }
    }
    
    @inlinable
    func edge(from start: Target, to end: Target) -> Edge? {
        guard let startIndex = nodeIndex(for: start.name) else {
            return nil
        }
        guard let endIndex = nodeIndex(for: end.name) else {
            return nil
        }
        
        return edges.first(where: { $0.startIndex == startIndex && $0.endIndex == endIndex })
    }
}

// MARK: - Higher level methods
extension DependencyGraph {
    func targetsDepending(on target: Target) -> [Target] {
        return nodesConnected(from: target)
    }
    
    func dependencies(of target: Target) -> [Target] {
        return nodesConnected(towards: target)
    }
    
    func targetsDepending(on targetName: String) -> [Target] {
        if let index = nodeIndex(for: targetName) {
            return edges.lazy.filter { $0.startIndex == index }.map { nodes[$0.endIndex] }
        }
        
        return []
    }
    
    func dependencies(of targetName: String) -> [Target] {
        if let index = nodeIndex(for: targetName) {
            return edges.lazy.filter { $0.endIndex == index }.map { nodes[$0.startIndex] }
        }
        
        return []
    }
}

private extension DependencyGraph {
    func createGraphEdges() throws {
        for target in nodes {
            for dependency in target.dependencies {
                guard let startIndex = nodeIndex(for: dependency.name) else {
                    continue
                }
                guard let endIndex = nodeIndex(for: target.name) else {
                    continue
                }
                
                guard self.edge(from: nodes[startIndex], to: nodes[endIndex]) == nil else {
                    continue
                }
                
                createEdge(from: startIndex, to: endIndex)
            }
        }
        
        if topologicalSorted() == nil {
            throw Error.cyclicDependency
        }
    }
    
    func createEdge(from startIndex: Int, to endIndex: Int) {
        let edge = Edge(startIndex: startIndex, endIndex: endIndex)
        edges.append(edge)
    }
    
    func nodeIndex(for targetName: String) -> Int? {
        nodes.firstIndex(where: { $0.name == targetName })
    }
}

extension DependencyGraph {
    class Edge: DirectedGraphEdge {
        var startIndex: Int
        var endIndex: Int
        
        init(startIndex: Int, endIndex: Int) {
            self.startIndex = startIndex
            self.endIndex = endIndex
        }
    }
}

extension DependencyGraph {
    enum Error: Swift.Error {
        case cyclicDependency
    }
}

extension Target: DirectedGraphNode { }
