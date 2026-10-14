import AppKit
import KeyboardShortcuts

@MainActor
enum QueueActions {
  private static var lastPasteNext = Date.distantPast

  static func buildReview(from items: [HistoryItemDecorator]) {
    let snapshots: [QueueEntrySnapshot] = items.compactMap { decorator in
      let item = decorator.item
      let representations = item.contents.compactMap { content -> QueueRepresentation? in
        guard let value = content.value else { return nil }
        if HistoryItem.transientTypes.contains(content.type) { return nil }
        return QueueRepresentation(typeIdentifier: content.type, bytes: value)
      }
      let bytes = representations.reduce(0) { $0 + $1.bytes.count }
      let plain = item.text ?? item.previewableText
      guard bytes <= QueueCoordinator.maxEntryBytes else {
        AppState.shared.statusMessage = "Skipped an item larger than 2 MB."
        return nil
      }
      let previewSource = plain.replacingOccurrences(of: "\n", with: " ")
      return QueueEntrySnapshot(
        id: UUID(),
        sourceEntryID: item.entryID,
        preview: String(previewSource.prefix(80)),
        plainText: IdentityTextTransform().transform(plain),
        representations: representations,
        byteCount: bytes
      )
    }
    switch AppState.shared.queue.beginReview(entries: snapshots, format: .original) {
    case .ok:
      AppState.shared.queueSelectionMode = false
      AppState.shared.statusMessage = "Review the order before starting."
    case .rejected(let reason):
      AppState.shared.statusMessage = message(for: reason)
    }
  }

  static func activate() {
    switch AppState.shared.queue.activate() {
    case .ok:
      AppState.shared.popup.close()
      AppState.shared.statusMessage = statusLine()
    case .rejected:
      AppState.shared.statusMessage = "Review the order before starting."
    }
  }

  static func pasteNext() async {
    let now = Date()
    guard now.timeIntervalSince(lastPasteNext) > 0.2 else { return }
    lastPasteNext = now
    guard let ticket = AppState.shared.queue.beginDispatch() else { return }
    let report = await PasteExecutor.shared.dispatchQueueItem(ticket, coordinator: AppState.shared.queue)
    AppState.shared.statusMessage = message(for: report)
  }

  static func retryLast() async {
    guard let ticket = AppState.shared.queue.prepareRetry() else { return }
    let report = await PasteExecutor.shared.dispatchQueueItem(ticket, coordinator: AppState.shared.queue)
    AppState.shared.statusMessage = message(for: report)
  }

  static func skip() {
    _ = AppState.shared.queue.skip()
    AppState.shared.statusMessage = statusLine()
  }

  static func pause() {
    _ = AppState.shared.queue.pause(reason: .user)
    AppState.shared.statusMessage = "Queue paused."
  }

  static func resume() {
    guard AppState.shared.queue.session?.state == .paused else { return }
    _ = AppState.shared.queue.resume()
    AppState.shared.statusMessage = statusLine()
  }

  static func cancel() {
    AppState.shared.queue.cancel()
    AppState.shared.statusMessage = "Queue canceled."
  }

  static func backToHistory() {
    AppState.shared.queue.cancel()
    AppState.shared.queue.dismissFinished()
    AppState.shared.queueSelectionMode = true
  }

  static func registerShortcut() {
    KeyboardShortcuts.onKeyUp(for: .pasteNext) {
      let shortcut = KeyboardShortcuts.Shortcut(name: .pasteNext)
      if shortcut?.modifiers == .command && shortcut?.key == .v {
        Task { @MainActor in
          AppState.shared.statusMessage = "Paste Next cannot use Command-V. Choose another shortcut."
        }
        return
      }
      Task { @MainActor in
        await pasteNext()
      }
    }
  }

  static func statusLine() -> String {
    let queue = AppState.shared.queue
    guard let session = queue.session else { return "" }
    switch session.state {
    case .ready:
      let next = queue.nextPreview ?? ""
      return "Next: \(next). \(queue.remainingCount) items remaining."
    case .paused:
      switch session.pauseReason {
      case .clipboardChanged:
        return "Queue paused because you copied something new."
      case .invalidTarget:
        return "Focus a supported text field to continue."
      case .permissionMissing:
        return "Direct paste needs Accessibility permission."
      case .uncertainDispatch:
        return "Paste may not have landed. Check the field, then Retry last or continue."
      case .sleep:
        return "Queue paused while the Mac slept."
      case .user, .none:
        return "Queue paused."
      }
    case .completed:
      return "Queue complete."
    case .reviewing:
      return "Review the order before starting."
    case .dispatching:
      return "Pasting…"
    case .cancelled:
      return "Queue canceled."
    }
  }

  private static func message(for reason: QueueRejection) -> String {
    switch reason {
    case .emptySelection: return "Select at least one item."
    case .tooMany: return "A queue can hold up to 50 items."
    case .oversizedEntry: return "An item is larger than 2 MB and was not added."
    case .overBudget: return "The queue is larger than the storage budget."
    case .notReviewing, .notReady, .inFlight, .noItem: return statusLine()
    }
  }

  private static func message(for report: PasteDispatchReport) -> String {
    switch report.outcome {
    case .dispatched, .copiedOnly, .rejected, .uncertain, .aborted:
      return statusLine()
    }
  }
}
