import AppKit
import ApplicationServices
import Foundation
import OSLog

final class AccessibilityFinderClient: FinderClient {
    private let finderBundleID = "com.apple.finder"
    private let messagingTimeout: Float = 1.0
    private let logger = Logger(subsystem: "io.github.dueyama.FinderHistory", category: "finder-client")
    private var lastLoggedWindowCounts: (raw: Int, tracked: Int)?
    private var lastLoggedFallbackCount: Int?

    func ensureAccessPermission(askUserIfNeeded: Bool) throws {
        let options: CFDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: askUserIfNeeded
        ] as CFDictionary

        guard AXIsProcessTrustedWithOptions(options) else {
            throw FinderClientError.accessibilityPermissionRequired
        }
    }

    func currentWindows() throws -> [FinderWindowSnapshot] {
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: finderBundleID).first else {
            throw FinderClientError.finderNotRunning
        }

        let finderElement = AXUIElementCreateApplication(finder.processIdentifier)
        AXUIElementSetMessagingTimeout(finderElement, messagingTimeout)
        let windows = try attribute(kAXWindowsAttribute as CFString, from: finderElement) as? [AXUIElement] ?? []

        let snapshots = windows.compactMap { window -> FinderWindowSnapshot? in
            AXUIElementSetMessagingTimeout(window, messagingTimeout)
            guard let url = documentURL(for: window) else {
                return nil
            }

            return FinderWindowSnapshot(
                id: stableWindowID(for: window, url: url),
                url: url,
                windowState: windowState(for: window)
            )
        }

        let counts = (raw: windows.count, tracked: snapshots.count)
        if lastLoggedWindowCounts?.raw != counts.raw || lastLoggedWindowCounts?.tracked != counts.tracked {
            logger.debug("Finder AX windows raw: \(counts.raw, privacy: .public), tracked: \(counts.tracked, privacy: .public)")
            lastLoggedWindowCounts = counts
        }

        if snapshots.isEmpty, !windows.isEmpty {
            let fallbackSnapshots = try currentWindowsFromFinderAppleScript()
            if lastLoggedFallbackCount != fallbackSnapshots.count {
                logger.debug("Finder AppleScript fallback windows: \(fallbackSnapshots.count, privacy: .public)")
                lastLoggedFallbackCount = fallbackSnapshots.count
            }
            return fallbackSnapshots
        }

        lastLoggedFallbackCount = nil
        return snapshots
    }

    func openFolder(at url: URL, restoring state: FinderWindowState?) throws {
        if let state, !state.isEmpty, openFolderWithFinderAppleScript(at: url, restoring: state) {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func documentURL(for window: AXUIElement) -> URL? {
        for attributeName in [kAXDocumentAttribute, kAXURLAttribute] {
            guard let value = try? attribute(attributeName as CFString, from: window),
                  let url = fileURL(from: value) else {
                continue
            }

            return url
        }

        return nil
    }

    private func fileURL(from value: Any) -> URL? {
        if let url = value as? URL, url.isFileURL {
            return url.standardizedFileURL
        }

        guard let rawValue = value as? String, !rawValue.isEmpty else {
            return nil
        }

        if let url = URL(string: rawValue), url.isFileURL {
            return url.standardizedFileURL
        }

        return URL(fileURLWithPath: rawValue, isDirectory: true).standardizedFileURL
    }

    private func currentWindowsFromFinderAppleScript() throws -> [FinderWindowSnapshot] {
        let source = """
        tell application "Finder"
            set output to ""
            repeat with i from 1 to count of Finder windows
                set finderWindow to Finder window i
                try
                    set windowBounds to bounds of finderWindow
                    set boundsText to ((item 1 of windowBounds) as text) & "," & ((item 2 of windowBounds) as text) & "," & ((item 3 of windowBounds) as text) & "," & ((item 4 of windowBounds) as text)
                    set viewText to ""
                    try
                        set viewText to (current view of finderWindow) as text
                    end try
                    set output to output & ((id of finderWindow) as text) & tab & (URL of (target of finderWindow)) & tab & boundsText & tab & viewText & linefeed
                on error errorMessage number errorNumber
                    set output to output & "ERROR" & tab & ((id of finderWindow) as text) & tab & (errorNumber as text) & tab & errorMessage & linefeed
                end try
            end repeat
            return output
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            throw FinderClientError.appleScriptFailed("Could not create Finder AppleScript.")
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "\(errorInfo)"
            throw FinderClientError.appleScriptFailed(message)
        }

        let output = result.stringValue ?? ""
        let snapshots = FinderWindowListParser.parseAppleScriptOutput(output)
        if snapshots.isEmpty, output.contains("ERROR") {
            logger.error("Finder AppleScript fallback output: \(output, privacy: .public)")
        }

        return snapshots
    }

    private func openFolderWithFinderAppleScript(at url: URL, restoring state: FinderWindowState) -> Bool {
        var commands = [
            "tell application \"Finder\"",
            "set targetFolder to POSIX file \(appleScriptStringLiteral(url.path)) as alias",
            "set finderWindow to make new Finder window to targetFolder"
        ]

        if let bounds = state.bounds {
            commands.append("set bounds of finderWindow to {\(bounds.left), \(bounds.top), \(bounds.right), \(bounds.bottom)}")
        }

        if let viewStyle = finderAppleScriptViewConstant(for: state.viewStyle) {
            commands.append("try")
            commands.append("set current view of finderWindow to \(viewStyle)")
            commands.append("end try")
        }

        commands.append("activate")
        commands.append("end tell")

        guard let script = NSAppleScript(source: commands.joined(separator: "\n")) else {
            return false
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            logger.error("Finder restore AppleScript failed: \(String(describing: errorInfo), privacy: .public)")
            return false
        }

        return true
    }

    private func appleScriptStringLiteral(_ rawValue: String) -> String {
        let escaped = rawValue
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func finderAppleScriptViewConstant(for viewStyle: String?) -> String? {
        guard let viewStyle = viewStyle?.lowercased() else {
            return nil
        }

        if viewStyle.contains("icon") {
            return "icon view"
        }

        if viewStyle.contains("list") {
            return "list view"
        }

        if viewStyle.contains("column") {
            return "column view"
        }

        if viewStyle.contains("flow") || viewStyle.contains("gallery") {
            return "flow view"
        }

        return nil
    }

    private func stableWindowID(for window: AXUIElement, url: URL) -> Int {
        if let windowNumber = try? attribute("AXWindowNumber" as CFString, from: window) as? NSNumber {
            return windowNumber.intValue
        }

        if let identifier = try? attribute(kAXIdentifierAttribute as CFString, from: window) as? String, !identifier.isEmpty {
            return identifier.hashValue
        }

        return Int(CFHash(window))
    }

    private func windowState(for window: AXUIElement) -> FinderWindowState? {
        guard let position = cgPointAttribute(kAXPositionAttribute as CFString, from: window),
              let size = cgSizeAttribute(kAXSizeAttribute as CFString, from: window) else {
            return nil
        }

        let bounds = FinderWindowBounds(
            left: Int(position.x.rounded()),
            top: Int(position.y.rounded()),
            right: Int((position.x + size.width).rounded()),
            bottom: Int((position.y + size.height).rounded())
        )
        return FinderWindowState(bounds: bounds)
    }

    private func cgPointAttribute(_ name: CFString, from element: AXUIElement) -> CGPoint? {
        guard let value = try? attribute(name, from: element),
              CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    private func cgSizeAttribute(_ name: CFString, from element: AXUIElement) -> CGSize? {
        guard let value = try? attribute(name, from: element),
              CFGetTypeID(value as CFTypeRef) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }

    private func attribute(_ name: CFString, from element: AXUIElement) throws -> Any? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, name, &value)
        guard error == .success else {
            throw FinderClientError.accessibilityAttributeFailed(attribute: name as String, status: error.rawValue)
        }

        return value
    }
}
