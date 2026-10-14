# ClipPocket delivery report

Status: **Implemented but verification blocked.** The release app is installed and records synthetic clipboard text. Direct paste and the ordered queue were not driven in TextEdit or a browser because this session cannot send keystrokes.

## Status and use

- App: `/Users/usama/Desktop/Fun Projects 2.0/ClipPocket/artifacts/ClipPocket.app`
- Installed: `~/Applications/ClipPocket.app`
- Build: `zsh scripts/build-local.sh`
- Test: `zsh scripts/test-local.sh`
- Install: `zsh scripts/install-local.sh`
- Open the clean clipboard picker: Shift-Command-V
- Paste Next: Control-Option-Command-V
- Command-V is unchanged
- To paste directly, allow ClipPocket in System Settings → Privacy & Security → Accessibility. History and Copy work without it.

## Environment and build

- Mac: Intel Core i7-7700HQ, x86_64
- macOS 15.7.3 (24G419)
- Xcode 26.3 (17C529), Swift 6.2.4
- Source commit: `eb03ebac3bbf24044c797c06f4304b74e3187835` (tag 2.7.1)
- Built architecture: x86_64, ad-hoc signature, no team id
- Bundle id: `dev.funprojects.clippocket`
- Store: `~/Library/Application Support/ClipPocket/Storage.sqlite`
- Preferences domain: `dev.funprojects.clippocket`
- Sparkle is not linked. The built Info.plist has no `SUFeedURL`. The executable has no update-feed URL.
- The unmodified baseline build did not finish. Resolving packages stopped while cloning Sparkle (`RPC failed; curl 92`, early EOF). ClipPocket does not use that package.
- Unit tests, last full run: 95 tests, 0 failures (`xcodebuild -only-testing:MaccyTests test`, exit 0).
- Release build after that: `scripts/build-local.sh` exit 0.
- The installed bundle includes a ClipPocket-specific `AppIcon.icns`; the menu-bar item uses a standard 15-point template clipboard symbol.
- Public repository: https://github.com/Usama-riaz-101/ClipPocket
- Release: https://github.com/Usama-riaz-101/ClipPocket/releases/tag/v1.0.0
- Direct app download: https://github.com/Usama-riaz-101/ClipPocket/releases/latest/download/ClipPocket-macOS.zip
- Release package: 4.2 MB universal binary (`x86_64 arm64`), ad-hoc signed, SHA-256 `09bcbbf6a6cf2bcafcfe3c0532c091572ee234a138b9113073ba438b5f093820`.

## Requirement evidence

