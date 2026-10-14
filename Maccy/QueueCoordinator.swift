import Foundation

/// In-memory ordered paste queue. Snapshots are copied at review time and are not
/// tied to live history rows. This type never reads or writes the system clipboard.
final class QueueCoordinator {
  static let maxEntries = 50
  static let maxEntryBytes = 2 * 1024 * 1024
  static let maxSnapshotBytes = 50 * 1024 * 1024

  private(set) var session: QueueSession?
  private(set) var inFlight = false
  private(set) var inFlightTransaction: PasteTransaction?
  private(set) var lastDispatch: LastDispatch?
  private(set) var normalPasteCount = 0

  func beginReview(entries: [QueueEntrySnapshot], format: QueueFormatMode) -> QueueCommandResult {
    guard !entries.isEmpty else { return .rejected(.emptySelection) }
    guard entries.count <= Self.maxEntries else { return .rejected(.tooMany) }
    guard entries.allSatisfy({ $0.byteCount <= Self.maxEntryBytes && $0.byteCount >= 0 }) else {
      return .rejected(.oversizedEntry)
    }
    let total = entries.reduce(0) { $0 + $1.byteCount }
    guard total <= Self.maxSnapshotBytes else { return .rejected(.overBudget) }

    let copies = entries.map { $0.isolatedCopy() }
    session = QueueSession(
      id: UUID(),
      generation: 1,
      state: .reviewing,
      entries: copies,
      nextIndex: 0,
      formatMode: format,
      pauseReason: nil
    )
    inFlight = false
    inFlightTransaction = nil
    lastDispatch = nil
    return .ok
  }

  func move(from source: Int, to destination: Int) -> QueueCommandResult {
    guard var session, session.state == .reviewing, !inFlight else { return .rejected(.notReviewing) }
    guard session.entries.indices.contains(source), session.entries.indices.contains(destination) else {
      return .rejected(.notReviewing)
    }
    guard source != destination else { return .ok }
    let item = session.entries.remove(at: source)
    session.entries.insert(item, at: destination)
    self.session = session
    return .ok
  }

  func remove(id: UUID) -> QueueCommandResult {
    guard var session, session.state == .reviewing, !inFlight else { return .rejected(.notReviewing) }
    session.entries.removeAll { $0.id == id }
    if session.entries.isEmpty {
      session.state = .cancelled
      session.generation += 1
    }
    self.session = session
    return .ok
  }

  func setFormat(_ format: QueueFormatMode) -> QueueCommandResult {
    guard var session, session.state == .reviewing, !inFlight else { return .rejected(.notReviewing) }
    session.formatMode = format
    self.session = session
    return .ok
  }

  func activate() -> QueueCommandResult {
    guard var session, session.state == .reviewing, !session.entries.isEmpty, !inFlight else {
      return .rejected(.notReviewing)
    }
    session.state = .ready
    session.nextIndex = 0
    session.pauseReason = nil
    self.session = session
    return .ok
  }

  func beginDispatch() -> DispatchTicket? {
    guard var session, session.state == .ready, !inFlight else { return nil }
    guard session.entries.indices.contains(session.nextIndex) else { return nil }
    let entry = session.entries[session.nextIndex]
    session.state = .dispatching
    let transaction = PasteTransaction(
      id: UUID(),
      generation: session.generation,
      queueEntryID: entry.id,
      stage: "prepared"
    )
    inFlight = true
    inFlightTransaction = transaction
    self.session = session
    return DispatchTicket(
      generation: session.generation,
      transactionID: transaction.id,
      entry: entry.isolatedCopy(),
      format: session.formatMode,
      index: session.nextIndex
    )
  }

  func finishDispatch(generation: Int, transactionID: UUID, result: DispatchFinish) {
    guard var session else { return }
    guard session.generation == generation else { return }
    guard inFlightTransaction?.id == transactionID else { return }
    inFlight = false
    inFlightTransaction = nil

    switch result {
    case .dispatched:
      let finished = session.entries[session.nextIndex]
      lastDispatch = LastDispatch(entry: finished.isolatedCopy(), result: .dispatched, index: session.nextIndex)
      session.nextIndex += 1
      if session.nextIndex >= session.entries.count {
        session.state = .completed
        session.pauseReason = nil
        session.entries = session.entries.map { $0.clearedPayload() }
      } else {
        session.state = .ready
        session.pauseReason = nil
      }
    case .rejected(let reason):
      session.state = .paused
      session.pauseReason = reason
    case .uncertain:
      if session.entries.indices.contains(session.nextIndex) {
        lastDispatch = LastDispatch(
          entry: session.entries[session.nextIndex].isolatedCopy(),
          result: .uncertain,
          index: session.nextIndex
        )
      }
      session.state = .paused
      session.pauseReason = .uncertainDispatch
    case .aborted:
      session.state = .paused
      session.pauseReason = .clipboardChanged
    }
    self.session = session
  }

