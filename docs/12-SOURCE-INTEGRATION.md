# ClipPocket source integration notes

This is an internal implementation document, not product marketing copy. It gives the coding agent the exact approved code input and adaptation tasks while keeping normal application copy focused on ClipPocket.

## Reproducible baseline

Source repository: https://github.com/p0deje/Maccy
Tag: 2.7.1
Commit: `eb03ebac3bbf24044c797c06f4304b74e3187835`
License file: https://github.com/p0deje/Maccy/blob/eb03ebac3bbf24044c797c06f4304b74e3187835/LICENSE

Verify the commit locally. A later moving branch is not the same baseline. If a concrete build/dependency defect requires another version, document the reason and actual commit rather than silently changing it. Preserve original notices in source and bundled legal resources; the MIT notice is not replaced by a new owner-only license header. Review dependency notices as well. Normal UI/marketing/public README does not need source-relationship labels.

## Inspected facts and adaptation

| File at pinned baseline | Observed fact | ClipPocket task |
| --- | --- | --- |
| `Maccy/Models/HistoryItem.swift` | SwiftData history with metadata and payload relationship | Preserve behavior; isolate store and add versioned fields as necessary |
| `Maccy/Models/HistoryItemContent.swift` | Type identifier and binary representation | Retain original payload fidelity for text scope |
| `Maccy/Storage.swift` | Source-named Application Support store; fatal error on failed open | Separate ClipPocket path and non-destructive recovery |
| `Maccy/Observables/AppState.swift` | Multi-selection disabled | Implement tested selection/review flow; no flag-only delivery |
| `Maccy/PasteStack.swift` | Global Command-V key-event advancement | Replace/disable for explicit Paste Next semantics |
| `Maccy/Observables/History.swift` | Queue methods and logs with history titles | Reuse only useful behavior; sanitize logs; enforce immutable queue contract |
| `Maccy/Info.plist` | Menu-only app and original update-feed URL | New displayed identity; no original update channel |
| `Maccy/AppDelegate.swift` | Capture startup, settings/menu routing and updater integration | Retain useful native path, isolate migrations and disable network updater |
| `Maccy.xcodeproj/project.pbxproj` | macOS 14, Swift 5 language mode, original IDs/team and packages | Legitimate local signing and separate product/test IDs; retain tested package locks initially |

These observations come from file inspection, not a Mac build. Existing storage/privacy/selection code is a starting point, not proof it meets this PRD. Inspect exact baseline source during implementation before changing APIs.

## Integration checklist

1. Source checkout and baseline build/test evidence before changes.
2. Separate bundle ID/store/preferences/testing domain before opening real user data.
3. Replace visible product identity and original app icon with ClipPocket's own. Keep internal names if renaming adds risk without product value.
4. Disable original update feed, store-review links, rating prompts and other product-specific external actions.
5. Audit copied-title logs, notifications and menu-bar recent-text exposure; use metadata/status defaults.
6. Default to text scope and prevent unused media/OCR/link-preview work in V1.
7. Implement explicit queue coordinator; remove double-advance paths from the original listener.
8. Validate original clipboard behavior, new queue requirements, offline runtime and local release installation.
9. Bundle original code/dependency legal notices and expose a separate local Legal Notices view.

No remote repository publishing, App Store submission or source-app affiliation claim is part of this task. The user-facing product is ClipPocket. Source provenance remains truthful in internal/legal records, without inserting relationship labels into normal product copy.
