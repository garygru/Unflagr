import Foundation
import AppKit

struct XattrEntry: Identifiable {
    let id = UUID()
    let name: String
    let value: Data

    var displayValue: String {
        if let str = String(data: value, encoding: .utf8),
           str.allSatisfy({ $0.isPrintable }) {
            return str
        }
        if value.count <= 32 {
            return value.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
        let prefix = value.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
        return "\(prefix)… (\(value.count) bytes)"
    }

    var isQuarantine: Bool {
        name == "com.apple.quarantine"
    }
}

private extension Character {
    var isPrintable: Bool {
        guard let ascii = asciiValue else { return !isNewline }
        return ascii >= 0x20 && ascii < 0x7F
    }
}

@Observable
class DroppedFile {
    let url: URL
    var xattrs: [XattrEntry] = []
    var errorMessage: String?
    var isLoading = false

    var displayName: String { url.lastPathComponent }
    var path: String { url.path }

    var isAppBundle: Bool {
        url.pathExtension.lowercased() == "app"
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    var hasQuarantine: Bool {
        xattrs.contains { $0.isQuarantine }
    }

    init(url: URL) {
        self.url = url
    }

    func loadXattrs() {
        isLoading = true
        errorMessage = nil
        do {
            let names = try XattrService.listXattrs(at: url.path)
            xattrs = try names.map { name in
                let data = try XattrService.getXattr(named: name, at: url.path)
                return XattrEntry(name: name, value: data)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func removeXattr(named name: String) async {
        let recursive = isAppBundle
        do {
            try XattrService.removeXattr(named: name, at: url.path, recursive: recursive)
        } catch {
            do {
                try await PrivilegedHelper.removeXattrPrivileged(named: name, at: url.path, recursive: recursive)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
        loadXattrs()
    }

    func removeQuarantine() async {
        await removeXattr(named: "com.apple.quarantine")
    }
}
