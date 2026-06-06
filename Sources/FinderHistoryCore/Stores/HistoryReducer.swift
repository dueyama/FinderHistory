import Foundation

enum HistoryReducer {
    static func closedWindows(
        previous: [FinderWindowSnapshot],
        current: [FinderWindowSnapshot]
    ) -> [FinderWindowSnapshot] {
        let currentIDs = Set(current.map(\.id))
        return previous.filter { !currentIDs.contains($0.id) }
    }

    static func insertingClosedWindows(
        _ closedWindows: [FinderWindowSnapshot],
        into records: [HistoryEntry],
        limit: Int,
        now: Date = Date()
    ) -> [HistoryEntry] {
        let clampedLimit = min(max(limit, AppPreferences.minHistoryLimit), AppPreferences.maxHistoryLimit)
        guard clampedLimit > 0 else {
            return []
        }

        var updatedRecords = records
        for snapshot in closedWindows.reversed() {
            let entry = HistoryEntry(snapshot: snapshot, closedAt: now)
            updatedRecords.removeAll { normalizedPath($0.url) == normalizedPath(entry.url) }
            updatedRecords.insert(entry, at: 0)
        }

        return Array(updatedRecords.prefix(clampedLimit))
    }

    static func trimmed(_ records: [HistoryEntry], limit: Int) -> [HistoryEntry] {
        let clampedLimit = min(max(limit, AppPreferences.minHistoryLimit), AppPreferences.maxHistoryLimit)
        return Array(records.prefix(clampedLimit))
    }

    private static func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.path
    }
}
