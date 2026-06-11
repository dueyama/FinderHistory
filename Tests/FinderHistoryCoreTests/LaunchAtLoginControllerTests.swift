import Foundation
@testable import FinderHistoryCore
import XCTest

final class LaunchAtLoginControllerTests: XCTestCase {
    func testMigratesLegacyLaunchAtLoginPreferenceAndRegistersNewLoginItem() throws {
        let defaults = UserDefaults.standard
        let currentBundleIdentifier = "io.github.dueyama.FinderHistory.tests.\(UUID().uuidString)"
        let legacyBundleIdentifier = "com.daishin.FinderHistory.tests.\(UUID().uuidString)"
        defaults.removeObject(forKey: AppPreferences.Key.launchAtLogin)
        defer {
            defaults.removeObject(forKey: AppPreferences.Key.launchAtLogin)
            defaults.removePersistentDomain(forName: currentBundleIdentifier)
            defaults.removePersistentDomain(forName: legacyBundleIdentifier)
        }
        defaults.setPersistentDomain(
            [AppPreferences.Key.launchAtLogin: true],
            forName: legacyBundleIdentifier
        )

        var registeredValue: Bool?
        try LaunchAtLoginController.migrateLegacyPreferenceIfNeeded(
            defaults: defaults,
            currentBundleIdentifier: currentBundleIdentifier,
            legacyBundleIdentifiers: [legacyBundleIdentifier]
        ) { enabled in
            registeredValue = enabled
        }

        let currentDomain = defaults.persistentDomain(forName: currentBundleIdentifier)
        XCTAssertEqual(currentDomain?[AppPreferences.Key.launchAtLogin] as? Bool, true)
        XCTAssertEqual(registeredValue, true)
    }

    func testDoesNotOverwriteCurrentLaunchAtLoginPreference() throws {
        let defaults = UserDefaults.standard
        let currentBundleIdentifier = "io.github.dueyama.FinderHistory.tests.\(UUID().uuidString)"
        let legacyBundleIdentifier = "com.daishin.FinderHistory.tests.\(UUID().uuidString)"
        defaults.removeObject(forKey: AppPreferences.Key.launchAtLogin)
        defer {
            defaults.removeObject(forKey: AppPreferences.Key.launchAtLogin)
            defaults.removePersistentDomain(forName: currentBundleIdentifier)
            defaults.removePersistentDomain(forName: legacyBundleIdentifier)
        }
        defaults.setPersistentDomain(
            [AppPreferences.Key.launchAtLogin: false],
            forName: currentBundleIdentifier
        )
        defaults.setPersistentDomain(
            [AppPreferences.Key.launchAtLogin: true],
            forName: legacyBundleIdentifier
        )

        var registeredValue: Bool?
        try LaunchAtLoginController.migrateLegacyPreferenceIfNeeded(
            defaults: defaults,
            currentBundleIdentifier: currentBundleIdentifier,
            legacyBundleIdentifiers: [legacyBundleIdentifier]
        ) { enabled in
            registeredValue = enabled
        }

        let currentDomain = defaults.persistentDomain(forName: currentBundleIdentifier)
        XCTAssertEqual(currentDomain?[AppPreferences.Key.launchAtLogin] as? Bool, false)
        XCTAssertNil(registeredValue)
    }

    func testSynchronizesStoredLaunchAtLoginPreferenceWhenRegistrationIsMissing() throws {
        let defaults = UserDefaults(suiteName: "LaunchAtLoginControllerTests-\(UUID().uuidString)")!
        defaults.set(true, forKey: AppPreferences.Key.launchAtLogin)

        var registeredValue: Bool?
        try LaunchAtLoginController.synchronizeStoredPreference(defaults: defaults, isEnabled: { false }) { enabled in
            registeredValue = enabled
        }

        XCTAssertEqual(registeredValue, true)
    }

    func testSynchronizeDoesNothingWhenStoredLaunchAtLoginPreferenceIsOff() throws {
        let defaults = UserDefaults(suiteName: "LaunchAtLoginControllerTests-\(UUID().uuidString)")!
        defaults.set(false, forKey: AppPreferences.Key.launchAtLogin)

        var registeredValue: Bool?
        try LaunchAtLoginController.synchronizeStoredPreference(defaults: defaults, isEnabled: { false }) { enabled in
            registeredValue = enabled
        }

        XCTAssertNil(registeredValue)
    }
}
