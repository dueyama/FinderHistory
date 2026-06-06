# Extending FinderHistory with Codex

Use this guide when asking Codex to change FinderHistory.

Before implementation, ask Codex to do a safety and boundary check using `docs/SAFETY_REVIEW.md` and `docs/AI_MAINTENANCE.md`.

For copy-paste user customization prompts, see `docs/CUSTOMIZATION_EXAMPLES.md`.

## Good Extension Requests

- "Show the close time in each history row."
- "Add a filter that hides folders under Downloads."
- "Add an Open in Terminal action for each available folder."
- "Change the row subtitle from parent path to full path."
- "Increase test coverage for history schema compatibility."

## Where to Change Things

- Finder polling or reopening behavior: `AccessibilityFinderClient` through the `FinderClient` protocol.
- Finder window restore state: `FinderWindowState`, `HistoryEntry`, `AccessibilityFinderClient`, and `docs/history.schema.json`.
- Close detection rules: `HistoryReducer`.
- JSON persistence: `HistoryStore` and `docs/history.schema.json`.
- Row display: `HistoryRowView` and `FolderDisplayFormatter`.
- Settings: `SettingsView` and `AppPreferences`.
- Text: both `en.lproj` and `ja.lproj` localization files.

## Constraints

- Keep the default history limit at 5 unless the product decision changes.
- Keep the menu item/list labels short.
- Preserve local-only behavior unless README privacy notes are updated.
- Avoid runtime plugins and arbitrary script execution in v1.
- Keep Finder Automation fixed and internal; do not add user-provided scripts.
- Add tests for behavior changes.

## Suggested Prompt Template

```text
Please extend FinderHistory to <goal>.
First review docs/SAFETY_REVIEW.md and docs/AI_MAINTENANCE.md.
Keep Finder access behind FinderClient, keep Automation fixed/internal,
update English and Japanese strings, update docs/history.schema.json if persistence changes,
and run swift test plus ./script/build_and_run.sh --verify.
```
