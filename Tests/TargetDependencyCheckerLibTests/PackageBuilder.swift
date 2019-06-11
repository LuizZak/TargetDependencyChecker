@testable import TargetDependencyCheckerLib

class PackageBuilder {
    var targets: [Target] = []
    
    init(_ closure: (PackageBuilder) -> Void = { _ in }) {
        closure(self)
    }
    
    @discardableResult
    func addTarget(name: String, _ closure: (TargetBuilder) -> Void = { _ in }) -> PackageBuilder {
        let builder = TargetBuilder(name: name)
        closure(builder)
        
        targets.append(builder.build())
        
        return self
    }
    
    func build() -> Package {
        return Package(targets: targets)
    }
}

class TargetBuilder {
    var _name: String
    var _path: String?
    var _dependencies: [TargetDependency] = []
    var _type: Target.TargetType = .regular
    
    init(name: String) {
        _name = name
    }
    
    @discardableResult
    func name(_ name: String) -> TargetBuilder {
        _name = name
        return self
    }
    
    @discardableResult
    func addDependency(_ name: String) -> TargetBuilder {
        _dependencies.append(TargetDependency(name: name))
        return self
    }
    
    @discardableResult
    func addDependencies(_ names: String...) -> TargetBuilder {
        _dependencies.append(contentsOf: names.map(TargetDependency.init))
        return self
    }
    
    func build() -> Target {
        return Target(name: _name, path: _path, dependencies: _dependencies, type: _type)
    }
}
