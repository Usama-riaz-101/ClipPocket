import XCTest
@testable import Maccy

final class QueueCoordinatorTests: XCTestCase {
  private func snap(_ text: String, source: UUID = UUID()) -> QueueEntrySnapshot {
    let data = Data(text.utf8)
    return QueueEntrySnapshot(
      id: UUID(),
      sourceEntryID: source,
      preview: text,
      plainText: text,
      representations: [QueueRepresentation(typeIdentifier: "public.utf8-plain-text", bytes: data)],
      byteCount: data.count
    )
  }

  func testSelectionOrderIsIndependentOfLaterMutation() {
    let coordinator = QueueCoordinator()
    let name = snap("Name")
    let email = snap("Email")
    let address = snap("Address")
    XCTAssertEqual(coordinator.beginReview(entries: [name, email, address], format: .original), .ok)
    var source = Data("Name".utf8)
    _ = source
    XCTAssertEqual(coordinator.session?.entries.map(\.plainText), ["Name", "Email", "Address"])
    XCTAssertEqual(coordinator.move(from: 2, to: 0), .ok)
    XCTAssertEqual(coordinator.session?.entries.map(\.plainText), ["Address", "Name", "Email"])
    XCTAssertEqual(coordinator.activate(), .ok)
    XCTAssertEqual(coordinator.session?.state, .ready)
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
  }

  func testSnapshotSurvivesSourceBufferChange() {
    var bytes = Data("Name".utf8)
    let entry = QueueEntrySnapshot(
      id: UUID(),
      sourceEntryID: UUID(),
      preview: "Name",
      plainText: "Name",
      representations: [QueueRepresentation(typeIdentifier: "public.utf8-plain-text", bytes: bytes)],
      byteCount: bytes.count
    )
    bytes.removeAll()
    XCTAssertEqual(entry.representations[0].bytes, Data("Name".utf8))
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [entry], format: .plainText), .ok)
    XCTAssertEqual(coordinator.session?.entries[0].plainText, "Name")
  }

  func testDoubleBeginDispatchAdvancesOnce() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A"), snap("B")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    let first = coordinator.beginDispatch()
    XCTAssertNotNil(first)
    XCTAssertNil(coordinator.beginDispatch())
    coordinator.finishDispatch(generation: first!.generation, transactionID: first!.transactionID, result: .dispatched)
    XCTAssertEqual(coordinator.session?.nextIndex, 1)
    XCTAssertEqual(coordinator.session?.state, .ready)
  }

  func testNormalPasteDoesNotAdvance() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A"), snap("B")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    coordinator.noteNormalPaste()
    coordinator.noteNormalPaste()
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
    XCTAssertEqual(coordinator.session?.state, .ready)
    XCTAssertEqual(coordinator.normalPasteCount, 2)
  }

  func testExternalCopyPausesWithoutMutatingSnapshots() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("Name"), snap("Email")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    let before = coordinator.session?.entries.map(\.plainText)
    coordinator.noteExternalCopy()
    XCTAssertEqual(coordinator.session?.state, .paused)
    XCTAssertEqual(coordinator.session?.pauseReason, .clipboardChanged)
    XCTAssertEqual(coordinator.session?.entries.map(\.plainText), before)
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
  }

  func testCancelIgnoresStaleCompletion() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    let ticket = coordinator.beginDispatch()!
    coordinator.cancel()
    coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .dispatched)
    XCTAssertEqual(coordinator.session?.state, .cancelled)
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
    XCTAssertTrue(coordinator.session?.entries.isEmpty == true)
  }

  func testSkipPauseResumeCancelComplete() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A"), snap("B")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    XCTAssertEqual(coordinator.skip(), .ok)
    XCTAssertEqual(coordinator.session?.nextIndex, 1)
    XCTAssertEqual(coordinator.session?.state, .ready)
    XCTAssertEqual(coordinator.pause(reason: .user), .ok)
    XCTAssertEqual(coordinator.session?.state, .paused)
    XCTAssertNil(coordinator.beginDispatch())
    XCTAssertEqual(coordinator.resume(), .ok)
    XCTAssertEqual(coordinator.session?.state, .ready)
    let ticket = coordinator.beginDispatch()!
    coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .dispatched)
    XCTAssertEqual(coordinator.session?.state, .completed)
    XCTAssertEqual(coordinator.session?.entries.first?.plainText, "")
  }

  func testUncertainDoesNotAutoAdvanceAndRetryUsesSameIndex() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A"), snap("B")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    let ticket = coordinator.beginDispatch()!
    coordinator.finishDispatch(generation: ticket.generation, transactionID: ticket.transactionID, result: .uncertain)
    XCTAssertEqual(coordinator.session?.state, .paused)
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
    XCTAssertEqual(coordinator.session?.pauseReason, .uncertainDispatch)
    let retry = coordinator.prepareRetry()
    XCTAssertEqual(retry?.index, 0)
    XCTAssertEqual(retry?.entry.plainText, "A")
  }

  func testRejectedTargetDoesNotAdvance() {
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap("A")], format: .original), .ok)
    XCTAssertEqual(coordinator.activate(), .ok)
    let ticket = coordinator.beginDispatch()!
    coordinator.finishDispatch(
      generation: ticket.generation,
      transactionID: ticket.transactionID,
      result: .rejected(.invalidTarget)
    )
    XCTAssertEqual(coordinator.session?.nextIndex, 0)
    XCTAssertEqual(coordinator.session?.state, .paused)
  }

  func testLimits() {
    let coordinator = QueueCoordinator()
    let tooMany = (0..<51).map { snap("item\($0)") }
    XCTAssertEqual(coordinator.beginReview(entries: tooMany, format: .original), .rejected(.tooMany))
    var huge = snap("x")
    huge.byteCount = QueueCoordinator.maxEntryBytes + 1
    XCTAssertEqual(coordinator.beginReview(entries: [huge], format: .original), .rejected(.oversizedEntry))
  }

  func testUnicodePlainTextPreserved() {
    let text = "سلام علیکم\nاردو\tcode {\n  indent\n}\n👨‍👩‍👧‍👦"
    let transformed = IdentityTextTransform().transform(text)
    XCTAssertEqual(transformed, text)
    let coordinator = QueueCoordinator()
    XCTAssertEqual(coordinator.beginReview(entries: [snap(text)], format: .plainText), .ok)
    XCTAssertEqual(coordinator.session?.entries.first?.plainText, text)
  }
}
