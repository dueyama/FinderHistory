import Foundation

public struct HistoryEntry: Codable, Equatable, Identifiable {
    public let id: UUID
    public let url: URL
    public let displayName: String
    public let parentPath: String
    public let closedAt: Date
    public let windowState: FinderWindowState?

    init(
        id: UUID = UUID(),
        url: URL,
        displayName: String,
        parentPath: String,
        closedAt: Date,
        windowState: FinderWindowState? = nil
    ) {
        self.id = id
        self.url = url.standardizedFileURL
        self.displayName = displayName
        self.parentPath = parentPath
        self.closedAt = closedAt
        self.windowState = windowState
    }

    init(snapshot: FinderWindowSnapshot, closedAt: Date) {
        self.init(
            url: snapshot.url,
            displayName: FolderDisplayFormatter.displayName(for: snapshot.url),
            parentPath: FolderDisplayFormatter.parentPath(for: snapshot.url),
            closedAt: closedAt,
            windowState: snapshot.windowState?.isEmpty == true ? nil : snapshot.windowState
        )
    }

    public var isAvailable: Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

struct HistoryDocument: Codable, Equatable {
    let schemaVersion: Int
    var records: [HistoryEntry]
}
