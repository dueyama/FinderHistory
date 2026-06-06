# AI Maintenance Guide

FinderHistory is intentionally maintained as source that AI assistants can inspect and modify. Keep the project simple, explicit, and testable.

## Required Reading Order

Before changing code, read:

1. `README.md`
2. `docs/SAFETY_REVIEW.md`
3. `docs/ARCHITECTURE.md`
4. `docs/EXTENDING_WITH_CODEX.md`
5. `docs/CUSTOMIZATION_EXAMPLES.md`
6. `AGENTS.md`
7. The specific source files you will edit

## Non-Negotiable Invariants

- No network behavior unless README privacy notes and tests are updated.
- No runtime plugin system in v1.
- No arbitrary user-provided AppleScript, shell script, or command execution.
- For install requests, do not run tests, build, launch, or request permissions until the safety-check results have been shown and the user approves continuing.
- Finder access stays behind `FinderClient`.
- Finder-specific Accessibility and Automation code stays in `AccessibilityFinderClient`.
- SwiftUI views do not query Finder, read files, or run scripts directly.
- History persistence stays behind `HistoryStore`.
- Close detection stays pure and testable in `HistoryReducer`.
- UI strings must use `L10n.string` and be present in both English and Japanese localization files.
- Schema changes must update `docs/history.schema.json` and tests.

## Source Ownership Map

- `Sources/FinderHistory/main.swift`: app entry, menu-bar scene, activation policy.
- `Sources/FinderHistoryCore/Services/FinderClient.swift`: Finder access contract.
- `Sources/FinderHistoryCore/Services/AccessibilityFinderClient.swift`: macOS Accessibility, fixed Finder Automation fallback, Finder reopen/restore.
- `Sources/FinderHistoryCore/Models/FinderWindowSnapshot.swift`: current Finder observation.
- `Sources/FinderHistoryCore/Models/FinderWindowState.swift`: optional restorable Finder state.
- `Sources/FinderHistoryCore/Models/HistoryEntry.swift`: persisted history record.
- `Sources/FinderHistoryCore/Stores/HistoryStore.swift`: JSON load/save only.
- `Sources/FinderHistoryCore/Stores/HistoryReducer.swift`: window diffing, dedupe, trimming.
- `Sources/FinderHistoryCore/ViewModels/FinderHistoryModel.swift`: app state orchestration.
- `Sources/FinderHistoryCore/Views/*.swift`: presentation and user actions only.
- `Sources/FinderHistoryCore/Resources/*.lproj/Localizable.strings`: UI copy.
- `script/build_and_run.sh`: local build, bundle staging, signing, LaunchServices registration.
- `docs/history.schema.json`: persisted JSON contract.

## Common Change Routes

Add a row field:

1. Extend `HistoryEntry` if persisted.
2. Update `docs/history.schema.json`.
3. Update `HistoryStoreTests`.
4. Update `HistoryRowView`.

Change Finder observation:

1. Start at `FinderClient`.
2. Implement in `AccessibilityFinderClient`.
3. Keep AppleScript fixed and internal.
4. Add parser or reducer tests.

Change close-detection behavior:

1. Edit `HistoryReducer`.
2. Add tests in `HistoryReducerTests`.
3. Avoid touching UI or Finder access unless the contract changes.

Change settings:

1. Add preference key in `AppPreferences`.
2. Add UI in `SettingsView`.
3. Add localized strings.
4. Update README if user-facing behavior changes.

## Finder Automation Rules

Finder Automation is allowed only for fixed internal operations:

- read Finder window `id`
- read Finder window target folder URL
- read Finder window bounds
- read Finder window view style
- reopen a stored folder
- restore stored bounds and view style

Do not add user-editable scripts, plugin script hooks, shell execution, or general AppleScript execution.

## Logging Rules

- Normal polling, counts, menu opens, and successful saves should be `debug`.
- Permission waiting can be `info`.
- Real failures should be `error`.
- Do not log full history contents or folder lists.

## Validation Before Handoff

Run:

```bash
swift test
./script/build_and_run.sh --verify
```

For Finder behavior changes, manually verify:

1. Open a Finder window.
2. Confirm FinderHistory shows a non-zero watched window count.
3. Close the Finder window.
4. Confirm the row appears in the menu.
5. Click the row and confirm Finder reopens the folder.
6. If window state changed, inspect `~/Library/Application Support/FinderHistory/history.json` and confirm schema-compatible state.

## Public Release Cleanup

Before publishing:

- Remove `.DS_Store`, `.build/`, `dist/`, and local generated app bundles from the working tree.
- Keep `Assets/FinderHistory.icns` and `Assets/FinderHistorySource.png`.
- Regenerate icons with `script/build_app_icon.sh` only when the source image changes.
- Do not commit local `~/Library/Application Support/FinderHistory/history.json`.
- Do not commit personal signing identities, provisioning profiles, or notarization credentials.
