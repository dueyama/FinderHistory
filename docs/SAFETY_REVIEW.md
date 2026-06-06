# Safety Review Guide

Use this guide before Codex runs FinderHistory from source. The expected flow is: fetch the repository, inspect it, show the safety-check results to the user, ask whether to continue, then run validation only if the user approves.

## Suggested Codex Prompt

```text
Please fetch this FinderHistory repository into a new local checkout, then review it for safety before running it.

Repository:
https://github.com/dueyama/FinderHistory

Check:
- whether the app uses any network APIs
- what local files it reads and writes
- what macOS permissions it requests
- whether build scripts install, sign, or launch anything unexpected
- whether Finder Automation is fixed and scoped to Finder window metadata
- whether arbitrary runtime plugins, shell commands, or user-provided scripts can execute inside the app
- whether docs and code agree about privacy and permissions

Report:
- blockers that should be fixed before running
- acceptable risks I should understand
- exact files you inspected
- exact commands you will run only if the review passes
- permission prompts I should approve or deny

After reporting the results, ask me whether to continue. Do not run tests, build, or launch the app until I explicitly approve.
```

## Required Review Stop

Codex must stop after the safety review and show the user a concise report before running validation or launching the app.

The report should include:

- Verdict: `pass`, `pass with notes`, or `blocked`.
- Files inspected.
- Network behavior.
- Local data written.
- macOS permissions requested.
- Scripts that will run.
- Any fixed Automation behavior.
- Any risks or caveats.
- Commands Codex proposes to run next.

Then ask:

```text
Do you want me to continue with tests, local build, and launch verification?
```

Only continue after explicit user approval. If the review is blocked, do not continue until the blocker is fixed.

## Files To Inspect

After cloning or updating the repo, inspect:

- `Package.swift`
- `Sources/FinderHistory/main.swift`
- `Sources/FinderHistoryCore/Services/FinderClient.swift`
- `Sources/FinderHistoryCore/Services/AccessibilityFinderClient.swift`
- `Sources/FinderHistoryCore/Stores/HistoryStore.swift`
- `Sources/FinderHistoryCore/Stores/AppPreferences.swift`
- `script/build_and_run.sh`
- `script/build_app_icon.sh`
- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/history.schema.json`

## Expected Permission Model

FinderHistory is expected to request:

- Accessibility permission, to observe Finder windows.
- Finder Automation permission, only when Accessibility exposes Finder windows but not folder URLs.
- Launch at Login registration only when the user enables it in Settings.

FinderHistory should not request:

- Contacts, Calendar, Photos, Microphone, Camera, Location, or Full Disk Access.
- Network access.
- Runtime plugin execution or arbitrary script execution.

The app uses a fixed internal AppleScript only for Finder window `id`, folder target, bounds, view style, and state restoration.

## Expected Local Data

FinderHistory stores history at:

```text
~/Library/Application Support/FinderHistory/history.json
```

The file may contain:

- local folder URLs
- display names
- parent paths
- close timestamps
- optional Finder window bounds and view style

The app should not transmit this data.

## Expected Codex Commands

Codex should run validation commands only after the safety review passes and the user approves continuing:

```bash
swift test
./script/build_and_run.sh --verify
```

The run script should:

- build with SwiftPM
- stage `~/Applications/FinderHistory.app`
- copy resources and the app icon
- sign with a local code-signing identity when available, or ad-hoc otherwise
- register the app with LaunchServices
- launch or verify the app

It should not download dependencies, contact external services, or modify files outside the app bundle except normal SwiftPM build output and the staged app bundle.

Local Apple Development signing is acceptable for source review builds even if it is not suitable for public binary distribution. Public downloadable binaries should be Developer ID signed and notarized outside this script.

## Release Safety Checklist

- `swift test` passes.
- README privacy and permission notes match the implementation.
- `docs/history.schema.json` matches persisted history.
- `.build/`, `dist/`, `.DS_Store`, and other generated files are not tracked.
- No secrets, personal paths, or local test history are committed.
- Public binary releases are Developer ID signed and notarized; source builds may be locally signed.
