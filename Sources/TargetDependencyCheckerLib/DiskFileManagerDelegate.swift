import Foundation

#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

class DiskFileManagerDelegate: FileManagerDelegate {
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String {
        let data = try Data(contentsOf: url)
        
        guard let string = String(data: data, encoding: encoding) else {
            throw Error.invalidStringData
        }
        
        return string
    }
    
    func allFilesInUrl(_ url: URL, includePattern: String?, excludePattern: String?) throws -> [URL] {
#if os(macOS)
        let fnflags: Int32 = FNM_CASEFOLD
#else
        let fnflags: Int32 = 0
#endif
        
        let fileManager = FileManager.default
        guard var objcFiles = fileManager.enumerator(atPath: url.path)?.compactMap({ $0 as? String }) else {
            throw Error.couldNotIterateDirectory
        }
        
        // Inclusions
        if let includePattern = includePattern {
            objcFiles = objcFiles.filter { path in
                fnmatch(includePattern, path, fnflags) == 0
            }
        }
        // Exclusions
        if let excludePattern = excludePattern {
            objcFiles = objcFiles.filter { path in
                fnmatch(excludePattern, path, fnflags) != 0
            }
        }
        
        return
            objcFiles
                // Map full path
                .map { (path: String) -> String in
                    return url.appendingPathComponent(path).path
                }
                // Convert to URLs
                .map { (path: String) -> URL in
                    return URL(fileURLWithPath: path)
                }
    }
    
    func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}

extension DiskFileManagerDelegate {
    enum Error: Swift.Error {
        case couldNotIterateDirectory
        case invalidStringData
    }
}
