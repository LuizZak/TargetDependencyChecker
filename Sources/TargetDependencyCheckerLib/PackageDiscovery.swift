import Foundation

class PackageDiscovery {
    let packageUrl: URL
    
    init(packageUrl: URL = PackageDiscovery.workDirectory) {
        
        self.packageUrl = packageUrl
    }
    
    func package() throws -> Package {
        let process = makeSwiftProcess()
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
        let process = makeSwiftProcess()
        process.arguments = ["package", "dump-package"]
        
        let result = try process.readStandardOutput()
        
        let json = try JSON.fromString(result)
        
        return json
    }
    
    private func makeSwiftProcess() -> Process {
        let process = Process()
        process.launchPath = PackageDiscovery.swiftCompilerPath
        
        return process
    }
}

extension PackageDiscovery {
    /// Path to the Swift compiler.
    private static let swiftCompilerPath: String = {
        let process = Process()
        
        #if os(macOS)
        process.launchPath = "/usr/bin/xcrun"
        process.arguments = ["--sdk", "macosx", "-f", "swift"]
        #else
        process.launchPath = "/usr/bin/which"
        process.arguments = ["swift"]
        #endif
        
        return try! process.readStandardOutput().spm_chomp()
    }()
    
    static var workDirectory: URL {
        var buffer: [Int8] = Array(repeating: 0, count: 1024)
        guard getcwd(&buffer, buffer.count) != nil else {
            fatalError("Error fetching work directory")
        }
        
        return URL(fileURLWithPath: String(cString: buffer))
    }
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