| CP ID | Implemented behavior | Automated evidence | Installed-app evidence | Result |
| --- | --- | --- | --- | --- |
| CP-01 | Text copies are stored once; empty, concealed, transient, ignored-app, and oversized copies are skipped | ClipboardTests and PolicyTests passed | Synthetic `CPXName441`, `CPXEmail441`, `CPXAddress441` were stored as `public.utf8-plain-text` | Pass for synthetic capture |
| CP-02 | Relaunch keeps entries; exact duplicates refresh one row | HistoryTests passed; fresh temp store reopened with pin and text | One synthetic token was still in the store after quit and relaunch | Pass |
| CP-03 | Panel opens with search focused; arrows, Space, and Return are wired | Existing list and key-handling code plus queue selection mode | Not driven. System Events returned error 1002 | Unverified in the installed app |
| CP-04 | Copy works without Accessibility. Direct paste restores a checked target and posts Command-V only after that check | Paste executor compiles; invalid-target path is unit-tested on the coordinator | TextEdit was opened. Keystrokes could not be sent, so the document stayed empty | Unverified |
| CP-05 | Explicit order, snapshots, Paste Next | QueueCoordinatorTests passed, including order, snapshot survival, and Command-V not advancing | Name/Email/Address were captured. The queue was not pasted into a form | Unverified in editors |
| CP-06 | Skip, pause, resume, cancel, one in-flight dispatch | QueueCoordinatorTests passed | Not driven in an editor | Unit-tested; editor run Unverified |
| CP-07 | Pins kept; unpinned expiry and budget; pin round-trip | PolicyTests retention, pin budget, and store reopen passed | Pin UI was not clicked | Unit-tested |
| CP-08 | Plain text keeps characters and whitespace; formatting is omitted only when requested | Dedup key differs for whitespace; title tests passed | Live whitespace copy was not rechecked after an earlier stalled capture | Unit-tested |
| CP-09 | Pause, concealed, transient, ignored apps | PolicyTests and ClipboardTests passed | Recording was paused with `ignoreEvents` during the idle sample, then turned back on | Pass |
| CP-10 | Copy-only without Accessibility; no extra permission prompts | Panel explains Accessibility. Capture worked before any prompt | Accessibility was not granted. No crash | Copy path Pass; direct paste Unverified |
| CP-11 | Separate id, store, defaults; no original feed | Bundle id and plist checked. No feed strings in the final executable | Store created under ClipPocket. No Maccy Application Support directory was present. `lsof` showed no sockets for the app | Pass |
| CP-12 | Bounded history and queue | Search benchmark and 60 idle samples | See Metrics | Pass for those measurements. Panel-open time Unmeasured |
| CP-13 | No runtime network | Final executable has no update URL. Running pid 17680 had no sockets | Same | Pass |
| CP-14 | Release app, scripts, tests | Release build exit 0. 95 unit tests passed | Installed at `~/Applications/ClipPocket.app` | Pass for build and install. Editor acceptance Unverified |
| CP-15 | Full payload kept; previews are short | Store reopen kept `pin-me` plus a newline, tab, and Urdu | A later `pbcopy` of `سلام` plus a newline and tab was stored as UTF-8 | Payload Pass. Editor acceptance Unverified |

## Editor compatibility

| App/version and field | Direct paste | Plain paste | Ordered queue | Limits |
| --- | --- | --- | --- | --- |
| TextEdit | Unverified. A new document was created. Keystrokes were refused (osascript error 1002), so nothing was pasted | Unverified | Unverified | Not exercised |
| Browser form | Unverified. Chrome was running; no form was driven | Unverified | Unverified | Not exercised |
| Notes | Unverified | Unverified | Unverified | Not exercised |
| Cursor / VS Code | Unverified | Unverified | Unverified | Not exercised |

## Metrics

Hardware: i7-7700HQ, macOS 15.7.3, x86_64.

- Capture: three labeled synthetic strings plus one earlier token were stored. Copies were spaced by about 0.4 s. A 50-copy cadence run was not done.
- Panel open: Unmeasured. The panel could not be opened from this session.
- Search: 1,000 in-memory entries, 100 searches (25 rounds of 4 queries, including `سلام`). Setup 236 ms. p50 7.94 ms, p95 10.05 ms. This is `Search.search` in the test process, not the on-screen panel.
- Queue: coordinator tests passed with zero double-advances in those cases. No editor attempt count.
- Relaunch: the checked synthetic token was present after quit and relaunch.
- Idle, recording paused so the poll loop ran without saving clipboard text: 60 samples, 30 seconds apart. CPU p50 0.0%, p95 0.1%, max 1.6%. RSS p50 74,692 KB, p95 85,060 KB, max 85,164 KB. The last 10 samples were flat at 74,380 KB.

## Isolation and data lifecycle

- New store directory and `schema.version` of `1` were created on first launch.
- A temporary store reopened with the same pin, order, newline, tab, and Urdu text.
- A file of garbage bytes was left unchanged when `ModelContainer` failed to open it.
- Final executable does not contain the old update feed or website URLs.
- LICENSE and NOTICES.txt are in the app bundle. The panel footer opens Legal Notices.
- The session store was deleted before the idle sample because the running app had also seen other clipboard changes while Chrome was frontmost. It was not uploaded.

## Remaining actions

Grant Accessibility to `~/Applications/ClipPocket.app`, then:

1. Paste one history entry into the middle of a TextEdit document (CP-04, CP-15).
2. Build a Name / Email / Address queue and paste it into three browser fields with Control-Option-Command-V (CP-05, CP-06).
3. Confirm Command-V does not advance the queue, and that a new copy pauses it.

Those three checks are the unverified editor cases. No further implementation step is waiting on a prompt from this session.
