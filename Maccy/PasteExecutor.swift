import AppKit
import ApplicationServices

enum PasteTargetVerdict: Equatable {
  case ready(pid: pid_t, bundleID: String?)
  case permissionDenied
  case secure
  case notEditable
  case missing
  case ownApplication
}

struct PasteDispatchReport: Equatable {
  enum Outcome: String {
    case dispatched
    case rejected
    case uncertain
    case copiedOnly
    case aborted
  }

  var outcome: Outcome
  var reason: String
}

@MainActor
final class PasteExecutor {
  static let shared = PasteExecutor()

  private(set) var panelTargetPID: pid_t?
  private(set) var panelTargetBundleID: String?
  private var lastExternalPID: pid_t?
  private var lastExternalBundleID: String?
  private var dispatching = false

  func startTrackingFrontmostApp() {
    if let app = NSWorkspace.shared.frontmostApplication {
      noteActivated(app)
    }
    NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { notification in
      guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
        return
      }
      Task { @MainActor in
        PasteExecutor.shared.noteActivated(app)
      }
    }
  }

  func noteActivated(_ app: NSRunningApplication) {
    guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
    lastExternalPID = app.processIdentifier
    lastExternalBundleID = app.bundleIdentifier
  }

  func notePanelWillOpen() {
    if let app = NSWorkspace.shared.frontmostApplication {
      noteActivated(app)
    }
    panelTargetPID = lastExternalPID
    panelTargetBundleID = lastExternalBundleID
  }

  nonisolated static var isTrusted: Bool {
    AXIsProcessTrusted()
  }

  static func promptForAccessibility() {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [promptKey: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  func verdict(pid: pid_t?) -> PasteTargetVerdict {
    guard Self.isTrusted else { return .permissionDenied }
    guard let pid, pid > 0 else { return .missing }
    if let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
       bundle == Bundle.main.bundleIdentifier {
      return .ownApplication
    }
    let element = AXUIElementCreateApplication(pid)
    var focused: CFTypeRef?
    let copyResult = AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focused)
    guard copyResult == .success, let focused else { return .missing }
    let focusedElement = focused as! AXUIElement

    var roleValue: CFTypeRef?
    AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
    let role = roleValue as? String ?? ""

    var subroleValue: CFTypeRef?
    AXUIElementCopyAttributeValue(focusedElement, kAXSubroleAttribute as CFString, &subroleValue)
    let subrole = subroleValue as? String ?? ""

    if role == "AXSecureTextField" || subrole == "AXSecureTextField" {
      return .secure
    }

    let editableRoles: Set<String> = [
      kAXTextFieldRole as String,
      kAXTextAreaRole as String,
      kAXComboBoxRole as String,
      "AXSearchField",
      "AXWebArea"
    ]
    guard editableRoles.contains(role) || role == "AXTextArea" else {
      if role.isEmpty { return .missing }
      return .notEditable
    }

    var settable: DarwinBoolean = false
    let attribute: CFString = (role == "AXWebArea" ? kAXValueAttribute : kAXValueAttribute) as CFString
    let settableResult = AXUIElementIsAttributeSettable(focusedElement, attribute, &settable)
    if settableResult == .success && !settable.boolValue && role != "AXWebArea" {
      return .notEditable
    }

    let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    return .ready(pid: pid, bundleID: bundle)
  }

  func currentFrontmostVerdict() -> PasteTargetVerdict {
    verdict(pid: NSWorkspace.shared.frontmostApplication?.processIdentifier)
  }

  func dispatchQueueItem(
    _ ticket: DispatchTicket,
    coordinator: QueueCoordinator
  ) async -> PasteDispatchReport {
    guard !dispatching else {
      return PasteDispatchReport(outcome: .rejected, reason: "inFlight")
    }
    dispatching = true
    defer { dispatching = false }

    guard coordinator.session?.generation == ticket.generation else {
      coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .aborted)
      return PasteDispatchReport(outcome: .aborted, reason: "staleGeneration")
    }

    AppState.shared.popup.close()
    try? await Task.sleep(for: .milliseconds(40))

    guard coordinator.session?.generation == ticket.generation, coordinator.inFlight else {
      return PasteDispatchReport(outcome: .aborted, reason: "cancelled")
    }

    let front = NSWorkspace.shared.frontmostApplication
    if front?.bundleIdentifier == Bundle.main.bundleIdentifier {
      coordinator.finishDispatch(
        generation: ticket.generation,
        transactionID: ticket.transactionID,
        result: .rejected(.invalidTarget)
      )
      return PasteDispatchReport(outcome: .rejected, reason: "ownApplication")
    }

    switch currentFrontmostVerdict() {
    case .permissionDenied:
      coordinator.finishDispatch(
        generation: ticket.generation,
        transactionID: ticket.transactionID,
        result: .rejected(.permissionMissing)
      )
      return PasteDispatchReport(outcome: .copiedOnly, reason: "permission")
    case .secure:
      coordinator.finishDispatch(
        generation: ticket.generation,
        transactionID: ticket.transactionID,
        result: .rejected(.invalidTarget)
      )
      return PasteDispatchReport(outcome: .rejected, reason: "secure")
    case .notEditable, .missing, .ownApplication:
      coordinator.finishDispatch(
        generation: ticket.generation,
        transactionID: ticket.transactionID,
        result: .rejected(.invalidTarget)
      )
      return PasteDispatchReport(outcome: .rejected, reason: "invalidTarget")
    case .ready:
      break
    }

    let observed = NSPasteboard.general.changeCount
    guard Clipboard.shared.prepareOwnWrite(expectedChangeCount: observed) else {
      coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .aborted)
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }

    let plain = ticket.format == .plainText
    guard Clipboard.shared.writeSnapshot(ticket.entry, plainTextOnly: plain) else {
      coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .aborted)
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }

    guard coordinator.session?.generation == ticket.generation else {
      return PasteDispatchReport(outcome: .aborted, reason: "cancelledAfterWrite")
    }
    guard Clipboard.shared.confirmOwnWriteStable() else {
      coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .aborted)
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }

    let posted = Clipboard.shared.postPasteKeystroke()
    if posted == .failed {
      coordinator.finishDispatch(
        generation: ticket.generation,
        transactionID: ticket.transactionID,
        result: .rejected(.invalidTarget)
      )
      return PasteDispatchReport(outcome: .rejected, reason: "eventCreateFailed")
    }
    if posted == .uncertain {
      coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .uncertain)
      return PasteDispatchReport(outcome: .uncertain, reason: "eventPostUncertain")
    }

    coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .dispatched)
    return PasteDispatchReport(outcome: .dispatched, reason: "posted")
  }

  func dispatchHistoryItem(_ item: HistoryItem, plainText: Bool) async -> PasteDispatchReport {
    guard !dispatching else {
      return PasteDispatchReport(outcome: .rejected, reason: "inFlight")
    }
    dispatching = true
    defer { dispatching = false }

    let snapshot = QueueEntrySnapshot(
      id: UUID(),
      sourceEntryID: item.entryID,
      preview: String(item.previewableText.prefix(80)),
      plainText: item.text ?? item.previewableText,
      representations: item.contents.compactMap { content in
        guard let value = content.value else { return nil }
        return QueueRepresentation(typeIdentifier: content.type, bytes: value)
      },
      byteCount: item.accountedBytes
    )

    AppState.shared.popup.close()
    let restored = await restorePreviousApp()

    guard PasteExecutor.isTrusted else {
      Clipboard.shared.copy(item, removeFormatting: plainText)
      return PasteDispatchReport(outcome: .copiedOnly, reason: "permission")
    }

    if !restored || NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Bundle.main.bundleIdentifier {
      Clipboard.shared.copy(item, removeFormatting: plainText)
      AppState.shared.statusMessage = "Could not return to the previous app. The item is copied."
      return PasteDispatchReport(outcome: .copiedOnly, reason: "ownApplication")
    }

    if case .secure = verdict(pid: NSWorkspace.shared.frontmostApplication?.processIdentifier) {
      AppState.shared.statusMessage = "That field is hidden, so it was not pasted."
      return PasteDispatchReport(outcome: .rejected, reason: "secure")
    }

    try? await Task.sleep(for: .milliseconds(120))

    let observed = NSPasteboard.general.changeCount
    guard Clipboard.shared.prepareOwnWrite(expectedChangeCount: observed) else {
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }
    guard Clipboard.shared.writeSnapshot(snapshot, plainTextOnly: plainText) else {
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }
    guard Clipboard.shared.confirmOwnWriteStable() else {
      return PasteDispatchReport(outcome: .aborted, reason: "clipboardChanged")
    }
    let posted = Clipboard.shared.postPasteKeystroke()
    switch posted {
    case .posted:
      return PasteDispatchReport(outcome: .dispatched, reason: "posted")
    case .uncertain:
      return PasteDispatchReport(outcome: .uncertain, reason: "eventPostUncertain")
    case .failed:
      return PasteDispatchReport(outcome: .rejected, reason: "eventCreateFailed")
    }
  }

  @discardableResult
  private func restorePreviousApp() async -> Bool {
    guard let pid = panelTargetPID ?? lastExternalPID else { return false }
    let app = NSRunningApplication(processIdentifier: pid)
    app?.activate(options: [.activateIgnoringOtherApps])
    if await waitUntilFrontmost(pid, timeout: 0.8) {
      return true
    }
    app?.activate(options: [.activateIgnoringOtherApps])
    return await waitUntilFrontmost(pid, timeout: 0.5)
  }

  private func waitUntilFrontmost(_ pid: pid_t, timeout: TimeInterval) async -> Bool {
    let start = Date()
    while Date().timeIntervalSince(start) < timeout {
      if NSWorkspace.shared.frontmostApplication?.processIdentifier == pid {
        return true
      }
      try? await Task.sleep(for: .milliseconds(20))
    }
    return NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
  }
}
