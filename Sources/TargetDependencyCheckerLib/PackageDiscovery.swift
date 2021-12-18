import Foundation

class PackageDiscovery {
    let packageUrl: URL
    
    init(packageUrl: URL) {
        self.packageUrl = packageUrl
    }
    
    func package() throws -> Package {
        let process = makeSwiftProcessAtPackagePath()
        process.arguments = ["package", "dump-package"]
        
        let result = try process.readStandardOutput()
        
        guard let data = result.data(using: .utf8) else {
            throw JSON.Error.invalidJsonString
        }
        
        return try JSONDecoder().decode(Package.self, from: data)
    }
    
    func packageManager() throws -> PackageManager {
        try PackageManager(package: package(),
                           packageRootUrl: packageUrl,
                           fileManagerDelegate: DiskFileManagerDelegate())
    }
    
    func dumpPackageJSON() throws -> JSON {
        let process = makeSwiftProcessAtPackagePath()
        process.arguments = ["package", "dump-package"]
        
        let result = try process.readStandardOutput()
        
        let json = try JSON.fromString(result)
        
        return json
    }
    
    private func makeSwiftProcessAtPackagePath() -> Process {
        let process = Process()
        process.executableURL = PackageDiscovery.swiftCompilerPath
        
        if #available(OSX 10.13, *) {
            process.currentDirectoryURL = packageUrl
        } else {
            process.currentDirectoryPath = packageUrl.path
        }
        
        return process
    }
}

extension PackageDiscovery {
    /// Path to the Swift compiler.
    private static let swiftCompilerPath: URL = {
        let process = Process()
        
        #if os(macOS)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", "macosx", "-f", "swift"]
        #else
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["swift"]
        #endif
        
        return URL(fileURLWithPath: try! process.readStandardOutput().spm_chomp())
    }()
}

extension String {
    // Based off of SwiftPM's own String.spm_chomp method
    func spm_chomp(separator: String? = nil) -> String {
        func scrub(_ separator: String) -> String {
            var E = endIndex
            while String(self[startIndex..<E]).hasSuffix(separator) && E > startIndex {
                E = index(before: E)
            }
            return String(self[startIndex..<E])
        }
        
        if let separator = separator {
            return scrub(separator)
        } else if hasSuffix("\r\n") {
            return scrub("\r\n")
        } else if hasSuffix("\n") {
            return scrub("\n")
        } else {
            return self
        }
    }
}

extension Process {
    @discardableResult
    public func readStandardOutput() throws -> String {
        let outputPipe = Pipe()
        
        standardOutput = outputPipe
        
        if #available(OSX 10.13, *) {
            try run()
        } else {
            launch()
        }
        
        waitUntilExit()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
        // Throw if there was a non zero termination.
        guard terminationStatus == 0 else {
            throw ProcessError.fatalError
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw ProcessError.nonUtf8Result
        }
        
        return string
    }
    
    enum ProcessError: Error {
        case fatalError
        case nonUtf8Result
    }
}
