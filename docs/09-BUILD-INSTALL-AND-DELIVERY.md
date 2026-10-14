# ClipPocket build installation and delivery

## Required developer inspection

Inspect `sw_vers`, `uname -m`, `xcode-select -p`, `xcodebuild -version`, installed Swift and current git status. Obtain the pinned source, verify the commit, inspect the Xcode project/test schemes and resolve the retained package lockfile. The baseline targets macOS 14 and uses Swift 5 language mode. Do not guess a build command or introduce a toolchain upgrade before trying the actual project.

## Identity and packaging

Displayed name ClipPocket; bundle ID `dev.funprojects.clippocket`; distinct unit/UI test IDs; app-local preferences and store; original minimal clipboard icon assets. Internal source file names can remain if mass renaming is unnecessary. All ordinary visible strings/menus/window titles/settings refer to ClipPocket. Original authors' notices and dependencies' license text stay in legal resources.

Remove inherited signing team constraints for local development; choose a legitimate local signing path. Build for the detected Mac architecture initially. App Store publishing/notarized distribution/universal builds are outside this personal V1. Stable install location reduces permission confusion but does not guarantee permissions survive signature changes.

Original updater initialization and feed must be disabled/removed, not simply relabeled. No Check for Updates button backed by another product's server. Remove source-specific rating/store/support website actions from normal UI, or replace with local help. Legal references are static text, not automatic network calls.

## Deliverable files the agent must produce

| Output | Purpose |
| --- | --- |
| `artifacts/ClipPocket.app` | Working locally installable release bundle |
| `scripts/build-local.sh` | Validated repeatable native release build |
| `scripts/test-local.sh` | Actual retained/new test commands with correct scheme |
| `scripts/install-local.sh` | User-local install without destroying unrelated data |
| `README.md` | Actual build/run/shortcuts/permissions and limits; normal ClipPocket product copy |
| `DELIVERY-REPORT.md` | Filled report with requirements and evidence |
| Bundled Legal Notices | Original code/dependency notices, available locally |

Prefer `~/Applications/ClipPocket.app` for a user-local install. Preserve preferences and history during replacement. Gracefully stop the old ClipPocket instance; do not force-close editors or overwrite the original source app. Native permissions are checked using the installed bundle rather than only a debug executable.

## First-use instructions

Launch the installed app; copy fictional text to check recording; open the configured picker shortcut; use Copy without permission. To enable direct paste/Paste Next, grant Accessibility through the native OS UI. Focus TextEdit/browser fields and try a three-entry queue. No microphone, Screen Recording, Full Disk Access, API key or account is required by the specified path. Explain any implementation-specific additional permission with evidence instead of requesting everything.

## Repository and runtime hygiene

Keep package locks, relevant tests, docs and required legal notices tracked. Ignore build outputs, private history stores, recordings, local diagnostics and secret files. Do not publish a GitHub remote automatically. Do not accidentally copy real user clipboard content into examples or screenshots. Synthetic fixtures are clearly marked and confined to test mode.

## Completion evidence

Provide actual build/test/install commands and results, architecture/OS, tested editor versions, queue checks, data isolation, migration/retention results, offline verification and measured performance. If a permission/environment blocks a case, name the CP IDs and shortest action, then mark that case Unverified. A compiler-only result is not the requested working delivery.
