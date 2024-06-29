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
        
        dependencies = []

        for dependency in dep {
            if let byName = dependency.byName {
                for byName in byName.compactMap({$0}) {
                    dependencies.append(
                        .init(name: byName, type: .byName)
                    )
                }
            }
            if let product = dependency.product {
                let productArgs = product.compactMap({$0})
                guard productArgs.count == 2 else {
                    continue
                }

                dependencies.append(
                    .init(name: productArgs[0], type: .product(package: productArgs[1]))
                )
            }
        }
    }
    
    enum TargetType: String, Decodable {
        case regular
        case test
        case executable
        case snippets
        case macro
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case path
        case dependencies
        case type
    }

    struct DependenciesArray: Decodable {
        var byName: [String?]?
        var product: [String?]?
    }
}

struct TargetDependency: Hashable {
    var name: String
    var type: TargetDependencyType
    
    enum TargetDependencyType: Hashable {
        case byName
        case product(package: String)
    }
}
