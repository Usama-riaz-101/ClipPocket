# ClipPocket UI and UX design brief

## Direction

A calm native Mac utility with a compact searchable panel. The primary object is copied text; the primary action is reuse it. Keep screenshots and implementation free of dashboards, marketing slogans, onboarding carousels or decorative empty space. Display the name ClipPocket, a simple original clipboard icon and clear local state. Third-party legal notices belong in a separate accessible legal surface.

Preserve working native controls where they fit. Reference SVG/PDF screens show intended hierarchy, not pixel-perfect mandates or implemented code. Use native dynamic colors and macOS focus/selection conventions rather than hardcoded browser CSS.

## Layout

| Area | Specification |
| --- | --- |
| Panel | Preferred width 440 pt, usable range 360-560 pt; height initially 520 pt, capped to visible screen minus safe margins |
| Header | ClipPocket, Recording/Paused indicator, compact settings action |
| Search | Always visible; keyboard focus on open; clear query action |
| Scope controls | All / Pinned; Queue selection action with selected count |
| History | One vertical scroll region; pinned section first, recency list after it; two-line text previews |
| Row | Type/source icon if known, text preview, copy-time metadata, pin state; selection badge/checkbox in queue mode |
| Footer | Current Enter action, plain-text shortcut hint and optional queue status; stays visible |
| Preview | On-demand native detail surface; full text scrolls there, not a second nested region inside every row |
| Queue review | Numbered ordered rows, move up/down, remove, format choice, Activate Queue button |
| Active queue | Next preview, remaining count, Paste Next, Skip, Pause/Resume and Cancel; concise visible state |

No wide sidebar or persistent main window. Position near menu bar/cursor according to chosen setting and clamp inside the active display. If screen bounds shrink, reduce list height before clipping controls. Preserve search text and selection sensibly across preview open/close; Escape returns predictably.

## Type and styling

System font; content about 13-14 pt, secondary metadata 11-12 pt, title 15-16 pt. Use system spacing with 8/12/16 pt rhythm. Corners around 10-14 pt where native panel styling permits. Selected rows have a clear fill and visible focus ring; keyboard highlight is distinct from checked queue membership. Use one restrained blue accent; recording/paused states also have words/icons, not color alone. Light and dark mode both supported.

Code snippets may use a monospace preview. Keep exact content unchanged; display control whitespace only in an optional preview mode. Urdu/RTL text uses correct paragraph direction without reversing the surrounding controls. Long URLs wrap or truncate visually; paste still uses the complete original.

## States and exact intent

| State | Suggested copy | Action |
| --- | --- | --- |
| Empty history | Copy something to start your history. | Normal capture; no fake examples in runtime |
| No search matches | No matches for this search. | Clear search |
| Recording paused | History recording is paused. | Resume recording |
| Copy-only | Direct paste needs Accessibility permission. | Open permission instructions; Copy remains available |
| Queue review | Review the order before starting. | Activate Queue / Back |
| Queue Ready | Next: Name. 3 items remaining. | Paste Next / controls |
| Clipboard changed | Queue paused because you copied something new. | Resume / Cancel |
| Invalid target | Focus a supported text field to continue. | Resume after focus |
| Queue done | Queue complete. | Dismiss/new queue |
| Storage error | History could not be opened. Your data was not reset. | Retry / local recovery guidance |

Use a native confirmation only for destructive clear-all including pins. Clear unpinned is explicit and described; optional undo for deletion is useful but not required for initial P0. Never hide destructive behavior behind a vague icon with no label.

## Accessibility and validation

All controls have accessible names; queue order and remaining count are announced appropriately without reading every copy aloud. Full keyboard operation and VoiceOver navigation. Visible focus, sufficient contrast, Reduce Motion support and no required animation. Use comfortable native pointer targets; ensure 44 pt targets where practical in larger setup/review actions, without making every dense history row oversized.

Verify 360/440/560 pt widths, a short display, multiple monitors, dark mode, long snippets, 200% text/zoom where supported, RTL text, keyboard-only use and a blocked-permission state. Avoid double scrollbars and clipped footer actions. Preview data in design screens is fictional and must never ship as normal captured history.
