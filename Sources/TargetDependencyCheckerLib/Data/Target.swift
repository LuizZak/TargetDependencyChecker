struct Target: Decodable, Hashable {
    var name: String
    var path: String?
    var dependencies: [TargetDependency]
    var type: TargetType
    
    init(name: String, path: String?, dependencies: [TargetDependency], type: Target.TargetType) {
        self.name = name
        self.path = path
        self.dependencies = dependencies
        self.type = type
    }
    
    init(from decoder: Decoder) throws {        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        try name = container.decode(String.self, forKey: .name)
        try path = container.decodeIfPresent(String.self, forKey: .path)
        try type = container.decode(TargetType.self, forKey: .type)
        
        let dep = try container.decode([DependenciesArray].self, forKey: .dependencies)
        
        dependencies = dep.flatMap { $0.byName?.compactMap { $0.map(TargetDependency.init) } ?? [] }
    }
    
    enum TargetType: String, Decodable {
        case regular
        case test
        case executable
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case path
        case dependencies
        case type
    }

    struct DependenciesArray: Decodable {
        var byName: [String?]?
    }
}

struct TargetDependency: Decodable, Hashable {
    var name: String
}
