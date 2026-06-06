import Foundation

final class HistoryStore {
    static let schemaVersion = 1

    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL = HistoryStore.defaultFileURL(), fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() throws -> [HistoryEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let document = try decoder.decode(HistoryDocument.self, from: data)
        guard document.schemaVersion == Self.schemaVersion else {
            return []
        }

        return document.records
    }

    func save(_ records: [HistoryEntry]) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let document = HistoryDocument(schemaVersion: Self.schemaVersion, records: records)
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: [.atomic])
    }

    func clear() throws {
        try save([])
    }

    static func defaultFileURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseURL
            .appendingPathComponent("FinderHistory", isDirectory: true)
            .appendingPathComponent("history.json")
    }
}