  func prepareRetry() -> DispatchTicket? {
    guard var session, session.state == .paused, session.pauseReason == .uncertainDispatch, !inFlight else {
      return nil
    }
    guard session.entries.indices.contains(session.nextIndex) else { return nil }
    let entry = session.entries[session.nextIndex]
    session.state = .dispatching
    let transaction = PasteTransaction(
      id: UUID(),
      generation: session.generation,
      queueEntryID: entry.id,
      stage: "prepared"
    )
    inFlight = true
    inFlightTransaction = transaction
    self.session = session
    return DispatchTicket(
      generation: session.generation,
      transactionID: transaction.id,
      entry: entry.isolatedCopy(),
      format: session.formatMode,
      index: session.nextIndex
    )
  }

  func skip() -> QueueCommandResult {
    guard var session, session.state == .ready, !inFlight else { return .rejected(.notReady) }
    guard session.entries.indices.contains(session.nextIndex) else { return .rejected(.noItem) }
    session.nextIndex += 1
    if session.nextIndex >= session.entries.count {
      session.state = .completed
      session.entries = session.entries.map { $0.clearedPayload() }
    }
    self.session = session
    return .ok
  }

  func pause(reason: PauseReason) -> QueueCommandResult {
    guard var session, !inFlight else { return .rejected(.inFlight) }
    switch session.state {
    case .ready, .reviewing:
      session.state = .paused
      session.pauseReason = reason
      self.session = session
      return .ok
    case .paused:
      return .ok
    default:
      return .rejected(.notReady)
    }
  }

  func noteExternalCopy() {
    guard var session else { return }
    switch session.state {
    case .ready, .dispatching:
      session.state = .paused
      session.pauseReason = .clipboardChanged
      if session.state == .paused {
        inFlight = false
        inFlightTransaction = nil
      }
      self.session = session
    default:
      break
    }
  }

  func resume() -> QueueCommandResult {
    guard var session, session.state == .paused, !inFlight else { return .rejected(.notReady) }
    session.state = .ready
    session.pauseReason = nil
    self.session = session
    return .ok
  }

  func cancel() {
    guard var session else { return }
    session.generation += 1
    session.state = .cancelled
    session.entries = []
    session.pauseReason = nil
    inFlight = false
    inFlightTransaction = nil
    lastDispatch = nil
    self.session = session
  }

  func dismissFinished() {
    guard let session else { return }
    if session.state == .completed || session.state == .cancelled {
      self.session = nil
      lastDispatch = nil
    }
  }

  func noteNormalPaste() {
    normalPasteCount += 1
  }

  var nextPreview: String? {
    guard let session, session.entries.indices.contains(session.nextIndex) else { return nil }
    return session.entries[session.nextIndex].preview
  }

  var remainingCount: Int {
    guard let session else { return 0 }
    return max(0, session.entries.count - session.nextIndex)
  }
}

enum QueueState: String, Equatable {
  case reviewing
  case ready
  case dispatching
  case paused
  case completed
  case cancelled
}

enum QueueFormatMode: String, Equatable {
  case original
  case plainText
}

enum PauseReason: String, Equatable {
  case user
  case clipboardChanged
  case invalidTarget
  case permissionMissing
  case uncertainDispatch
  case sleep
}

enum QueueCommandResult: Equatable {
  case ok
  case rejected(QueueRejection)
}

enum QueueRejection: String, Equatable {
  case emptySelection
  case tooMany
  case oversizedEntry
  case overBudget
  case notReviewing
  case notReady
  case inFlight
  case noItem
}

enum DispatchFinish: Equatable {
  case dispatched
  case rejected(PauseReason)
  case uncertain
  case aborted
}

struct QueueRepresentation: Equatable {
  var typeIdentifier: String
  var bytes: Data
}

struct QueueEntrySnapshot: Equatable, Identifiable {
  var id: UUID
  var sourceEntryID: UUID
  var preview: String
  var plainText: String
  var representations: [QueueRepresentation]
  var byteCount: Int

  func isolatedCopy() -> QueueEntrySnapshot {
    QueueEntrySnapshot(
      id: id,
      sourceEntryID: sourceEntryID,
      preview: preview,
      plainText: plainText,
      representations: representations.map { QueueRepresentation(typeIdentifier: $0.typeIdentifier, bytes: Data($0.bytes)) },
      byteCount: byteCount
    )
  }

  func clearedPayload() -> QueueEntrySnapshot {
    var copy = self
    copy.plainText = ""
    copy.representations = []
    copy.byteCount = 0
    return copy
  }
}

struct QueueSession: Equatable {
  var id: UUID
  var generation: Int
  var state: QueueState
  var entries: [QueueEntrySnapshot]
  var nextIndex: Int
  var formatMode: QueueFormatMode
  var pauseReason: PauseReason?
}

struct PasteTransaction: Equatable {
  var id: UUID
  var generation: Int
  var queueEntryID: UUID
  var stage: String
}

struct DispatchTicket: Equatable {
  var generation: Int
  var transactionID: UUID
  var entry: QueueEntrySnapshot
  var format: QueueFormatMode
  var index: Int
}

struct LastDispatch: Equatable {
  var entry: QueueEntrySnapshot
  var result: String
  var index: Int

  init(entry: QueueEntrySnapshot, result: DispatchFinish, index: Int) {
    self.entry = entry
    switch result {
    case .dispatched:
      self.result = "dispatched"
    case .uncertain:
      self.result = "uncertain"
    case .rejected:
      self.result = "rejected"
    case .aborted:
      self.result = "aborted"
    }
    self.index = index
  }
}
