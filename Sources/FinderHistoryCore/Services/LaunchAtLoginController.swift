import Foundation
import ServiceManagement

public enum LaunchAtLoginController {
    private static let legacyBundleIdentifiers = [
        "com.daishin.FinderHistory"
    ]

    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }

    public static func migrateLegacyPreferenceIfNeeded(
        defaults: UserDefaults = .standard,
        currentBundleIdentifier: String? = Bundle.main.bundleIdentifier,
        legacyBundleIdentifiers: [String]? = nil,
        setLaunchAtLogin: (Bool) throws -> Void = LaunchAtLoginController.setEnabled(_:)
    ) throws {
        guard let currentBundleIdentifier else {
            return
        }

        let currentDomain = defaults.persistentDomain(forName: currentBundleIdentifier)
        guard currentDomain?[AppPreferences.Key.launchAtLogin] == nil else {
            return
        }

        let legacyBundleIdentifiers = legacyBundleIdentifiers ?? LaunchAtLoginController.legacyBundleIdentifiers
        for legacyBundleIdentifier in legacyBundleIdentifiers {
            let legacyDomain = defaults.persistentDomain(forName: legacyBundleIdentifier)
            guard let legacyValue = legacyDomain?[AppPreferences.Key.launchAtLogin] as? Bool else {
                continue
            }

            defaults.set(legacyValue, forKey: AppPreferences.Key.launchAtLogin)
            var currentDomain = defaults.persistentDomain(forName: currentBundleIdentifier) ?? [:]
            currentDomain[AppPreferences.Key.launchAtLogin] = legacyValue
            defaults.setPersistentDomain(currentDomain, forName: currentBundleIdentifier)
            if legacyValue {
                try setLaunchAtLogin(true)
            }
            return
        }
    }

    public static func synchronizeStoredPreference(
        defaults: UserDefaults = .standard,
        isEnabled: () -> Bool = { LaunchAtLoginController.isEnabled },
        setLaunchAtLogin: (Bool) throws -> Void = LaunchAtLoginController.setEnabled(_:)
    ) throws {
        guard defaults.bool(forKey: AppPreferences.Key.launchAtLogin), !isEnabled() else {
            return
        }

        try setLaunchAtLogin(true)
    }
}
