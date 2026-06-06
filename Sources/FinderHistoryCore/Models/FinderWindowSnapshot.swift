import Foundation

struct FinderWindowSnapshot: Equatable, Identifiable {
    let id: Int
    let url: URL
    let windowState: FinderWindowState?

    init(id: Int, url: URL, windowState: FinderWindowState? = nil) {
        self.id = id
        self.url = url.standardizedFileURL
        self.windowState = windowState
    }
}
