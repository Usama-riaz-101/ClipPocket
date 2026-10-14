# ClipPocket implementation plan

Execute the milestones continuously. They are internal checkpoints, not requests for the user to approve each stage. Start with a verified source build, then preserve functioning clipboard behavior while implementing ClipPocket's queue and identity.

| Milestone | Work | Exit evidence |
| --- | --- | --- |
| M0 Environment and baseline | Inspect Mac/Xcode/workspace; obtain exact commit; inspect locks/test scheme; baseline build | Actual tool versions, commit and baseline build result |
| M1 Identity and isolation | Display identity, bundle/test IDs, store/preferences, original icon, legal resources; updater/logging cleanup | Runs alongside source app without modifying its data; no original feed requests |
| M2 History correctness | Text capture policy, polling, dedup, search, pins, limits and persistence | Core tests and actual copy/relaunch checks |
| M3 Paste executor | Permission flow, copy-only, focus restore, plain paste, interference and serialization | Real TextEdit/editor paste; no stale target on panel/settings |
| M4 Ordered queue | Selection badges, review/reorder, snapshots, explicit Paste Next, Skip/Pause/Resume/Cancel | State-machine/race tests and real Name/Email/Address form |
| M5 UX and robustness | Native panel, long/RTL content, errors, migrations, clipboard interference and offline behavior | Compatibility table, visual checks, 30-minute run |
| M6 Release and delivery | Release `.app`, reproducible scripts, installed-app testing, report | All P0 traceability and actual artifact paths |

## Work order rules

Do not treat `multiSelectionEnabled = true` as the complete queue implementation. Inspect existing selection/order behavior and replace the global Command-V stack advancement with the new explicit queue contract. Avoid wholesale class renaming or rewriting functioning capture before baseline tests pass. UI polish follows actual capture/paste behavior; a diagram or mock screen is not a runtime substitute.

Keep an implementation change log for important defaults/migrations. Progress files list CP IDs as Not started / Implemented / Tested / Blocked. On context resumption, read those files and execute the next step without re-asking the project goal.

## Validation gates

M1: app identity, legal resources, updater and data isolation. M2: actual payload fidelity/persistence. M3: known real editor paste path. M4: deterministic ordering and interference/cancel cases. M5: real offline/editor performance. M6: installable bundle and truthful report. Failed gates trigger fixes; do not move failure into an undocumented limitation when it is P0.

## Dependency blockers

If Xcode is missing, implement/prep unaffected source and report the exact installation. Native OS permissions require a user action. No API key is needed. Linux cannot produce real Mac test evidence. A tool/session limit may require resumption, but must not be described as complete. Finish all independently possible work, and present only the concrete remaining blocker.

## Status vocabulary

Fully verified locally: all P0 cases pass on the stated Mac/editor versions and installed app. Implemented but verification blocked: completed implementation/build as possible with a named native permission/environment blocker. Incomplete: required implementation or failing behavior remains. The word working is reserved for actually exercised behavior.
