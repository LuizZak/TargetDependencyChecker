import Foundation

protocol FileManagerDelegate {
    /// Returns a list of all files in `url` recursively.
    func allFilesInPath(_ url: URL) throws -> [URL]
    
    /// Reads the contents of a file at a given path as a string of given encoding.
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String
    
    /// Returns `true` if a given `URL` represents a directory in the file system.
    func isDirectory(_ url: URL) -> Bool
}
