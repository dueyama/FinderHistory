import Foundation

enum FinderWindowListParser {
    static func parseAppleScriptOutput(_ output: String) -> [FinderWindowSnapshot] {
        output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> FinderWindowSnapshot? in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard parts.count >= 2,
                      let id = Int(parts[0]),
                      let url = fileURL(from: String(parts[1])) else {
                    return nil
                }

                return FinderWindowSnapshot(
                    id: id,
                    url: url,
                    windowState: windowState(from: parts)
                )
            }
    }

    private static func fileURL(from rawValue: String) -> URL? {
        if let url = URL(string: rawValue), url.isFileURL {
            return url.standardizedFileURL
        }

        guard rawValue.hasPrefix("/") else {
            return nil
        }

        return URL(fileURLWithPath: rawValue, isDirectory: true).standardizedFileURL
    }

    private static func windowState(from parts: [Substring]) -> FinderWindowState? {
        let bounds = parts.indices.contains(2) ? bounds(from: String(parts[2])) : nil
        let viewStyle = parts.indices.contains(3) && !parts[3].isEmpty ? String(parts[3]) : nil
        let state = FinderWindowState(bounds: bounds, viewStyle: viewStyle)
        return state.isEmpty ? nil : state
    }

    private static func bounds(from rawValue: String) -> FinderWindowBounds? {
        let values = rawValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(Int.init)

        guard values.count == 4 else {
            return nil
        }

        return FinderWindowBounds(left: values[0], top: values[1], right: values[2], bottom: values[3])
    }
}
