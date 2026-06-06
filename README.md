# FinderHistory

FinderHistory is a small macOS menu-bar utility that remembers recently closed Finder windows and reopens their folders from the menu bar.

The app is intentionally source-distributed for people who want a simple utility they can inspect, modify, and extend with Codex.

## Use With Codex

FinderHistory is intended to be fetched, reviewed, built, and maintained through Codex. You should not need to type build commands yourself. Give Codex the repository URL and ask it to clone the repo, inspect the source, show you the safety-check results, ask whether to continue, then run validation and launch the local app build only after you approve.

Start with this prompt:

```text
Install this app from this repository:
https://github.com/dueyama/FinderHistory
```

Codex should then:

1. Clone or update the repository in a local workspace.
2. Read `docs/SAFETY_REVIEW.md`.
3. Inspect the files listed in that checklist.
4. Show you the safety-check results, including permissions, data storage, scripts, network behavior, and risks.
5. Ask whether to continue with installation.
6. Do not run tests, build, or launch the app until you approve continuing.
7. If approved, run `swift test`.
8. Run `./script/build_and_run.sh --verify`.
9. Explain any Accessibility or Finder Automation prompt before you approve it.
10. Open and close a Finder window for verification, then confirm it appears in the menu-bar history.

For the review checklist used by this repository, see `docs/SAFETY_REVIEW.md`.

## Features

- Tracks Finder windows by Accessibility window identity, so navigating inside an existing window does not create a history item.
- Shows each closed window as a folder name plus its parent path.
- Reopens available folders from the menu-bar popover.
- Restores captured Finder window bounds and view style when available. Selection, tabs, and sidebar state are not restored in v1.
- Remembers 5 closed windows by default, configurable from 1 to 50.
- Stores history locally in Application Support as JSON.
- Includes English UI strings and Japanese localization.
- Provides Codex-friendly extension docs, schema, and tests.

## Requirements

- macOS 13 or newer
- Xcode command line tools or Xcode with SwiftPM support

FinderHistory uses macOS Accessibility to observe Finder windows. On first use, enable FinderHistory in **System Settings > Privacy & Security > Accessibility**.

On macOS versions where Accessibility exposes Finder windows but not their folder URLs, FinderHistory falls back to Finder Automation to read window `id` and `target`. macOS may show a prompt asking FinderHistory to control Finder; allow it so closed-window history can be recorded. This is local-only and does not run user scripts.

For source builds, the run script stages the app at `~/Applications/FinderHistory.app` by default and registers it with LaunchServices so macOS can display the app icon in privacy settings.

No paid Apple Developer Program membership is required for local source builds. If a local code-signing identity is available, the run script uses it automatically so Accessibility permissions remain stable across rebuilds. If no identity is available, the script falls back to ad-hoc signing; in that case macOS may treat each rebuilt app as a new app and you may need to remove and re-add FinderHistory in Accessibility settings.

To force a specific signing identity:

```bash
FINDERHISTORY_CODESIGN_IDENTITY="Apple Development: Example" ./script/build_and_run.sh
```

To force ad-hoc signing:

```bash
FINDERHISTORY_CODESIGN_IDENTITY="-" ./script/build_and_run.sh
```

A public downloadable binary should be Developer ID signed and notarized; that requires Apple Developer Program membership. The source build script is intended for local development and review, not for producing a trusted public binary release.

## Local Source Build

Ask Codex to run the local source build. Do not paste commands blindly; let Codex inspect the repo first and report what it will run.

The main build script is:

```bash
./script/build_and_run.sh
```

Codex may also use these modes while validating or debugging:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

The script builds the SwiftPM executable, stages `~/Applications/FinderHistory.app`, copies resources, signs the bundle, registers it with LaunchServices, and launches it. Codex should explain this before running it.

## Privacy

FinderHistory does not use the network.

Closed Finder window history is stored only on your Mac at:

```text
~/Library/Application Support/FinderHistory/history.json
```

The file contains local folder URLs, display names, parent paths, close timestamps, and optional Finder window bounds/view style. Use **Clear History** from the menu-bar popover or Settings to erase it.

## Extending with Codex

This repository is structured so Codex can make targeted changes safely:

- Finder Accessibility access lives behind a Finder client abstraction.
- History persistence lives behind the history store.
- Window diffing and trimming are covered by unit tests.
- `docs/history.schema.json` documents the persisted JSON shape.
- `docs/SAFETY_REVIEW.md` describes the pre-run safety review.
- `AGENTS.md`, `docs/AI_MAINTENANCE.md`, `docs/EXTENDING_WITH_CODEX.md`, and `docs/CUSTOMIZATION_EXAMPLES.md` describe safe extension paths.

Good first extensions include alternate row metadata, filters, additional open actions, or display formatting changes.

For copy-paste customization prompts, see `docs/CUSTOMIZATION_EXAMPLES.md`.

Runtime plugins and arbitrary script execution are deliberately out of scope for v1.

## 日本語メモ

FinderHistory は、最近閉じた Finder ウィンドウのフォルダをメニューバーから開き直すための小さな macOS アプリです。

ソースから実行する前に、GitHub の URL を Codex に渡し、clone と安全性チェックを依頼してください。Codex はチェック結果をユーザーに見せ、続行するか確認してから、テスト、ローカルビルド、起動確認に進む前提です。ユーザーが自分でコマンドを打つ前提ではありません。

初回利用時は、システム設定 > プライバシーとセキュリティ > アクセシビリティで FinderHistory を有効にしてください。許可しない場合、Finder ウィンドウの履歴を取得できません。

履歴はローカルの `~/Library/Application Support/FinderHistory/history.json` にだけ保存され、ネットワークは使用しません。

## License

MIT
