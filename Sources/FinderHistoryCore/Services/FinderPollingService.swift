import Foundation

final class FinderPollingService {
    private let finderClient: FinderClient
    private let queue = DispatchQueue(label: "io.github.dueyama.FinderHistory.finder-polling", qos: .utility)
    private var isPolling = false

    init(finderClient: FinderClient) {
        self.finderClient = finderClient
    }

    func poll(
        askUserIfNeeded: Bool,
        completion: @escaping (Result<[FinderWindowSnapshot], Error>) -> Void
    ) {
        queue.async { [weak self] in
            guard let self, !self.isPolling else {
                return
            }

            self.isPolling = true
            let result: Result<[FinderWindowSnapshot], Error> = Result {
                try self.finderClient.ensureAccessPermission(askUserIfNeeded: askUserIfNeeded)
                return try self.finderClient.currentWindows()
            }
            self.isPolling = false

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
