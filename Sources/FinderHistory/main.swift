import AppKit
import FinderHistoryCore
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct FinderHistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model: FinderHistoryModel

    init() {
        AppPreferences.registerDefaults()
        try? LaunchAtLoginController.migrateLegacyPreferenceIfNeeded()
        try? LaunchAtLoginController.synchronizeStoredPreference()
        let model = FinderHistoryModel.live()
        model.start()
        _model = StateObject(wrappedValue: model)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(nsImage: MenuBarIcon.image)
                .accessibilityLabel(L10n.string("app.name"))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
