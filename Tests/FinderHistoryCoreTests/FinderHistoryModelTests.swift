import Foundation
@testable import FinderHistoryCore
import XCTest

@MainActor
final class FinderHistoryModelTests: XCTestCase {
    func testModelRecordsClosedWindowAfterInitialSnapshot() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let client = MockFinderClient(snapshots: [
            [FinderWindowSnapshot(id: 1, url: tempDirectory)],
            []
        ])
        let store = HistoryStore(fileURL: tempDirectory.appendingPathComponent("history.json"))
        let defaults = UserDefaults(suiteName: "FinderHistoryModelTests-\(UUID().uuidString)")!
        defaults.set(5, forKey: AppPreferences.Key.historyLimit)
        let model = FinderHistoryModel(finderClient: client, historyStore: store, defaults: defaults)

        model.refresh()
        try await waitUntil {
            model.finderStatus == .available
        }
        XCTAssertTrue(model.history.isEmpty)

        model.refresh()
        try await waitUntil {
            model.history.count == 1
        }
        XCTAssertEqual(model.history.count, 1)
        XCTAssertEqual(model.history[0].url, tempDirectory.standardizedFileURL)
    }

    func testModelKeepsPollingAfterAccessibilityPermissionIsGranted() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let client = MockFinderClient(
            snapshots: [[FinderWindowSnapshot(id: 1, url: tempDirectory)]],
            permissionResults: [
                .failure(FinderClientError.accessibilityPermissionRequired),
                .success(())
            ]
        )
        let store = HistoryStore(fileURL: tempDirectory.appendingPathComponent("history.json"))
        let defaults = UserDefaults(suiteName: "FinderHistoryModelTests-\(UUID().uuidString)")!
        defaults.set(5, forKey: AppPreferences.Key.historyLimit)
        let model = FinderHistoryModel(
            finderClient: client,
            historyStore: store,
            defaults: defaults,
            pollInterval: 0.05
        )

        model.start()
        defer {
            model.stop()
        }

        try await waitUntil {
            model.finderStatus == .available
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 2,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("Timed out waiting for condition")
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}

private final class MockFinderClient: FinderClient {
    private var snapshots: [[FinderWindowSnapshot]]
    private var permissionResults: [Result<Void, Error>]

    init(
        snapshots: [[FinderWindowSnapshot]],
        permissionResults: [Result<Void, Error>] = []
    ) {
        self.snapshots = snapshots
        self.permissionResults = permissionResults
    }

    func currentWindows() throws -> [FinderWindowSnapshot] {
        guard !snapshots.isEmpty else {
            return []
        }

        return snapshots.removeFirst()
    }

    func ensureAccessPermission(askUserIfNeeded: Bool) throws {
        guard !permissionResults.isEmpty else {
            return
        }

        switch permissionResults.removeFirst() {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }

    func openFolder(at url: URL, restoring state: FinderWindowState?) throws {}
}
