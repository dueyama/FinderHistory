import Foundation
import ApplicationServices

protocol FinderClient: Sendable {
    func ensureAccessPermission(askUserIfNeeded: Bool) throws
    func currentWindows() throws -> [FinderWindowSnapshot]
    func openFolder(at url: URL, restoring state: FinderWindowState?) throws
}

extension FinderClient {
    func ensureAccessPermission(askUserIfNeeded: Bool) throws {}

    func openFolder(at url: URL) throws {
        try openFolder(at: url, restoring: nil)
    }
}

enum FinderClientError: LocalizedError, Equatable {
    case accessibilityPermissionRequired
    case accessibilityAttributeFailed(attribute: String, status: Int32)
    case appleScriptFailed(String)
    case finderNotRunning

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return L10n.string("error.accessibilityPermissionRequired")
        case let .accessibilityAttributeFailed(attribute, status):
            return L10n.string("error.accessibilityAttributeFailed", attribute, status)
        case let .appleScriptFailed(message):
            return L10n.string("error.appleScriptFailed", message)
        case .finderNotRunning:
            return L10n.string("error.finderNotRunning")
        }
    }
}
