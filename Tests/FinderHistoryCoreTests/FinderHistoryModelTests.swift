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

    func testOpenDoesNotBlockMainActorWhenFinderOpenIsSlow() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let client = MockFinderClient(snapshots: [], openDelay: 0.35)
        let resolver = MockHistoryAvailabilityResolver(isAvailable: true, delay: 0.35)
        let store = HistoryStore(fileURL: tempDirectory.appendingPathComponent("history.json"))
        let defaults = UserDefaults(suiteName: "FinderHistoryModelTests-\(UUID().uuidString)")!
        let model = FinderHistoryModel(
            finderClient: client,
            historyStore: store,
            defaults: defaults,
            availabilityResolver: resolver
        )
        let entry = HistoryEntry(
            url: tempDirectory,
            displayName: "Folder",
            parentPath: tempDirectory.deletingLastPathComponent().path,
            closedAt: Date()
        )

        let start = Date()
        model.open(entry)
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.1)

        try await waitUntil {
            client.openCallCount == 1
        }
    }

    func testRefreshHistoryAvailabilityDoesNotBlockMainActorWhenFileCheckIsSlow() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        let entry = HistoryEntry(
            url: tempDirectory,
            displayName: "Folder",
            parentPath: tempDirectory.deletingLastPathComponent().path,
            closedAt: Date()
        )
        let client = MockFinderClient(snapshots: [])
        let resolver = MockHistoryAvailabilityResolver(isAvailable: false, delay: 0.35)
        let store = HistoryStore(fileURL: tempDirectory.appendingPathComponent("history.json"))
        try store.save([entry])
        let defaults = UserDefaults(suiteName: "FinderHistoryModelTests-\(UUID().uuidString)")!
        let model = FinderHistoryModel(
            finderClient: client,
            historyStore: store,
            defaults: defaults,
            availabilityResolver: resolver
        )

        let start = Date()
        model.refreshHistoryFromDisk()
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.1)

        try await waitUntil {
            model.isHistoryEntryAvailable(entry) == false
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

private final class MockFinderClient: FinderClient, @unchecked Sendable {
    private let lock = NSLock()
    private var snapshots: [[FinderWindowSnapshot]]
    private var permissionResults: [Result<Void, Error>]
    private let openDelay: TimeInterval
    private var _openCallCount = 0

    var openCallCount: Int {
        lock.withLock {
            _openCallCount
        }
    }

    init(
        snapshots: [[FinderWindowSnapshot]],
        permissionResults: [Result<Void, Error>] = [],
        openDelay: TimeInterval = 0
    ) {
        self.snapshots = snapshots
        self.permissionResults = permissionResults
        self.openDelay = openDelay
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

    func openFolder(at url: URL, restoring state: FinderWindowState?) throws {
        lock.withLock {
            _openCallCount += 1
        }

        if openDelay > 0 {
            Thread.sleep(forTimeInterval: openDelay)
        }
    }
}

private final class MockHistoryAvailabilityResolver: HistoryAvailabilityResolving, @unchecked Sendable {
    private let isAvailable: Bool
    private let delay: TimeInterval

    init(isAvailable: Bool, delay: TimeInterval = 0) {
        self.isAvailable = isAvailable
        self.delay = delay
    }

    func folderExists(at url: URL) -> Bool {
        if delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }
        return isAvailable
    }
}
