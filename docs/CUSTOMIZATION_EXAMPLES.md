# Customization Examples

FinderHistory is meant to be customized through Codex. Give Codex the repository URL, ask it to install or open the checkout, then ask for the customization you want. Codex should read `AGENTS.md`, `docs/SAFETY_REVIEW.md`, and `docs/AI_MAINTENANCE.md` before changing code. Codex should show the safety and boundary-check results, then ask whether to continue before editing, testing, building, or launching.

## Basic Prompt Shape

```text
Customize FinderHistory from this repository:
https://github.com/dueyama/FinderHistory

I want: <your customization>.

Follow AGENTS.md. Keep Finder access behind FinderClient, keep Finder Automation fixed/internal, update tests and docs if needed, then run validation.
Before editing, show me the safety and boundary-check results and ask whether to continue.
```

In Japanese:

```text
このレポの FinderHistory を自分用にカスタマイズして:
https://github.com/dueyama/FinderHistory

やりたいこと: <カスタマイズ内容>

AGENTS.md に従って、安全確認、テスト、ローカルビルド確認までやって。
Finder アクセスは FinderClient の内側に保ち、Finder Automation は固定の内部処理だけにして。
編集に入る前に、安全確認と変更方針を見せて、続行するか確認して。
```

## Example Requests

### Show Full Paths

```text
Customize FinderHistory so each history row shows the full folder path instead of the parent path.
Keep the row compact and run swift test.
```

Expected code area:

- `HistoryRowView`
- Possibly `FolderDisplayFormatter`

### Show Close Time

```text
Customize FinderHistory so each history row shows when the Finder window was closed, using a short local time format.
Update English and Japanese strings if visible labels change.
Add or update formatter tests.
```

Expected code area:

- `HistoryRowView`
- A small formatter in `Support/` if needed
- `FolderDisplayFormatterTests` or a new focused test

### Ignore Some Folders

```text
Customize FinderHistory to ignore closed Finder windows under ~/Downloads and ~/.Trash.
Keep the filter testable and add HistoryReducer tests.
```

Expected code area:

- `HistoryReducer`
- `HistoryReducerTests`
- README privacy/behavior notes if the filter becomes user-facing

### Add Open In Terminal

```text
Customize FinderHistory to add an "Open in Terminal" action for each available folder.
Do not add arbitrary shell execution. Use a fixed macOS open action for Terminal only, and explain the permission/security impact.
```

Expected code area:

- `FinderClient`
- `AccessibilityFinderClient` or a new fixed opener service
- `HistoryRowView`
- Localized strings

Safety note: this should open Terminal at a folder. It should not run user-provided commands.

### Change The Default History Limit

```text
Customize FinderHistory so the default history limit is 10 instead of 5.
Keep the settings range 1...50 and update tests/docs.
```

Expected code area:

- `AppPreferences`
- tests that assume the default limit
- README feature list

### Change Row Display

```text
Customize FinderHistory so rows show the folder name, then the full path, then a small restore-state indicator when window bounds were captured.
Keep the popover width stable and avoid adding a card layout.
```

Expected code area:

- `HistoryRowView`
- `HistoryEntry`
- Localized strings if adding visible labels

### Add A Folder Blocklist Setting

```text
Customize FinderHistory with a Settings field for ignored path prefixes.
Persist the setting locally, keep defaults empty, add tests for filtering, and update README privacy notes.
```

Expected code area:

- `AppPreferences`
- `SettingsView`
- `HistoryReducer`
- `HistoryReducerTests`
- Localized strings
- README

### Change The App Icon

```text
Customize FinderHistory with a new app icon from a source PNG I provide.
Keep Assets/FinderHistorySource.png as the editable source, regenerate Assets/FinderHistory.icns, and do not commit generated iconset folders.
```

Expected code area:

- `Assets/FinderHistorySource.png`
- `Assets/FinderHistory.icns`
- `script/build_app_icon.sh`

## Requests To Avoid

Avoid asking Codex to add these in v1:

- runtime plugins
- user-provided AppleScript execution
- shell command hooks
- network sync
- cloud backup
- background upload or analytics

If you need one of those, ask Codex to first write a design note and safety review instead of implementing it directly.
