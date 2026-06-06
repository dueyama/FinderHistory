import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var model: FinderHistoryModel
    @AppStorage(AppPreferences.Key.historyLimit) private var historyLimit = AppPreferences.defaultHistoryLimit
    @AppStorage(AppPreferences.Key.launchAtLogin) private var launchAtLoginEnabled = false
    @State private var launchAtLoginError: String?

    public init(model: FinderHistoryModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            Section(header: Text(L10n.string("settings.history.title"))) {
                Stepper(
                    value: historyLimitBinding,
                    in: AppPreferences.minHistoryLimit...AppPreferences.maxHistoryLimit
                ) {
                    Text(L10n.string("settings.history.limit", historyLimit))
                }

                Text(L10n.string("settings.history.description"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text(L10n.string("settings.launch.title"))) {
                Toggle(isOn: launchAtLoginBinding) {
                    Text(L10n.string("settings.launch.login"))
                }

                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(header: Text(L10n.string("settings.automation.title"))) {
                automationStatus

                Button(L10n.string("settings.automation.check")) {
                    model.requestFinderAccess()
                }

                Button(L10n.string("action.openAccessibilitySettings")) {
                    SystemSettingsOpener.openAccessibilityPrivacyPane()
                }
            }

            Section(header: Text(L10n.string("settings.privacy.title"))) {
                Text(L10n.string("settings.privacy.localOnly"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(L10n.string("action.clearHistory")) {
                    model.clearHistory()
                }
                .disabled(model.history.isEmpty)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 480, height: 420)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        }
    }

    private var historyLimitBinding: Binding<Int> {
        Binding {
            historyLimit
        } set: { newValue in
            historyLimit = min(max(newValue, AppPreferences.minHistoryLimit), AppPreferences.maxHistoryLimit)
            model.trimToCurrentLimit()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding {
            launchAtLoginEnabled
        } set: { newValue in
            do {
                try LaunchAtLoginController.setEnabled(newValue)
                launchAtLoginEnabled = newValue
                launchAtLoginError = nil
            } catch {
                launchAtLoginEnabled = LaunchAtLoginController.isEnabled
                launchAtLoginError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private var automationStatus: some View {
        switch model.finderStatus {
        case .unknown:
            Text(L10n.string("settings.automation.unknown"))
                .font(.caption)
                .foregroundStyle(.secondary)
        case .available:
            Text(L10n.string("settings.automation.available"))
                .font(.caption)
                .foregroundStyle(.secondary)
        case let .unavailable(message):
            Text(L10n.string("settings.automation.unavailable", message))
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}
