# Implementation notes

Internal record of defaults and storage. Not product copy.

## Source

Pinned checkout `eb03ebac3bbf24044c797c06f4304b74e3187835` (tag 2.7.1), sparse, without the design-asset tree. Local branch `clippocket`. No remote was pushed.

## Identity

- Display name ClipPocket, bundle `dev.funprojects.clippocket`
- Tests `dev.funprojects.clippocket.tests`, UI tests `dev.funprojects.clippocket.uitests`
- Module name stays `Maccy` so existing tests import the same module
- Preferences domain follows the bundle id
- Store: `~/Library/Application Support/ClipPocket/Storage.sqlite`
- Sidecar `schema.version` is `1` after a successful open
- Signing team removed. Local builds are ad-hoc signed
- Original menu-bar and app icon bitmaps were replaced with a new clipboard drawing
- Sparkle is not linked. `SUFeedURL` and the Sparkle mach-lookup entitlements are gone. `appcast.xml` is not copied into the app

## Storage

SwiftData models remain `HistoryItem` and `HistoryItemContent`. Added fields, all with defaults so a new store opens without a custom migration stage:

- `entryID` UUID
- `dedupKey` SHA-256 of type plus exact bytes
- `pinOrder` optional integer
- `accountedBytes`
- `previewText` bounded display text

A failed open does not delete the sqlite file. The app shows “History could not be opened. Your data was not reset.” and uses an in-memory container only so the process can stay up.

## Queue

`QueueCoordinator` owns an in-memory session. Paste Next is Control-Option-Command-V. The old global Command-V listener is not installed. Command-V calls `noteNormalPaste` and does not move the pointer. An external copy pauses a ready or dispatching queue and does not edit snapshots.

## Logging

History insert/update logs byte counts. Titles and clipboard bodies are not logged. Menu bar text is not the last copy. Copy notifications that included the copied text are not sent.
