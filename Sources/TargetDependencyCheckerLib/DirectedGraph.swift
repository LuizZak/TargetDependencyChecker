/// A protocol for representing directed graphs
public protocol DirectedGraph {
    associatedtype Edge: Hashable
    associatedtype Node: Hashable
    
    /// Gets a list of all nodes in this directed graph
    var nodes: Set<Node> { get }
    /// Gets a list of all edges in this directed graph
    var edges: Set<Edge> { get }
    
    /// Returns the starting node for a given edge on this graph.
    @inlinable
    func startNode(for edge: Edge) -> Node
    
    /// Returns the ending node for a given edge on this graph.
    @inlinable
    func endNode(for edge: Edge) -> Node
    
    /// Returns all ingoing and outgoing edges for a given directed graph node.
    @inlinable
    func allEdges(for node: Node) -> Set<Edge>
    
    /// Returns all outgoing edges for a given directed graph node.
    @inlinable
    func edges(from node: Node) -> Set<Edge>
    
    /// Returns all ingoing edges for a given directed graph node.
    @inlinable
    func edges(towards node: Node) -> Set<Edge>
    
    /// Returns an existing edge between two nodes, or `nil`, if no edges between
    /// them currently exist.
    @inlinable
    func edge(from start: Node, to end: Node) -> Edge?
    
    /// Returns all graph nodes `<n>` that are connected from a given directed
    /// graph node, in `node -> <n>` fashion.
    @inlinable
    func nodesConnected(from node: Node) -> Set<Node>
    
    /// Returns all graph nodes `<n>` that are connected towards a given directed
    /// graph node, in `<n> -> node` fashion.
    @inlinable
    func nodesConnected(towards node: Node) -> Set<Node>
    
    /// Returns all graph nodes that are connected towards and from the given
    /// graph node.
    @inlinable
    func allNodesConnected(to node: Node) -> Set<Node>
    
    /// Performs a depth-first visiting of this directed graph, finishing once
    /// all nodes are visited, or when `visitor` returns false.
    @inlinable
    func depthFirstVisit(start: Node, _ visitor: (DirectedGraphVisitElement<Edge, Node>) -> Bool)
    
    /// Performs a breadth-first visiting of this directed graph, finishing once
    /// all nodes are visited, or when `visitor` returns false.
    @inlinable
    func breadthFirstVisit(start: Node, _ visitor: (DirectedGraphVisitElement<Edge, Node>) -> Bool)
}

/// Element for a graph visiting operation.
///
/// - root: The item represents the root of a directed graph
/// - edge: The item represents an edge, pointing to a node of the graph
public enum DirectedGraphVisitElement<E, N> {
    case root(N)
    case edge(E, towards: N)
    
    public var node: N {
        switch self {
        case .root(let node),
             .edge(_, let node):
            return node
        }
    }
}

public extension DirectedGraph {
    @inlinable
    func allEdges(for node: Node) -> Set<Edge> {
        return edges(towards: node).union(edges(from: node))
    }
    
    @inlinable
    func nodesConnected(from node: Node) -> Set<Node> {
        return Set(edges(from: node).map(self.endNode(for:)))
    }
    
    @inlinable
    func nodesConnected(towards node: Node) -> Set<Node> {
        return Set(edges(towards: node).map(self.startNode(for:)))
    }
    
    @inlinable
    func allNodesConnected(to node: Node) -> Set<Node> {
        return nodesConnected(towards: node).union(nodesConnected(from: node))
    }
    
    /// Performs a depth-first visiting of this directed graph, finishing once
    /// all nodes are visited, or when `visitor` returns false.
    @inlinable
    func depthFirstVisit(start: Node, _ visitor: (DirectedGraphVisitElement<Edge, Node>) -> Bool) {
        var visited: Set<Node> = []
        var queue: [DirectedGraphVisitElement<Edge, Node>] = []
        
        queue.append(.root(start))
        
        while let next = queue.popLast() {
            visited.insert(next.node)
            
            if !visitor(next) {
                return
            }
            
            for nextEdge in edges(from: next.node) {
                let node = endNode(for: nextEdge)
                if visited.contains(node) {
                    continue
                }
                
                queue.append(.edge(nextEdge, towards: node))
            }
        }
    }
    
    /// Performs a breadth-first visiting of this directed graph, finishing once
    /// all nodes are visited, or when `visitor` returns false.
    @inlinable
    func breadthFirstVisit(start: Node, _ visitor: (DirectedGraphVisitElement<Edge, Node>) -> Bool) {
        var visited: Set<Node> = []
        var queue: [DirectedGraphVisitElement<Edge, Node>] = []
        
        queue.append(.root(start))
        
        while !queue.isEmpty {
            let next = queue.removeFirst()
            visited.insert(next.node)
            
            if !visitor(next) {
                return
            }
            
            for nextEdge in edges(from: next.node) {
                let node = endNode(for: nextEdge)
                if visited.contains(node) {
                    continue
                }
                
                queue.append(.edge(nextEdge, towards: node))
            }
        }
    }
}

public extension DirectedGraph {
    /// Returns a list which represents the [topologically sorted](https://en.wikipedia.org/wiki/Topological_sorting)
    /// nodes of this graph.
    ///
    /// Returns nil, in case it cannot be topologically sorted, e.g. when any
    /// cycles are found.
    ///
    /// - Returns: A list of the nodes from this graph, topologically sorted, or
    /// `nil`, in case it cannot be sorted.
    @inlinable
    func topologicalSorted() -> [Node]? {
        var permanentMark: Set<Node> = []
        var temporaryMark: Set<Node> = []
        
        var unmarkedNodes: Set<Node> = nodes
        var list: [Node] = []
        
        func visit(_ node: Node) -> Bool {
            if permanentMark.contains(node) {
                return true
            }
            if temporaryMark.contains(node) {
                return false
            }
            temporaryMark.insert(node)
            for next in nodesConnected(from: node) {
                if !visit(next) {
                    return false
                }
            }
            permanentMark.insert(node)
            list.insert(node, at: 0)
            return true
        }
        
        while !unmarkedNodes.isEmpty {
            let node = unmarkedNodes.removeFirst()
            
            if !visit(node) {
                return nil
            }
        }
        
        return list
    }
    
    /// Returns true if there exists a path in this graph that connect two given
    /// nodes.
    ///
    /// In case the two nodes are not connected, or are connected in the opposite
    /// direction, false is returned.
    @inlinable
    func hasPath(from start: Node, to end: Node) -> Bool {
        var found = false
        breadthFirstVisit(start: start) { visit in
            if visit.node == end {
                found = true
                return false
            }
            
            return true
        }
        
        return found
    }
    
    /// Returns true if there exists an edge that connects two nodes on the
    /// specified direction.
    @inlinable
    func hasEdge(from start: Node, to end: Node) -> Bool {
        return edge(from: start, to: end) != nil
    }
}
