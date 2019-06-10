import Foundation

public enum Checker {
    public static func main() throws {
        let package = PackageDiscovery()
        
        let json = try package.dumpPackage()
        
        let targets = try json[key: "targets"]!.decode([Target].self, decoder: JSONDecoder())
        
        print(targets)
    }
}
