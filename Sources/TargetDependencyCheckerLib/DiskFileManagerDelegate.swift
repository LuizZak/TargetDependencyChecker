import Foundation

class DiskFileManagerDelegate: FileManagerDelegate {
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String {
        let data = try Data(contentsOf: url)
        
        guard let string = String(data: data, encoding: encoding) else {
            throw Error.invalidStringData
        }
        
        return string
    }
    
    func allFilesInPath(_ url: URL) throws -> [URL] {
        try FileManager
            .default
            .contentsOfDirectory(at: url,
                                 includingPropertiesForKeys: nil,
                                 options: [.skipsHiddenFiles])
    }
    
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}

extension DiskFileManagerDelegate {
    enum Error: Swift.Error {
        case invalidStringData
    }
}
