# ClipPocket delivery report template

Copy to the implemented project's `DELIVERY-REPORT.md` and fill from execution. An unfilled template is not completion evidence.

## Status and use

Fully verified locally / Implemented but verification blocked / Incomplete. Give actual `.app` path, install/run commands, picker and Paste Next shortcuts and the shortest permission/setup actions.

## Environment and build

Mac chip, macOS, Xcode/Swift versions, actual source commit, target architecture, product IDs/store path and changed dependencies. Record real build/test command outputs and failures. Baseline provenance belongs here as internal engineering evidence, not UI/marketing copy.

## Requirement evidence

| CP ID | Implemented behavior | Automated evidence | Installed-app evidence | Pass/Fail/Unverified and blocker |
| --- | --- | --- | --- | --- |
| CP-01 through CP-15 | Fill every ID separately | Actual test reference | Actual observed case | Exact result |

## Editor compatibility

| App/version and field | Direct paste | Plain paste | Ordered queue | Limits |
| --- | --- | --- | --- | --- |
| TextEdit | Fill | Fill | Fill | Fill |
| Browser form/textarea | Actual browser | Fill | Fill | Fill |
| Notes | Fill | Fill | Fill | Fill |
| Cursor/VS Code if tested | Fill | Fill | Fill | Fill |

## Metrics

Capture test count/cadence; p50/p95 panel open/search; queue attempts and order/double-advance failures; relaunch fidelity; offline/network checks; idle/sustained CPU/RSS. Include hardware and store size. Write Unmeasured where appropriate; never copy PRD targets into measured columns.

## Isolation and data lifecycle

Separate store/defaults, pin/retention behavior, migration/load failure handling, recording exclusions, original updater disabled, sensitive logs removed and bundled notices present. Describe actual tests, not intentions.

## Remaining actions

Exact external permission/environment blocker, affected CP IDs, completed independent work and validation action after resolution. Do not ask the user to repeat the implementation request. Known supported-app limits are stated plainly. No claim of fully working delivery when a P0 behavior remains unimplemented or unverified.
