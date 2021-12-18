import Foundation

public func workDirectory() -> URL {
    var buffer: [Int8] = Array(repeating: 0, count: 1024)
    guard getcwd(&buffer, buffer.count) != nil else {
        fatalError("Error fetching work directory")
    }
    
    return URL(fileURLWithPath: String(cString: buffer))
}
