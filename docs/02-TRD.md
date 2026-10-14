# ClipPocket technical requirements

## Platform and structure

Start from the exact source baseline in `12-SOURCE-INTEGRATION.md`. Keep its Xcode build and package lockfile initially, inspect test plans and build locally before changing dependencies. The baseline targets macOS 14 and uses Swift's version 5 language mode; that is not a Swift 5.0 compiler recommendation. Use an installed Xcode/Swift toolchain that supports its actual source/dependencies. Do not upgrade to a moving development branch without evidence.

## Components

| Component | Responsibility |
| --- | --- |
| ClipboardMonitor | Poll changeCount; collect eligible text payloads; detect external vs app-written events |
| CapturePolicy | Empty/unsupported/type/app exclusions; size limits and pause |
| HistoryRepository | SwiftData persistence, deduplication, pins, retention and versioned migration |
| SearchIndex | Bounded in-memory search over previews/full text; no external service |
| PanelController | Panel visibility, keyboard focus and previous app/field descriptor |
| PasteExecutor | Verify target, prepare clipboard snapshot, serialize and dispatch native paste |
| QueueCoordinator | Immutable ordered snapshots, pointer, pause/cancel, exactly-once dispatch accounting |
| PreferencesStore | App-local preferences and configurable shortcuts |
| Diagnostics | Durations/counters/error codes without payloads or titles |
| TextTransformation seam | Future explicit transformation interface; identity/no-op only in V1 |

MainActor owns native UI, pasteboard access where required and SwiftData main-context operations. Use appropriate serial workers for hashing/search work; never pass live non-Sendable model objects freely across workers. Queue and dispatch have one authoritative coordinator. Keep interfaces small; do not add a generic agent framework.

## Capture algorithm

Read `NSPasteboard.general.changeCount` on a lightweight timer. If unchanged, do nothing. On change, obtain a bounded snapshot of allowed text types, apply ignore policy before persistence and calculate a stable exact payload key. Plain text is not trimmed or case-folded for deduplication; code whitespace matters. Preview normalization is separate. Keep rich-text representations with a valid text fallback within limits; no network fetches to build link previews.

Ignore self-generated clipboard writes with a ClipPocket-specific marker plus an expected change-count transaction. Do not use a timer-only suppression flag that can swallow unrelated user copies. Own writes do not re-add history or advance queues. When a newer external copy appears, it remains normal eligible history, but an active queue transitions to Paused with reason Clipboard changed. Pending queue snapshots are unchanged.

Capture cannot observe values replaced between polls. Source change-count jumps are diagnostics, not a reliable list of missed entries. Start at 100 ms, pause the timer on termination, avoid busy loops and inspect responsiveness/CPU. Polling adjustments must not cause a capture-fidelity claim beyond measured behavior.

## History and search

Canonical identity uses exact text bytes plus relevant stored representation signatures, according to a documented deterministic serialization. Collision resolution compares payloads, not hash alone. The same plain text with different meaningful formatting can remain separate entries; explain this in implementation notes. Exact duplicates update recency/copy count without unpinning or changing queue snapshots. Search can normalize text for matching independently of stored content; preserve RTL and case-insensitive matching where sensible.

Load only bounded metadata/previews for a panel page; read a full payload for preview/paste as needed. Large previews are capped; pasted content is not. Pins have stable identity and user-defined order. Retention protects pinned entries and respects the byte budget. When pins themselves exhaust the budget, reject new capture/pins visibly instead of evicting pins silently.

## Paste transaction

1. Acquire a target descriptor: foreground process and editable focused element where accessible. On panel opening capture the previous target; menu/panel controls must not become a paste destination.
2. On explicit Paste/Paste Next, serialize dispatch. Reject secure/read-only/invalid targets, inaccessible permission state, shutdown/cancel and an already-running dispatch.
3. Snapshot the chosen original or plain-text payload. For a queue use its immutable entry snapshot and generation, not the live history row position.
4. Close the panel without stealing the final target. Activate the captured target only for a selected-item panel paste; for queue shortcuts use the user's currently focused target. Wait for actual focus/activation confirmation with a finite timeout rather than a blind arbitrary sleep.
5. Revalidate target and queue generation. Write the payload and own marker to the system clipboard; record its change count. Before key dispatch confirm no newer external clipboard change. If one occurs, pause and do not overwrite it again or consume the queue entry.
6. Submit the platform paste event through a tested native mechanism. Suppress self-event queue observers; complete one in-flight transaction. Advance exactly once only after the executor reaches its valid dispatched result.
7. Keep the last dispatched payload on the system clipboard, like normal paste. Do not restore older clipboard contents automatically or preload the next queue item while idle. Display next entry in the app only.

Native event posting is not a general editor-acceptance acknowledgement. Define result `dispatched` honestly; where an editor supports reliable content verification, add it to integration tests. A rejected preflight or dispatch error does not advance. For an uncertain post-dispatch result, pause with an explicit Retry last item action so retries are user-controlled; never automatically send again and duplicate field contents.

Focus can change during cross-process dispatch and there is no global OS transaction lock. Use last-moment checks and test the timing; do not claim atomic universal paste. Do not use broad screen scraping or document-wide replacement to fake verification. Unsupported editors fall back to copy-only with visible manual paste instructions; real compatibility is reported.

## Queue algorithm and states

States: Empty, Reviewing, Ready, Dispatching, Paused, Completed, Cancelled. Each session has a generation and immutable snapshots with stable queue-entry UUIDs. Assign order by explicit selection badges; the review supports drag or keyboard reorder. Never derive paste order from recency after activation.

Only a dedicated Paste Next command consumes an entry. Do not retain the original stack listener that advances on arbitrary Command-V. Debounce key repeat and permit only one in-flight dispatch. A successful dispatch moves the pointer once. Skip moves the pointer without changing the clipboard. Pause stops execution; Resume verifies prerequisites but does not paste automatically. Cancel increments generation and clears snapshots; events submitted before cancellation cannot be undone, but no not-yet-submitted paste may occur afterward.

History deletion/eviction cannot invalidate queue contents because snapshots own their payloads. External copies pause, not mutate. Sleep/session lock pauses active work; relaunch clears queue. History-recording pause is independent and must not inadvertently arm/disarm a queue. Queue max 50, per-entry max 2 MiB and a separately bounded total snapshot budget no greater than the store budget.

## Errors and observability

Classify permission missing, target invalid, shortcut conflict, clipboard interference, storage failure, oversized content and canceled generation. Show the closest actionable message. Log action IDs, item/queue UUIDs, durations, counts and error categories; no copied titles, bodies, URLs, clipboard contents or screen text. Audit retained source logs specifically, not only newly written code.

## Runtime and future boundaries

Disable original updater/feed, external review prompts, website actions and networked metadata features. V1 needs no remote backend. Future AI can use an explicit transform adapter that returns a new proposed snippet, preserving the original. No model, network path, auto-upload, consent dialog or AI UI in V1. See `11-FUTURE-AI-EXTENSION.md`.
