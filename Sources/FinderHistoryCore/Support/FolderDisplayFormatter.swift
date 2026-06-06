import Foundation

enum FolderDisplayFormatter {
    static func displayName(for url: URL) -> String {
        let standardizedURL = url.standardizedFileURL

        if standardizedURL.path == "/" {
            return "/"
        }

        let displayName = FileManager.default.displayName(atPath: standardizedURL.path)
        if !displayName.isEmpty {
            return displayName
        }

        let lastPathComponent = standardizedURL.lastPathComponent
        return lastPathComponent.isEmpty ? standardizedURL.path : lastPathComponent
    }

    static func parentPath(for url: URL) -> String {
        let standardizedURL = url.standardizedFileURL
        let parentURL = standardizedURL.deletingLastPathComponent()

        if parentURL.path == standardizedURL.path {
            return ""
        }

        return parentURL.path
    }
}
