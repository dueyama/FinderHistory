import Foundation

protocol HistoryAvailabilityResolving: Sendable {
    func folderExists(at url: URL) -> Bool
}

struct FileManagerHistoryAvailabilityResolver: HistoryAvailabilityResolving {
    func folderExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
