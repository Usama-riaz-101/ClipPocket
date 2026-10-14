# ClipPocket app flow

## First launch

Launch installed app → initialize ClipPocket's own store/preferences → show menu bar icon → start eligible local capture → show compact welcome/setup once. Explain history stays on this Mac. Accessibility is requested only when enabling direct paste. If denied, keep capture/search/copy usable and show copy-only status. Shortcut conflicts produce a reassignment action, not a silent failure.

## Copy and retrieve

Copy text in any source app → eligible clipboard change → exact bounded snapshot → save/update history → menu status remains quiet. Open picker → search focused → choose entry with arrows/mouse → Enter/direct Paste or explicit Copy → panel closes → target revalidated → native paste dispatched or copy-only instructions shown. Escape closes without changing the clipboard. Clicking an item selects/previews; it does not unexpectedly paste on mere hover.

## Build and use a queue

1. Open History and enter Queue selection mode.
2. Select items; badges show selection order 1, 2, 3. Selection is distinct from keyboard highlight.
3. Build Queue opens Review with the ordered list. Reorder or remove, choose original/plain text, then Activate Queue.
4. Activation sets Ready and closes the panel. It does not paste or write the first entry to the system clipboard.
5. Focus a destination field and use Paste Next. Verify target, snapshot and generation, then dispatch one entry.
6. Move to the next field and repeat. Status shows remaining count and a short next preview when opening the menu/panel.
7. Finish transitions to Completed and clears payload snapshots after the brief completion feedback. Clear status on dismissal/new queue.

Paste Next never chooses a field automatically. Tab/mouse navigation stays under the user's control. Normal Command-V pastes current clipboard content without consuming the queue. No auto-field classification or form-filling agent in V1.

## Exceptions

| Event | State/action | User recovery |
| --- | --- | --- |
| Copy new external text while Ready | Save eligible new history; pause queue | Explicit Resume after selecting destination |
| Permission absent | Copy-only status; no queue dispatch/advance | Grant Accessibility or use explicit Copy |
| Target invalid/secure | Pause queue, leave pointer unchanged | Focus a supported field and Resume |
| Dispatch uncertain | Pause; retain last transaction metadata | Check field; explicitly Retry last or Continue next |
| Press Cancel before dispatch | Invalidate generation; clear snapshots | Start another queue if wanted |
| Cancel after submitted event | Stop future dispatch; prior event may already paste | No automatic reversal of user content |
| Sleep/session lock | Pause and revoke pending target | Resume after unlock |
| App quits/restarts | Clear queue; history persists | Build another queue |
| Storage load fails | Error with non-destructive recovery | Retry/open diagnostics; no silent empty reset |

## State separation

History capture state: Recording, Paused, Storage error. Panel state: Closed, History, Search results, Empty, Queue review, Settings. Queue state: Empty, Reviewing, Ready, Dispatching, Paused, Completed, Cancelled. Permission state: Direct paste available or Copy-only. Display these independently: a paused recorder is not necessarily a canceled queue.

## Critical keyboard behavior

Picker shortcut toggles panel. Escape returns/close; arrows navigate; Enter performs the visibly indicated action; a documented modifier invokes plain-text paste; Space toggles a checkbox only in Queue selection mode. Shortcut help in footer reflects settings, not hardcoded values. Queue review is fully usable without dragging. Settings/Legal Notices never receive a pending paste.

Diagrams and reference screens: `14-DIAGRAMS.md` and `ClipPocket-Blueprint.pdf`.
