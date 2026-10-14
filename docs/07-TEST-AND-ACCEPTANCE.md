# ClipPocket testing and acceptance

## Automated regression tests

Run relevant retained source tests before and after modification, then add tests for the queue contract and identity separation. Use an isolated synthetic store/preferences suite. Do not read the user's actual history as test input.

| Test | Scenario | Expected | CP IDs |
| --- | --- | --- | --- |
| T01 Capture policy | Text/empty/unsupported/concealed/transient/ignored app | Only eligible bounded payload retained | CP-01,09 |
| T02 Own write | Copy or paste originating from ClipPocket | No duplicate history or queue consumption | CP-01,05 |
| T03 Exact duplicate | Same payload twice; meaningful whitespace variant | Exact duplicate promotes once; variant preserved | CP-02,08 |
| T04 Persistence | Save entries/pins then open fresh repository | Exact data and pin state retained | CP-02,07 |
| T05 Selection order | Select recency rows in custom order, then recency changes | Reviewed order unchanged | CP-05 |
| T06 Queue snapshot | Delete/evict original history row during queue | Pending snapshot still usable | CP-05,07 |
| T07 Double shortcut | Repeated keyDown/in-flight duplicate command | One dispatch and one pointer advance | CP-06 |
| T08 Normal Command-V | Paste while queue Ready | Queue pointer unchanged | CP-05,06 |
| T09 External copy | New copy during Ready/pre-dispatch | History records; queue pauses; no unwanted clipboard overwrite | CP-01,06 |
| T10 Cancellation race | Cancel before/during submission boundary | No not-yet-submitted paste after cancel; stale completion ignored | CP-06 |
| T11 Invalid target | Secure/read-only/missing/changed target | No dispatch/advance; actionable state | CP-04,10 |
| T12 Uncertain dispatch | Executor cannot establish result after posting | Explicit recovery; no automatic replay | CP-04,06 |
| T13 Queue controls | Skip, Pause, Resume, Cancel and Complete | Deterministic pointer; no clipboard preload/resume paste | CP-06 |
| T14 Unicode and plain text | Emoji, Urdu, combining marks, tabs and code | Exact text survives; only formatting removed | CP-08,15 |
| T15 Retention | Limits, expired entries, pins/budget exhausted | Unpinned evicted; pins protected; no silent truncation | CP-07,12 |
| T16 Migration/store error | Synthetic old schema/corrupt store | Safe migration or visible recovery; no data reset | CP-02,10 |
| T17 App isolation | Source app data exists; separate identity starts | No read/write to original store/defaults | CP-11 |
| T18 Network/review/updater | Run normal installed app paths | No original feed/network behavior in V1 | CP-13 |

Mocks test coordinator invariants, not actual Mac paste success. Integration/UI tests must verify native clipboard, permission behavior and actual editor content separately. No implementation-mirroring tests that merely assert a constant was set.

## Manual installed-app checklist

1. Build and install the release app under its stable path, launch from Finder and verify menu identity. Confirm current OS/toolchain and installed architecture.
2. Copy 50 fictional entries at controlled intervals, including an earlier value retrieved after many later copies. Check exact payload fidelity and persisted state after relaunch.
3. Test search, pin/unpin, recency, deletion, clear unpinned, confirmed clear including pins and retention boundaries.
4. Without Accessibility permission: capture/search/copy still work. Enable direct paste through native settings; do not reset all apps' permissions. Verify installed bundle permissions.
5. Paste mid-document in TextEdit; use rich/plain versions and long Unicode text. Open/close panel/settings/preview and check focus does not cause paste into the wrong app.
6. Build Name/Email/Address queue; reorder, remove, activate and paste into three actual browser form fields. Check each pointer/order and normal Command-V behavior.
7. Press Paste Next rapidly/hold it; change app/field, copy an unrelated value, remove a source history row, Skip, Pause/Resume and Cancel before dispatch. Verify no unrequested pastes.
8. Test Notes, browser textarea/contenteditable and Cursor/VS Code where installed. Report direct supported / copy-only / unsupported with actual version and limitation. Secure fields are excluded.
9. Run offline and inspect updater/network actions; no API credentials should be requested. Run a 30-minute use/capture stress test and measure CPU/RSS.
10. Try a short display, multiple monitors, narrow/wide panel, dark mode, RTL, keyboard-only controls, VoiceOver and Reduce Motion.
11. Launch alongside an installed source app if available. Verify independent preferences/store/history. Avoid concurrent tests that read private real data; use synthetic copies.
12. Audit app bundle and repo for notices, product identity, original feed, content logs and testing-only fake data. User runtime starts with genuine captured history, not fixture rows.

## Performance and reporting

Measure the PRD targets with sample count, hardware, item count and cold/warm distinction. The 1,000-row search benchmark uses a seeded isolated test store even if default retention is lower. Include p50/p95 and failures rather than omit slow cases. A queue dispatch test must inspect destination content; an event-post count alone is insufficient.

For every CP-01 through CP-15 record implementation, automated result, actual manual evidence, Pass/Fail/Unverified and exact blocker. All app/editor/version claims come from execution. Test command examples must be replaced with validated commands for the implemented Xcode project.
