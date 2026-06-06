import SwiftUI

public struct MenuBarView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var model: FinderHistoryModel

    public init(model: FinderHistoryModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if model.history.isEmpty {
                emptyState
            } else {
                historyList
            }

            Divider()
            footer
        }
        .frame(width: 380)
        .onAppear {
            model.refreshHistoryFromDisk()
            model.start()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(nsImage: MenuBarIcon.image)
                    .frame(width: 18, height: 18)
                Text(L10n.string("app.name"))
                    .font(.headline)

                Spacer()

                Button {
                    model.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(L10n.string("action.refresh"))
            }

            statusText
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if case .unavailable = model.finderStatus {
                HStack {
                    Button(L10n.string("action.enableFinderAccess")) {
                        model.requestFinderAccess()
                    }
                    .controlSize(.small)

                    Button(L10n.string("action.openAccessibilitySettings")) {
                        SystemSettingsOpener.openAccessibilityPrivacyPane()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var statusText: some View {
        switch model.finderStatus {
        case .unknown:
            Text(L10n.string("status.finder.unknown"))
        case .available:
            Text(L10n.string("status.finder.available", model.finderWindowCount))
        case let .unavailable(message):
            Text(L10n.string("status.finder.unavailable", message))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.string("history.empty.title"))
                .font(.headline)
            Text(L10n.string("history.empty.description"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var historyList: some View {
        let rowHeight: CGFloat = 58
        let visibleHeight = min(CGFloat(model.history.count) * rowHeight, 340)

        return ScrollView {
            VStack(spacing: 0) {
                ForEach(model.history) { entry in
                    HistoryRowView(entry: entry) {
                        model.open(entry)
                        dismiss()
                    }

                    if entry.id != model.history.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(height: max(visibleHeight, rowHeight))
    }

    private var footer: some View {
        HStack {
            Button(L10n.string("action.clearHistory")) {
                model.clearHistory()
            }
            .disabled(model.history.isEmpty)

            Spacer()

            Button(L10n.string("action.settings")) {
                SettingsOpener.open(model: model)
            }

            Button(L10n.string("action.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
    }
}
