import Foundation

public enum Checker {
    public static func main() throws {
        let packageDiscovery = PackageDiscovery()
        
        let packageManager = try packageDiscovery.packageManager()
        
        for target in packageManager.targets {
            print(packageManager.sourcePath(for: target)!.path)
        }
    }
}
