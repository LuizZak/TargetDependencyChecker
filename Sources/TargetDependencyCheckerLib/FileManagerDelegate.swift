import Foundation

protocol FileManagerDelegate {
    /// Returns all files in a given directory recursively, optionaly specifying
    /// include and exclude patterns to fine-grain the results.
    ///
    /// - Parameters:
    ///   - url: Base directory to search files in.
    ///   - includePattern: An optional pattern that when specified only includes
    /// (full) file patterns that match a specified pattern.
    ///   - excludePattern: An optional pattern that when specified omits files
    /// matching the pattern. Takes priority over `includePattern`.
    /// - Returns: The full file URL for each file found satisfying the patterns
    /// specified.
    func allFilesInUrl(_ url: URL, includePattern: String?, excludePattern: String?) throws -> [URL]
    
    /// Reads the contents of a file at a given path as a string of given encoding.
    func contentsOfFile(at url: URL, encoding: String.Encoding) throws -> String
    
    /// Returns `true` if a given `URL` represents a directory in the file system.
    func isDirectory(_ url: URL) -> Bool
}
