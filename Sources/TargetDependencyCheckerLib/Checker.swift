import Foundation

public enum Checker {
    public static func main() throws {
        let packageDiscovery = PackageDiscovery()
        
        let package = try packageDiscovery.package()
        
        print(package.targets)
    }
}
