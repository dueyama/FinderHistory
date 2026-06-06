# AGENTS.md

This repository is designed to be easy to extend with Codex.

Before making changes, read `docs/SAFETY_REVIEW.md` and `docs/AI_MAINTENANCE.md`.

## User Shortcut: Install This App

If the user asks Codex to install this app, treat that as a request to do the full safe local source-build workflow. The user should not need to type commands manually.

Accept prompts such as:

```text
Install this app from this repository:
https://github.com/dueyama/FinderHistory
```

or:

```text
このレポを使って、このアプリを入れて:
https://github.com/dueyama/FinderHistory
```

When handling that request:

1. If starting from a repository URL, clone or update the repository first.
2. Read `docs/SAFETY_REVIEW.md`.
3. Inspect the files listed there before running the app.
4. Present the safety-check results to the user, including inspected files, permissions, local data storage, scripts, network behavior, and any risks.
5. Ask the user whether to continue with installation.
6. Do not run `swift test`, `./script/build_and_run.sh`, or launch the app until the user explicitly approves continuing.
7. If approved, run `swift test`.
8. Run `./script/build_and_run.sh --verify`.
9. Tell the user which macOS prompts to approve: Accessibility, and Finder Automation if prompted.
10. Verify the workflow by opening and closing a Finder window and checking that it appears in the menu-bar history.

Do not publish, tag, create a release, or push to GitHub unless the user explicitly asks.

## Project Shape

- `FinderHistory` is the executable SwiftPM target.
- `FinderHistoryCore` contains app logic, SwiftUI views, Finder access, persistence, localization, and testable reducers.
- Tests live under `Tests/FinderHistoryCoreTests`.

## Implementation Boundaries

- Finder access belongs behind `FinderClient`.
- Accessibility-specific code belongs in `AccessibilityFinderClient`.
- History load/save belongs in `HistoryStore`.
- Window close detection belongs in `HistoryReducer`.
- UI copy must use `L10n.string` and be added to both English and Japanese `Localizable.strings`.
- Persisted history changes must update `docs/history.schema.json`.

## Safe Extension Rules

- Add or update tests for reducer, store, or formatting changes.
- Keep persisted JSON compatible with `docs/history.schema.json`.
- Do not add network behavior without updating README privacy notes.
- Do not add arbitrary runtime script execution in v1; prefer explicit source-level extension points.
- Keep Finder Automation fixed and internal; do not add user-provided scripts.
- Keep the app menu-bar-only unless the product decision is intentionally changed.

## Validation

Run these before handing off changes:

```bash
swift test
./script/build_and_run.sh --verify
```

If Accessibility permission is denied during manual testing, reset or re-enable it in System Settings > Privacy & Security > Accessibility.

For public release cleanup, remove ignored local artifacts such as `.build/`, `dist/`, and `.DS_Store` from the working tree before packaging or publishing.
