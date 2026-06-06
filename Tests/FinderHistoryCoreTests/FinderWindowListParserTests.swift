import Foundation
@testable import FinderHistoryCore
import XCTest

final class FinderWindowListParserTests: XCTestCase {
    func testParseAppleScriptOutputUsesFinderWindowIDAndFileURL() {
        let output = "11534\tfile:///Users/daishin/\t10,20,810,620\tlist view\n11520\tfile:///Users/daishin/Documents/Codex/FinderHistory/\t30,40,830,640\ticon view\n"

        let snapshots = FinderWindowListParser.parseAppleScriptOutput(output)

        XCTAssertEqual(snapshots.count, 2)
        XCTAssertEqual(snapshots[0].id, 11534)
        XCTAssertEqual(snapshots[0].url, URL(fileURLWithPath: "/Users/daishin/", isDirectory: true).standardizedFileURL)
        XCTAssertEqual(snapshots[0].windowState?.bounds, FinderWindowBounds(left: 10, top: 20, right: 810, bottom: 620))
        XCTAssertEqual(snapshots[0].windowState?.viewStyle, "list view")
        XCTAssertEqual(snapshots[1].id, 11520)
        XCTAssertEqual(snapshots[1].url, URL(fileURLWithPath: "/Users/daishin/Documents/Codex/FinderHistory/", isDirectory: true).standardizedFileURL)
        XCTAssertEqual(snapshots[1].windowState?.bounds, FinderWindowBounds(left: 30, top: 40, right: 830, bottom: 640))
        XCTAssertEqual(snapshots[1].windowState?.viewStyle, "icon view")
    }

    func testParseAppleScriptOutputSkipsMalformedRows() {
        let output = "bad\tfile:///Users/daishin/\n11520\tnot-a-file-url\n11534\t/Users/daishin/\n"

        let snapshots = FinderWindowListParser.parseAppleScriptOutput(output)

        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].id, 11534)
        XCTAssertEqual(snapshots[0].url, URL(fileURLWithPath: "/Users/daishin/", isDirectory: true).standardizedFileURL)
    }
}
