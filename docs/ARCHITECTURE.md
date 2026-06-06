# Architecture

FinderHistory is a SwiftPM macOS menu-bar app with one executable target and one core target.

## Runtime Flow

1. `FinderHistoryApp` starts a menu-bar-only SwiftUI app.
2. `FinderHistoryModel` starts a polling timer.
3. `AccessibilityFinderClient` asks Finder for current accessibility windows and folder document URLs.
4. If Finder exposes windows through Accessibility but not their folder URLs, `AccessibilityFinderClient` falls back to indexed Finder Automation to read each Finder window `id` and `target`.
5. Finder window snapshots include the folder URL and optional restore state such as window bounds and view style.
6. `HistoryReducer` compares the previous and current snapshots by window identity.
7. Closed window targets are converted to `HistoryEntry` values.
8. `HistoryStore` persists the trimmed history JSON in Application Support.
9. `MenuBarView` renders the history and calls the Finder client to reopen folders, restoring captured state when available.

## Key Boundaries

- `FinderClient`: the only boundary that knows how Finder is queried or commanded.
- `HistoryReducer`: pure close-detection and trimming rules.
- `HistoryStore`: JSON schema and disk persistence.
- `FolderDisplayFormatter`: display name and parent path formatting.
- SwiftUI views: presentation and user actions only.

## Permissions

Finder access uses macOS Accessibility. Users must enable FinderHistory in System Settings > Privacy & Security > Accessibility. On macOS versions where Finder does not expose folder URLs through Accessibility, FinderHistory also asks for Finder Automation permission and uses a fixed, internal script to read Finder window ids and targets.

The app is not sandboxed in v1 source builds.

`script/build_and_run.sh` stages the runnable app at `~/Applications/FinderHistory.app`, registers it with LaunchServices, and signs it with the first available local code-signing identity. If no local identity is available, it falls back to ad-hoc signing. Set `FINDERHISTORY_CODESIGN_IDENTITY` to force a specific identity. Public binary distribution should use Developer ID signing and notarization.

## Persistence

History is stored at:

```text
~/Library/Application Support/FinderHistory/history.json
```

The schema is documented in `docs/history.schema.json`.
