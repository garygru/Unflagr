import Foundation
import Darwin

enum XattrError: LocalizedError {
    case listFailed(Int32)
    case readFailed(String, Int32)
    case removeFailed(String, Int32)

    var errorDescription: String? {
        switch self {
        case .listFailed(let err):
            return "Failed to list xattrs: \(String(cString: strerror(err)))"
        case .readFailed(let name, let err):
            return "Failed to read '\(name)': \(String(cString: strerror(err)))"
        case .removeFailed(let name, let err):
            return "Failed to remove '\(name)': \(String(cString: strerror(err)))"
        }
    }
}

enum XattrService {
    static func listXattrs(at path: String) throws -> [String] {
        let size = listxattr(path, nil, 0, XATTR_NOFOLLOW)
        guard size >= 0 else { throw XattrError.listFailed(errno) }
        guard size > 0 else { return [] }

        var buffer = [CChar](repeating: 0, count: size)
        let result = listxattr(path, &buffer, size, XATTR_NOFOLLOW)
        guard result >= 0 else { throw XattrError.listFailed(errno) }

        var names: [String] = []
        var current = ""
        for byte in buffer[0..<result] {
            if byte == 0 {
                if !current.isEmpty { names.append(current) }
                current = ""
            } else {
                current.append(Character(UnicodeScalar(UInt8(bitPattern: byte))))
            }
        }
        return names
    }

    static func getXattr(named name: String, at path: String) throws -> Data {
        let size = getxattr(path, name, nil, 0, 0, XATTR_NOFOLLOW)
        guard size >= 0 else { throw XattrError.readFailed(name, errno) }
        guard size > 0 else { return Data() }

        var buffer = [UInt8](repeating: 0, count: size)
        let result = getxattr(path, name, &buffer, size, 0, XATTR_NOFOLLOW)
        guard result >= 0 else { throw XattrError.readFailed(name, errno) }

        return Data(buffer[0..<result])
    }

    static func removeXattr(named name: String, at path: String, recursive: Bool) throws {
        if recursive {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            process.arguments = ["-dr", name, path]
            let pipe = Pipe()
            process.standardError = pipe
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                let errData = pipe.fileHandleForReading.readDataToEndOfFile()
                let errStr = String(data: errData, encoding: .utf8) ?? "Unknown error"
                throw XattrError.removeFailed(name, process.terminationStatus)
            }
        } else {
            let result = removexattr(path, name, XATTR_NOFOLLOW)
            guard result == 0 else { throw XattrError.removeFailed(name, errno) }
        }
    }
}
