import XCTest
import SwiftData
@testable import Maccy

final class PolicyTests: XCTestCase {
  func testCaptureEligibleText() {
    let decision = CapturePolicy.decide(
      types: ["public.utf8-plain-text"],
      enabledTypes: ["public.utf8-plain-text", "public.rtf", "public.html"],
      ignoredTypes: [],
      sourceBundleID: "com.apple.TextEdit",
      ignoredApps: [],
      ignoreAllAppsExceptListed: false,
      stringIsEmpty: false,
      hasRichText: false,
      byteCount: 4,
      recordingPaused: false,
      isOwnWrite: false
    )
    XCTAssertEqual(decision, .keep)
  }

  func testCaptureIgnoresEmptyConcealedTransientIgnoredAndOwn() {
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: true,
        hasRichText: false,
        byteCount: 1,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.empty)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text", "org.nspasteboard.ConcealedType"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: false,
        hasRichText: false,
        byteCount: 4,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.concealed)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text", "org.nspasteboard.TransientType"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: false,
        hasRichText: false,
        byteCount: 4,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.transient)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.png"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: true,
        hasRichText: false,
        byteCount: 10,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.unsupported)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: "com.example.Secret",
        ignoredApps: ["com.example.Secret"],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: false,
        hasRichText: false,
        byteCount: 3,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.ignoredApp)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: false,
        hasRichText: false,
        byteCount: 3,
        recordingPaused: false,
        isOwnWrite: true
      ),
      .ignore(.ownWrite)
    )
    XCTAssertEqual(
      CapturePolicy.decide(
        types: ["public.utf8-plain-text"],
        enabledTypes: ["public.utf8-plain-text"],
        ignoredTypes: [],
        sourceBundleID: nil,
        ignoredApps: [],
        ignoreAllAppsExceptListed: false,
        stringIsEmpty: false,
        hasRichText: false,
        byteCount: CapturePolicy.maxEntryBytes + 1,
        recordingPaused: false,
        isOwnWrite: false
      ),
      .ignore(.oversized)
    )
  }

  func testRetentionProtectsPinsAndEvictsOldestUnpinned() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let old = RetentionCandidate(id: UUID(), pinned: false, lastCopiedAt: now.addingTimeInterval(-40 * 86_400), bytes: 10)
    let recent = RetentionCandidate(id: UUID(), pinned: false, lastCopiedAt: now, bytes: 10)
    let pin = RetentionCandidate(id: UUID(), pinned: true, lastCopiedAt: now.addingTimeInterval(-80 * 86_400), bytes: 10)
    let plan = RetentionPolicy.plan(
      existing: [old, recent, pin],
      incomingBytes: 10,
      incomingWouldPin: false,
      now: now,
      maxUnpinned: 10,
      maxPins: 100,
      maxAgeDays: 30,
      maxBytes: 50 * 1024 * 1024
    )
    XCTAssertEqual(plan.deleteIDs, [old.id])
    XCTAssertFalse(plan.rejectIncoming)
    XCTAssertFalse(plan.deleteIDs.contains(pin.id))
  }

  func testPinBudgetRejectsInsteadOfEvictingPins() {
    let now = Date()
    let pins = (0..<3).map { _ in
      RetentionCandidate(id: UUID(), pinned: true, lastCopiedAt: now, bytes: 20)
    }
    let plan = RetentionPolicy.plan(
      existing: pins,
      incomingBytes: 20,
      incomingWouldPin: true,
      now: now,
      maxUnpinned: 10,
      maxPins: 3,
      maxAgeDays: 30,
      maxBytes: 1_000
    )
    XCTAssertTrue(plan.rejectIncoming)
    XCTAssertTrue(plan.deleteIDs.isEmpty)
  }

  @MainActor
  func testFreshAndReopenedStoreKeepsPinAndText() throws {
    let url = FileManager.default.temporaryDirectory.appending(path: "clippocket-\(UUID().uuidString).sqlite")
    defer { try? FileManager.default.removeItem(at: url) }
    let text = "pin-me\n\tاردو"
    let first = try ModelContainer(
      for: HistoryItem.self,
      HistoryItemContent.self,
      configurations: ModelConfiguration(url: url)
    )
    let item = HistoryItem(contents: [
      HistoryItemContent(type: NSPasteboard.PasteboardType.string.rawValue, value: Data(text.utf8))
    ])
    item.pin = "p"
    item.pinOrder = 1
    item.previewText = "pin-me"
    first.mainContext.insert(item)
    try first.mainContext.save()

    let second = try ModelContainer(
      for: HistoryItem.self,
      HistoryItemContent.self,
      configurations: ModelConfiguration(url: url)
    )
    let fetched = try second.mainContext.fetch(FetchDescriptor<HistoryItem>())
    XCTAssertEqual(fetched.count, 1)
    XCTAssertEqual(fetched[0].pin, "p")
    XCTAssertEqual(fetched[0].pinOrder, 1)
    XCTAssertEqual(fetched[0].text, text)
  }

  func testCorruptStoreIsNotDeleted() {
    let url = FileManager.default.temporaryDirectory.appending(path: "clippocket-corrupt-\(UUID().uuidString).sqlite")
    try? Data("not a database".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    XCTAssertThrowsError(
      try ModelContainer(
        for: HistoryItem.self,
        HistoryItemContent.self,
        configurations: ModelConfiguration(url: url)
      )
    )
    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    XCTAssertEqual(try Data(contentsOf: url), Data("not a database".utf8))
  }

  func testDedupKeyDiffersForWhitespace() {
    let spaced = PayloadSignature.dedupKey(parts: [("public.utf8-plain-text", Data("a b".utf8))])
    let tight = PayloadSignature.dedupKey(parts: [("public.utf8-plain-text", Data("ab".utf8))])
    let same = PayloadSignature.dedupKey(parts: [("public.utf8-plain-text", Data("a b".utf8))])
    XCTAssertEqual(spaced, same)
    XCTAssertNotEqual(spaced, tight)
  }
}
