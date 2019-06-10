struct Target: Decodable {
    var name: String
    var path: String?
    var dependencies: [TargetDependency]
    var type: TargetType
    
    enum TargetType: String, Decodable {
        case regular
        case test
    }
}

struct TargetDependency: Decodable {
    var byName: [String]
}
