import SwiftUI

struct HistoryRowView: View {
    let entry: HistoryEntry
    let isAvailable: Bool
    let open: () -> Void
    @State private var isHovering = false

    var body: some View {
        Group {
            if isAvailable {
                Button(action: open) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .contentShape(Rectangle())
        .background(isHovering && isAvailable ? Color.accentColor.opacity(0.08) : Color.clear)
        .onHover { isHovering = $0 }
        .help(entry.url.path)
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            Image(systemName: isAvailable ? "folder" : "exclamationmark.triangle")
                .foregroundStyle(isAvailable ? Color.accentColor : Color.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.body)
                    .lineLimit(1)

                Text(entry.parentPath.isEmpty ? entry.url.path : entry.parentPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isAvailable {
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.string("history.missing"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
