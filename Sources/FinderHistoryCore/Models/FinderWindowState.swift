import Foundation

public struct FinderWindowState: Codable, Equatable {
    public let bounds: FinderWindowBounds?
    public let viewStyle: String?

    init(bounds: FinderWindowBounds? = nil, viewStyle: String? = nil) {
        self.bounds = bounds
        self.viewStyle = viewStyle
    }

    var isEmpty: Bool {
        bounds == nil && (viewStyle?.isEmpty ?? true)
    }
}

public struct FinderWindowBounds: Codable, Equatable {
    public let left: Int
    public let top: Int
    public let right: Int
    public let bottom: Int

    init(left: Int, top: Int, right: Int, bottom: Int) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}
