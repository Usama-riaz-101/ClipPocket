# ClipPocket troubleshooting

| Symptom | Inspect | Recovery / alternate |
| --- | --- | --- |
| No history appears | Recorder paused, enabled text types, changeCount timer and ignore policy | Resume; test a plain TextEdit copy; show diagnostics without content |
| Fast copies missing | Poll timing and latest-state replacement | Tune measured interval; document observed-rate boundary, no retroactive recovery claim |
| Duplicates on paste | Own marker/changeCount guard and payload signature | Fix self-write detection; regression test external copy during suppression |
| Same code loses indentation | Capture/dedup/plain-text transform | Keep original bytes; normalize previews only |
| Queue not selectable | Disabled baseline selection and active view routing | Implement real selection/review; feature flag alone is insufficient |
| Queue skips/double-pastes | Original Command-V listener, repeats, multiple monitors and in-flight tasks | Remove old advancement; serialize explicit commands; generation guard |
| Order unexpectedly changes | Queue uses live history indices | Immutable snapshots with explicit order |
| New external copy disrupts queue | Marker/changeCount transaction | Pause queue, preserve new copy and pending snapshots; explicit resume |
| Permission missing | Actual installed bundle Accessibility status | Copy-only fallback and specific native permission action |
| Paste goes to panel/wrong app | Previous target capture, activation/focus confirmation | Validate again after dismissal; block unsafe field; no blind delayed Command-V |
| Paste posted but not accepted | Editor behavior/secure input/shortcut interception | Test specific editor; explicit Retry last; copy-only fallback; no auto replay |
| Old source app data changed | Store URL, defaults domains, inherited migrations | Isolate before writes; restore controlled backups if available; test against fixtures |
| App contacts original release feed | Updater init, plist feed, review/website actions | Remove/disable source-specific remote actions and validate offline |
| History load crashes | Source fatalError path, schema/migration and directory | Non-destructive error UI; retry/diagnose; never delete store silently |
| History clear also clears system clipboard | Inherited clear clipboard preference | Separate explicit option; default preserves clipboard |
| Long entry truncated | Preview vs payload use and limits | Paste original snapshot; oversize skip visible; never truncated save |
| High idle CPU/RSS | Polling reads, image/OCR inherited tasks, full payload/index loading | Read payload only on changes; disable out-of-scope processing; bound caches |
| Logs contain copied text | Existing queue/copy/title logs and notifications | Replace with UUID/counters; do not export raw logs from private sessions |
| Build asks for original developer team | Inherited signing config | Local/ad hoc signing for the Mac path; update test IDs; avoid someone else's certificate |

Fix the smallest reproducible component and rerun affected checks. Report actual missing Xcode/permission/tool action precisely. No API-key blocker applies to V1. If event posting is inherently unverified in an app, state copy-only support rather than fake confirmation.
