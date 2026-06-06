import Foundation
@testable import FinderHistoryCore
import XCTest

final class HistoryStoreTests: XCTestCase {
    func testSaveAndLoadRoundTripUsesSchemaVersion() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let fileURL = tempDirectory.appendingPathComponent("history.json")
        let store = HistoryStore(fileURL: fileURL)
        let entry = HistoryEntry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            url: URL(fileURLWithPath: "/Users/test/Documents", isDirectory: true),
            displayName: "Documents",
            parentPath: "/Users/test",
            closedAt: Date(timeIntervalSince1970: 1_800_000_000),
            windowState: FinderWindowState(
                bounds: FinderWindowBounds(left: 10, top: 20, right: 810, bottom: 620),
                viewStyle: "list view"
            )
        )

        try store.save([entry])

        let loaded = try store.load()
        XCTAssertEqual(loaded, [entry])

        let data = try Data(contentsOf: fileURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, HistoryStore.schemaVersion)
        let records = try XCTUnwrap(json["records"] as? [[String: Any]])
        XCTAssertNotNil(records[0]["windowState"] as? [String: Any])
    }

    func testMissingHistoryFileLoadsEmptyHistory() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let store = HistoryStore(fileURL: tempDirectory.appendingPathComponent("missing.json"))

        XCTAssertEqual(try store.load(), [])
    }
}
