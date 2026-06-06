import Foundation

public enum AppPreferences {
    public enum Key {
        public static let historyLimit = "historyLimit"
        public static let launchAtLogin = "launchAtLogin"
    }

    public static let defaultHistoryLimit = 5
    public static let minHistoryLimit = 1
    public static let maxHistoryLimit = 50

    public static func registerDefaults(_ defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            Key.historyLimit: defaultHistoryLimit,
            Key.launchAtLogin: false
        ])
    }

    public static func clampedHistoryLimit(from defaults: UserDefaults = .standard) -> Int {
        let rawValue = defaults.object(forKey: Key.historyLimit) as? Int ?? defaultHistoryLimit
        return min(max(rawValue, minHistoryLimit), maxHistoryLimit)
    }
}
