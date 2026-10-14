# ClipPocket backend and local data schema

## Backend decision

No remote backend is applicable to V1. No API routes, accounts, auth tokens, cloud database, sync or server deployment. Persistence is a local SwiftData store in `~/Library/Application Support/ClipPocket/Storage.sqlite`, owned by this app. Preferences use `dev.funprojects.clippocket`. SQLite physical tables are managed by SwiftData; do not assume this conceptual schema is raw SQL DDL.

## Baseline mapping

The inspected source uses SwiftData models `HistoryItem` and `HistoryItemContent`. History includes app attribution, first/last copy timestamps, copy count, pin and title; child payloads hold a pasteboard type and optional binary value, with cascading deletion. Retain tested behavior and isolate the store before schema changes. Its old model artifacts do not mean a new remote backend is needed.

## Proposed logical schema

| Entity | Field | Type and purpose |
| --- | --- | --- |
| HistoryEntry | id | Stable UUID, generated once |
| HistoryEntry | dedupKey | Deterministic payload signature; compare actual payload on collisions |
| HistoryEntry | firstCopiedAt / lastCopiedAt | Date values |
| HistoryEntry | copyCount | Positive integer |
| HistoryEntry | sourceBundleID | Optional observed source; unknown allowed |
| HistoryEntry | previewText | Bounded display/search preview; never the paste payload |
| HistoryEntry | isPinned / pinOrder | Bool and optional stable ordering integer |
| HistoryEntry | accountedBytes | Sum of retained payload sizes for budget checks |
| HistoryEntry | representations | To-many PayloadRepresentation; cascade delete |
| PayloadRepresentation | id | UUID |
| PayloadRepresentation | typeIdentifier | Pasteboard type string |
| PayloadRepresentation | bytes | Original bounded Data |
| PayloadRepresentation | entry | Parent relationship |

The agent may keep existing model names and add needed fields rather than rename everything. Document the implemented mapping. Do not create a second history store simply to match these conceptual names. Pins can retain the baseline's pin field and add an order property if less risky; stable queue snapshots do not depend on mutable shortcuts.

## In-memory queue schema

| Record | Fields | Lifetime |
| --- | --- | --- |
| QueueSession | UUID, generation, state, ordered entries, next index, format mode, pause reason | One session; not persisted |
| QueueEntrySnapshot | UUID, source entry UUID, original representations, plain-text fallback, short preview, byte count | Immutable until canceled/completed |
| PasteTransaction | UUID, session generation, queue entry UUID, target descriptor, expected clipboard changeCount, stage/result | One in-flight action |
| LastDispatch | Entry snapshot + submitted/uncertain result metadata | For explicit Retry last; cleared on cancel/quit |

History eviction/deletion does not delete an active queue payload. Bound the queue separately. Completion/cancel releases snapshots. Never restore an armed queue after restart; clipboard text must not paste automatically on launch.

## Preferences

Capture enabled; picker shortcut; Paste Next shortcut; copy/direct-paste default; original/plain formatting; limits/age; ignored apps/types; panel size/position; launch-at-login if implemented; diagnostics flag. Persist preferences only in the ClipPocket domain. Any one-time source-data import is out of scope; no automatic read or modification of another app's user data.

## Retention and migration

Fresh ClipPocket store first. Use a versioned schema/migration plan appropriate to the retained model definitions. Add stable identifiers and nonoptional fields with documented safe migration/default handling. Prove both fresh creation and migration of a synthetic older ClipPocket store. App upgrades preserve entries/pins; a failed load shows recovery instead of calling fatalError or deleting the database.

Retention removes oldest unpinned entries first, using actual saved timestamps. Pin protection and byte limits are explicit. Clear unpinned cascades representations only for unpinned entries. Clear all including pins requires confirmation. Plain clipboard content is unchanged unless an explicit separate option says otherwise.

Storage may be ordinary local plaintext under the user's OS account; do not label it encrypted without an implemented and tested encryption mechanism. Avoid exporting raw content in diagnostics/backups. Future AI outputs, if added later, need a distinct derived-entry link to the original and their own migration; no such table is required in V1.
