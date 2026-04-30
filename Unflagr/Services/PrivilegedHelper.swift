import Foundation

enum PrivilegedHelper {
    @MainActor
    static func removeXattrPrivileged(named name: String, at path: String, recursive: Bool) async throws {
        let flag = recursive ? "-dr" : "-d"
        let escapedPath = path.replacingOccurrences(of: "'", with: "'\\''")
        let escapedName = name.replacingOccurrences(of: "'", with: "'\\''")
        let source = """
        do shell script "/usr/bin/xattr \(flag) '\(escapedName)' '\(escapedPath)'" with administrator privileges
        """

        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw PrivilegedError.scriptCreationFailed
        }
        script.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
            throw PrivilegedError.executionFailed(message)
        }
    }
}

enum PrivilegedError: LocalizedError {
    case scriptCreationFailed
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptCreationFailed:
            return "Failed to create authorization script"
        case .executionFailed(let message):
            return message
        }
    }
}
