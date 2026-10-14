# ClipPocket product requirements

## Overview

ClipPocket is a local macOS menu bar utility that preserves copied text, makes earlier entries easy to search and reuse, and pastes a selected sequence into separate fields. It solves repeated copying, losing an earlier copied value and switching back and forth while filling forms. It is Project 02 of a personal Fun Projects series, with a working app as the outcome.

## Goals and objectives

1. Recover and reuse recently copied text without revisiting the source.
2. Fill several fields from an explicitly ordered queue without repeatedly opening history.
3. Keep capture, storage, search and paste entirely local with predictable controls.
4. Make the common path fast and keyboard-first while preserving data and clipboard behavior.
5. Deliver a reproducible installed application with real acceptance evidence.

No subscriptions, login, backend, sync, analytics service, AI transformation or paid APIs in V1. Text, plain-text links and supported rich-text representations are the scope. Images, arbitrary files, OCR and shared libraries are deferred; unused inherited features must not distract from P0 work.

## Users and jobs

The primary user is a Mac developer who copies client details, code, links and messages. Frequent jobs: retrieve an earlier snippet; paste without formatting; pin a reusable address; copy Name/Email/Address and paste in the same explicitly selected order. The app must handle English, Roman Urdu, native Urdu/RTL and code without corrupting characters or whitespace.

## Requirements

| ID | Priority | Requirement | Acceptance |
| --- | --- | --- | --- |
| CP-01 | P0 | Observe eligible clipboard changes | Normal-speed text copies are captured once; empty/unsupported/ignored copies excluded |
| CP-02 | P0 | Persist history and deduplicate | Relaunch retains entries; exact duplicates refresh recency/copy count without multiplying records |
| CP-03 | P0 | Shortcut, search and selection | Open compact panel, type, navigate and select fully by keyboard |
| CP-04 | P0 | Copy and direct paste | Copy-only works without Accessibility; direct paste restores a verified previous target |
| CP-05 | P0 | Ordered multi-item queue | Explicit selected order is visible and preserved; Paste Next dispatches one item |
| CP-06 | P0 | Queue controls and safety | Reorder/remove before activation; Skip, Pause/Resume and Cancel during queue; no double advance |
| CP-07 | P0 | Pins and retention | Pins survive relaunch; limits/age rules visible; clear unpinned preserves pins |
| CP-08 | P0 | Plain-text mode | Strip formatting only; retain exact text, Unicode, line breaks and code indentation |
| CP-09 | P0 | Capture pause and exclusions | Clear state; sensitive/transient types and configured apps ignored |
| CP-10 | P0 | Permissions and failure states | Actionable Accessibility flow, copy-only fallback, no crash or broad-access workaround |
| CP-11 | P0 | Separate product identity/data | ClipPocket UI, bundle IDs, store and settings; no original updater or data mutation |
| CP-12 | P0 | Responsive bounded behavior | Search/UI responsive; polling, memory, storage and queue bounded; metrics measured |
| CP-13 | P0 | Offline runtime | No external API, service account or runtime network requests for V1 |
| CP-14 | P0 | Installable working delivery | Release `.app`, repeatable local build/install, tests and evidence report |
| CP-15 | P0 | Long/Unicode/editor compatibility | Full payload retained despite previews; tested supported editors and honest limitations |

P0 is required. Optional launch at login and small appearance preferences are P1 after the usable core. Clipboard history may only observe the latest state between polls; it cannot recover a value overwritten before observation. Do not market microsecond-burst capture guarantees.

## User experience

Default panel shortcut proposal: Command-Shift-C. It may conflict with app tools, so detect/allow reassignment. Proposed Paste Next shortcut: Control-Option-Command-V, configurable. Native app permission and shortcut behavior must be tested locally.

Panel opens with search focused, latest entries below a pinned section and two-line previews. Enter pastes the selected entry when direct-paste mode is ready; otherwise copies it and explains the remaining manual Command-V action. A visible Copy action always exists. Plain-text mode is selectable. Queue mode adds selection checkboxes with explicit order numbers; Build Queue shows a review of order, not an immediate paste.

Activate the reviewed queue, close the panel and focus the first field. Each Paste Next dispatches the next value to the currently verified field. Normal Command-V remains normal and does not consume the queue. Moving to another application is allowed between explicit queue commands; no automatic typing follows focus changes. External copy pauses the queue while still recording the new eligible history entry. Resume revalidates; it never overwrites a fresh external clipboard just to preload an idle queue.

## Defaults and boundaries

- macOS 14+; native Swift/AppKit/SwiftUI and existing Xcode project.
- Capture text representations only by default; cloud/OCR/media processing disabled.
- Clipboard polling starts at 100 ms, reads payload only after change; measure idle cost before tuning.
- Retain up to 500 unpinned entries and up to 100 pins, within a 50 MiB accounted payload budget; expire unpinned entries after 30 days. Pins are protected from automatic eviction. Refuse a new pin with a clear explanation at its limit.
- Maximum entry payload 2 MiB and maximum queue 50 entries. Limits are documented and configurable where safe. Oversized items are skipped with a local status, never silently truncated.
- Queue is in-memory and cleared on quit/relaunch. History survives. Pause capture is independent of queue Pause.
- Normal clipboard content is not cleared on app quit or history clear unless explicitly enabled. No silent import of another app's history.

## Success metrics

These are acceptance targets, not measured claims. Run on the actual Mac with a stated item count, app versions and methodology.

| Metric | Target | Measurement |
| --- | --- | --- |
| Capture correctness | All 50 eligible normal-speed copies in the controlled test appear correctly | Copies spaced at least 250 ms; explicit expected list |
| Open responsiveness | Panel p95 at most 150 ms | 100 opens after warm launch; cold launch reported separately |
| Search responsiveness | p95 at most 100 ms at 1,000 test entries | Isolated seeded test store; query set includes Unicode |
| Ordered dispatch | 50 queue attempts have correct order with zero double advances | Targeted fixtures plus real form trials |
| Relaunch persistence | 100% of eligible saved test entries and pins retained | Close/reopen and compare payloads |
| Safety | Zero unintended paste on cancellation, blocked target or stale session tests | Adversarial unit and real editor cases |
| Runtime networking | Zero application-initiated network requests during V1 test | Inspect requests/updater and run offline |
| Resource bounds | Finite queues/store; no sustained growth over a 30-minute test | Poll interval, CPU and RSS measured; no fabricated hardware-independent number |

## Definition of done

All P0 requirements have implementation and evidence. The installed app captures, persists, searches and pastes actual copied text. Real TextEdit and browser-form queues pass; permissions, interference, limits and recovery work. Native release build and meaningful tests pass, identity/data are isolated, legal notices are included and runtime works offline. A UI preview or source-only delivery does not meet this definition. If a native permission blocks a real test, use the status Implemented but verification blocked and identify the exact remaining action.
