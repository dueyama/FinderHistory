import Foundation
@testable import FinderHistoryCore
import XCTest

final class HistoryReducerTests: XCTestCase {
    func testClosedWindowIsDetectedByMissingWindowID() {
        let documents = snapshot(id: 10, path: "/Users/test/Documents")
        let downloads = snapshot(id: 11, path: "/Users/test/Downloads")

        let closed = HistoryReducer.closedWindows(
            previous: [documents, downloads],
            current: [documents]
        )

        XCTAssertEqual(closed, [downloads])
    }

    func testNavigationInSameWindowDoesNotBecomeHistory() {
        let oldLocation = snapshot(id: 10, path: "/Users/test/Documents")
        let newLocation = snapshot(id: 10, path: "/Users/test/Desktop")

        let closed = HistoryReducer.closedWindows(
            previous: [oldLocation],
            current: [newLocation]
        )

        XCTAssertTrue(closed.isEmpty)
    }

    func testDeduplicationMovesFolderToFront() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let documents = snapshot(id: 10, path: "/Users/test/Documents")
        let downloads = snapshot(id: 11, path: "/Users/test/Downloads")
        let existing = HistoryReducer.insertingClosedWindows([documents, downloads], into: [], limit: 5, now: now)

        let updated = HistoryReducer.insertingClosedWindows([documents], into: existing, limit: 5, now: now.addingTimeInterval(10))

        XCTAssertEqual(updated.count, 2)
        XCTAssertEqual(updated[0].url.path, "/Users/test/Documents")
        XCTAssertEqual(updated[0].closedAt, now.addingTimeInterval(10))
        XCTAssertEqual(updated[1].url.path, "/Users/test/Downloads")
    }

    func testHistoryLimitTrimsNewestRecords() {
        let windows = (0..<5).map { index in
            snapshot(id: index, path: "/Users/test/Folder\(index)")
        }

        let records = HistoryReducer.insertingClosedWindows(windows, into: [], limit: 3, now: Date(timeIntervalSince1970: 1_800_000_000))

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(records.map(\.url.path), [
            "/Users/test/Folder0",
            "/Users/test/Folder1",
            "/Users/test/Folder2"
        ])
    }

    private func snapshot(id: Int, path: String) -> FinderWindowSnapshot {
        FinderWindowSnapshot(id: id, url: URL(fileURLWithPath: path, isDirectory: true))
    }
}
