@testable import TargetDependencyCheckerLib

class PackageBuilder {
    var _name: String = "TestPackage"
    var _targets: [Target] = []
    
    init(_ closure: (PackageBuilder) -> Void = { _ in }) {
        closure(self)
    }

    @discardableResult
    func name(_ name: String) -> PackageBuilder {
        _name = name
        return self
    }
    
    @discardableResult
    func addTarget(name: String, path: String? = nil, type: Target.TargetType = .regular, _ closure: (TargetBuilder) -> Void = { _ in }) -> PackageBuilder {
        let builder = TargetBuilder(name: name, path: path, type: type)
        closure(builder)
        
        _targets.append(builder.build())
        
        return self
    }
    
    func build() -> Package {
        return Package(name: _name, targets: _targets)
    }
}

class TargetBuilder {
    var _name: String
    var _path: String?
    var _type: Target.TargetType = .regular
    var _dependencies: [TargetDependency] = []
    
    init(name: String, path: String?, type: Target.TargetType) {
        _name = name
        _path = path
        _type = type
    }
    
    @discardableResult
    func name(_ name: String) -> TargetBuilder {
        _name = name
        return self
    }

    @discardableResult
    func type(_ type: Target.TargetType) -> TargetBuilder {
        _type = type
        return self
    }

    @discardableResult
    func path(_ path: String?) -> TargetBuilder {
        _path = path
        return self
    }
    
    @discardableResult
    func addDependency(_ name: String, type: TargetDependency.TargetDependencyType = .byName) -> TargetBuilder {
        _dependencies.append(TargetDependency(name: name, type: type))
        return self
    }
    
    @discardableResult
    func addDependencies(_ names: String..., type: TargetDependency.TargetDependencyType = .byName) -> TargetBuilder {
        _dependencies.append(contentsOf: names.map { .init(name: $0, type: type) })
        return self
    }
    
    func build() -> Target {
        return Target(name: _name, path: _path, dependencies: _dependencies, type: _type)
    }
}
