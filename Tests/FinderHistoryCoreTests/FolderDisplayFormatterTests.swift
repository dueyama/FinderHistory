import Foundation
@testable import FinderHistoryCore
import XCTest

final class FolderDisplayFormatterTests: XCTestCase {
    func testDisplayNameUsesFolderName() {
        let url = URL(fileURLWithPath: "/Users/test/Documents", isDirectory: true)

        XCTAssertEqual(FolderDisplayFormatter.displayName(for: url), "Documents")
    }

    func testParentPathUsesContainingFolder() {
        let url = URL(fileURLWithPath: "/Users/test/Documents", isDirectory: true)

        XCTAssertEqual(FolderDisplayFormatter.parentPath(for: url), "/Users/test")
    }

    func testRootFolderDisplayIsStable() {
        let url = URL(fileURLWithPath: "/", isDirectory: true)

        XCTAssertEqual(FolderDisplayFormatter.displayName(for: url), "/")
        XCTAssertEqual(FolderDisplayFormatter.parentPath(for: url), "")
    }
}
