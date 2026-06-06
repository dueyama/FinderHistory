import Combine
import Foundation
import OSLog

public enum FinderAccessStatus: Equatable {
    case unknown
    case available
    case unavailable(String)
}

@MainActor
public final class FinderHistoryModel: ObservableObject {
    @Published public private(set) var history: [HistoryEntry] = []
    @Published public private(set) var finderStatus: FinderAccessStatus = .unknown
    @Published public private(set) var finderWindowCount: Int = 0
    @Published public private(set) var lastErrorMessage: String?
    @Published private var historyAvailability: [UUID: Bool] = [:]

    private let finderClient: FinderClient
    private let pollingService: FinderPollingService
    private let historyStore: HistoryStore
    private let defaults: UserDefaults
    private let pollInterval: TimeInterval
    private let openQueue: DispatchQueue
    private let availabilityQueue: DispatchQueue
    private let availabilityResolver: HistoryAvailabilityResolving
    private let logger = Logger(subsystem: "io.github.dueyama.FinderHistory", category: "history")
    private var previousWindows: [FinderWindowSnapshot]?
    private var timer: Timer?
    private var defaultsObserver: NSObjectProtocol?
    private var hasLoggedAccessibilityDenial = false

    init(
        finderClient: FinderClient,
        historyStore: HistoryStore,
        defaults: UserDefaults = .standard,
        pollInterval: TimeInterval = 2,
        openQueue: DispatchQueue = DispatchQueue(label: "io.github.dueyama.FinderHistory.open", qos: .userInitiated),
        availabilityQueue: DispatchQueue = DispatchQueue(label: "io.github.dueyama.FinderHistory.availability", qos: .utility),
        availabilityResolver: HistoryAvailabilityResolving = FileManagerHistoryAvailabilityResolver()
    ) {
        self.finderClient = finderClient
        self.pollingService = FinderPollingService(finderClient: finderClient)
        self.historyStore = historyStore
        self.defaults = defaults
        self.pollInterval = pollInterval
        self.openQueue = openQueue
        self.availabilityQueue = availabilityQueue
        self.availabilityResolver = availabilityResolver

        do {
            history = HistoryReducer.trimmed(try historyStore.load(), limit: AppPreferences.clampedHistoryLimit(from: defaults))
            logger.debug("Loaded Finder history count: \(self.history.count, privacy: .public)")
        } catch {
            history = []
            lastErrorMessage = error.localizedDescription
            logger.error("Loading Finder history failed: \(error.localizedDescription, privacy: .public)")
        }

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.trimToCurrentLimit()
            }
        }

        refreshAvailability(for: history)
    }

    deinit {
        timer?.invalidate()
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    public static func live() -> FinderHistoryModel {
        FinderHistoryModel(
            finderClient: AccessibilityFinderClient(),
            historyStore: HistoryStore()
        )
    }

    public func start() {
        guard timer == nil else {
            return
        }

        logger.debug("Starting Finder polling")
        scheduleTimer()
        pollFinder(askUserIfNeeded: true)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func refresh() {
        pollFinder(askUserIfNeeded: false)
    }

    public func refreshHistoryFromDisk() {
        do {
            let loadedHistory = HistoryReducer.trimmed(
                try historyStore.load(),
                limit: AppPreferences.clampedHistoryLimit(from: defaults)
            )
            if loadedHistory != history {
                history = loadedHistory
            }
            refreshAvailability(for: loadedHistory)
            logger.debug("Menu opened with Finder history count: \(loadedHistory.count, privacy: .public)")
            lastErrorMessage = nil
        } catch {
            logger.error("Loading Finder history failed: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = error.localizedDescription
        }
    }

    public func requestFinderAccess() {
        pollFinder(askUserIfNeeded: true)
    }

    func isHistoryEntryAvailable(_ entry: HistoryEntry) -> Bool {
        historyAvailability[entry.id] ?? true
    }

    private func pollFinder(askUserIfNeeded: Bool) {
        pollingService.poll(askUserIfNeeded: askUserIfNeeded) { [weak self] result in
            Task { @MainActor in
                self?.handleRefreshResult(result)
            }
        }
    }

    private func handleRefreshResult(_ result: Result<[FinderWindowSnapshot], Error>) {
        switch result {
        case let .success(currentWindows):
            hasLoggedAccessibilityDenial = false
            if timer == nil {
                logger.debug("Resuming Finder polling")
                scheduleTimer()
            }
            if finderWindowCount != currentWindows.count {
                logger.debug("Watching Finder window count: \(currentWindows.count, privacy: .public)")
            }
            finderWindowCount = currentWindows.count
            logger.debug("Finder snapshot count: \(currentWindows.count, privacy: .public)")
            if let previousWindows {
                let closedWindows = HistoryReducer.closedWindows(previous: previousWindows, current: currentWindows)
                logger.debug("Closed Finder window count: \(closedWindows.count, privacy: .public)")
                if !closedWindows.isEmpty {
                    let updatedHistory = HistoryReducer.insertingClosedWindows(
                        closedWindows,
                        into: history,
                        limit: AppPreferences.clampedHistoryLimit(from: defaults)
                    )
                    persist(updatedHistory)
                }
            }

            previousWindows = currentWindows
            finderStatus = .available
            lastErrorMessage = nil
        case let .failure(error):
            if case FinderClientError.accessibilityPermissionRequired = error {
                if !hasLoggedAccessibilityDenial {
                    logger.info("Finder polling is waiting for Accessibility permission")
                    hasLoggedAccessibilityDenial = true
                } else {
                    logger.debug("Finder polling still waiting for Accessibility permission")
                }
                previousWindows = nil
            } else {
                logger.error("Finder polling failed: \(error.localizedDescription, privacy: .public)")
                hasLoggedAccessibilityDenial = false
            }

            finderWindowCount = 0
            finderStatus = .unavailable(error.localizedDescription)
            lastErrorMessage = error.localizedDescription
        }
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    public func open(_ entry: HistoryEntry) {
        guard isHistoryEntryAvailable(entry) else {
            lastErrorMessage = L10n.string("error.folderMissing", entry.url.path)
            return
        }

        let entryID = entry.id
        let url = entry.url
        let windowState = entry.windowState
        let finderClient = finderClient
        let availabilityResolver = availabilityResolver

        logger.debug("Opening Finder history item: \(url.path, privacy: .public)")
        openQueue.async { [weak self] in
            guard availabilityResolver.folderExists(at: url) else {
                DispatchQueue.main.async { [weak self] in
                    self?.historyAvailability[entryID] = false
                    self?.lastErrorMessage = L10n.string("error.folderMissing", url.path)
                }
                return
            }

            do {
                try finderClient.openFolder(at: url, restoring: windowState)
                DispatchQueue.main.async { [weak self] in
                    self?.historyAvailability[entryID] = true
                    self?.lastErrorMessage = nil
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.logger.error("Opening Finder history item failed: \(error.localizedDescription, privacy: .public)")
                    self?.lastErrorMessage = error.localizedDescription
                }
            }
        }
    }

    public func clearHistory() {
        persist([])
    }

    public func trimToCurrentLimit() {
        let trimmedHistory = HistoryReducer.trimmed(history, limit: AppPreferences.clampedHistoryLimit(from: defaults))
        guard trimmedHistory != history else {
            return
        }

        persist(trimmedHistory)
    }

    private func persist(_ records: [HistoryEntry]) {
        history = records
        refreshAvailability(for: records)
        do {
            try historyStore.save(records)
            logger.debug("Saved Finder history count: \(records.count, privacy: .public)")
            lastErrorMessage = nil
        } catch {
            logger.error("Saving Finder history failed: \(error.localizedDescription, privacy: .public)")
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshAvailability(for records: [HistoryEntry]) {
        let entries = records.map { (id: $0.id, url: $0.url) }
        let availabilityResolver = availabilityResolver

        availabilityQueue.async { [weak self] in
            let checkedAvailability = Dictionary(
                uniqueKeysWithValues: entries.map { entry in
                    (entry.id, availabilityResolver.folderExists(at: entry.url))
                }
            )

            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                let currentHistoryIDs = Set(self.history.map(\.id))
                var nextAvailability = self.historyAvailability.filter { currentHistoryIDs.contains($0.key) }
                for (id, isAvailable) in checkedAvailability {
                    guard currentHistoryIDs.contains(id) else {
                        continue
                    }
                    nextAvailability[id] = isAvailable
                }
                self.historyAvailability = nextAvailability
            }
        }
    }
}
