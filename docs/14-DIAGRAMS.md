# ClipPocket diagrams and design references

Proposed behavior and UI, not screenshots of an implemented application. Mermaid diagrams remain editable; SVG/PDF versions are bundled for direct viewing.

## 1 Copy retrieve and reuse

Normal retrieval and ordered paste share local history, with explicit user actions.

```mermaid
flowchart TD
    C["Copy eligible text"] --> H["Local persistent history"]
    H --> P["Open picker and search"]
    P --> S["Select one entry"]
    S --> T{"Direct paste ready?"}
    T -->|Yes| V["Verify target and dispatch"]
    T -->|No| O["Copy only and manual paste"]
    P --> Q["Select items and review order"]
    Q --> R["Activate queue without pasting"]
    R --> N["Explicit Paste Next"]
    N --> V
```

![Copy retrieve and reuse](visuals/01-app-flow.svg)

The user chooses each destination field. ClipPocket does not navigate or fill a form automatically.

A new external copy pauses the active queue while eligible history recording continues.

## 2 Local application architecture

Every V1 component runs on the Mac. There is no server or AI service.

```mermaid
flowchart TD
    C["System clipboard"] --> M["Monitor and capture policy"]
    M --> H["SwiftData history repository"]
    H --> U["Picker and search"]
    U --> Q["Queue coordinator"]
    U --> P["Paste executor"]
    Q --> P
    F["Focus and permission gate"] --> P
    P --> E["Destination editor"]
    P --> C
```

![Local application architecture](visuals/02-architecture.svg)

Normal Command-V is not intercepted to consume queue entries. Queue commands are explicit.

Future transformations have a separate seam; V1 never uploads or changes original history text.

## 3 Queue lifecycle and cancellation

Only explicit queue commands can move the pointer or dispatch an item.

```mermaid
stateDiagram-v2
    [*] --> Reviewing
    Reviewing --> Ready: Activate
    Ready --> Dispatching: Paste Next
    Dispatching --> Ready: Dispatched and more entries
    Dispatching --> Completed: Dispatched last entry
    Dispatching --> Paused: Target or clipboard invalid
    Ready --> Paused: Pause or external copy
    Paused --> Ready: Explicit Resume
    Ready --> Ready: Skip with more entries
    Ready --> Completed: Skip last entry
    Reviewing --> Cancelled: Cancel
    Ready --> Cancelled: Cancel
    Paused --> Cancelled: Cancel
    Dispatching --> Cancelled: Cancel generation
    Completed --> [*]
    Cancelled --> [*]
```

![Queue lifecycle and cancellation](visuals/03-queue-states.svg)

Skip advances without dispatch. Normal Command-V does not advance. The queue is cleared on restart.

Cancel stops unsubmitted events; it cannot undo a paste already posted to another application.

## 4 Persistent history and temporary queue

Local persistence is separate from in-memory queue snapshots and paste transactions.

```mermaid
erDiagram
    HistoryEntry ||--|{ PayloadRepresentation : contains
    QueueSession ||--|{ QueueEntrySnapshot : orders
    QueueEntrySnapshot ||--o{ PasteTransaction : dispatches
    HistoryEntry {
        UUID id
        String dedupKey
        Date lastCopiedAt
        Bool isPinned
    }
    PayloadRepresentation {
        String typeIdentifier
        Data bytes
    }
    QueueSession {
        UUID id
        Int generation
        Int nextIndex
    }
    QueueEntrySnapshot {
        UUID id
        Data immutablePayload
    }
    PasteTransaction {
        UUID id
        String result
    }
```

![Persistent history and temporary queue](visuals/04-data-model.svg)

History eviction cannot alter an active queue snapshot. Queue contents are never restored as an armed session.

The diagram is a logical schema; SwiftData manages physical tables and versioned migrations.

## 5 Clipboard picker design reference

![Picker reference](visuals/05-picker-design.svg)

Reference only. Use native controls, dynamic colors and the detailed UI brief.

## 6 Queue review and active controls

![Queue reference](visuals/06-queue-design.svg)

Two separate runtime states shown side by side for comparison. Native app uses the appropriate state, not two permanent windows.
