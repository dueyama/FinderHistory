import Foundation
@testable import FinderHistoryCore
import XCTest

final class LaunchAtLoginControllerTests: XCTestCase {
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
