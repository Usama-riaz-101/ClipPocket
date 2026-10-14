# ClipPocket agent instructions

## Objective

Build the working native utility in `docs/01-PRD.md`. User instructions and PRD behavior outrank implementation suggestions. Read the complete handoff before coding. The app is ClipPocket. V1 has no server, API account, AI runtime or background upload.

## Autonomous work

Continue through source inspection, implementation, tests, packaging and local delivery. Milestones are internal; do not ask whether to continue. Resolve ordinary choices from these defaults. Ask only for an actual native permission/tool blocker or an unavoidable experience-changing decision. Continue independent work while blocked.

Maintain `PROGRESS.md` with milestone and requirement statuses, `NEXT-ACTION.md` with the next concrete step, and `DELIVERY-REPORT.md` with actual evidence. Read them after context compaction/resumption. Session limits are not completion. Preserve existing user modifications and do not overwrite an unrelated project.

## Source and identity

Acquire and verify the exact source baseline described in `12-SOURCE-INTEGRATION.md`. Preserve required third-party legal notices and dependencies' licenses. Normal UI, marketing and public README use ClipPocket's own identity and feature descriptions. Required legal/provenance records are not removed. No remote publishing is part of this task.

## Engineering invariants

- History is persistent and app-local; queue snapshots are temporary in-memory data.
- Normal Command-V remains untouched. Only explicit Paste Next consumes a queue entry.
- Dispatch is serialized and guarded by generation, target and clipboard checks. Ignore key repeat, synthetic self-events and stale completions.
- New external copies pause a ready queue rather than changing its pending items.
- Meaningful whitespace and Unicode survive; plain-text mode strips formatting only.
- Secure/transient markers and excluded-app settings continue to suppress capture. Do not log copied content.
- Source updater/review/rating/website actions cannot silently contact or represent another product.
- UI is compact, keyboard-first and accessible, with one history scroll region and visible status.

## Definition of done

Implement all CP-01 through CP-15, pass meaningful tests, produce a release app, test actual installed-app clipboard/editor behavior and complete the delivery report. A feature flag, UI mockup or compiler pass alone is insufficient. Report unrun tests as Unverified. No hardcoded transcripts, fake history, invented measurements or silent data reset in the delivered normal runtime.
