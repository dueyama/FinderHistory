import Foundation
import ServiceManagement

public enum LaunchAtLoginController {
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
