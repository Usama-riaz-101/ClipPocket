import Foundation
import SwiftData

@MainActor
class Storage {
  static let shared = Storage()

  var container: ModelContainer
  var context: ModelContext { container.mainContext }
  private(set) var loadError: String?
  private(set) var usingRecoveryStore = false

  var size: String {
    guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).allValues.first?.value as? Int64, size > 1 else {
      return ""
    }

    return ByteCountFormatter().string(fromByteCount: size)
  }

  let url = URL.applicationSupportDirectory.appending(path: "ClipPocket/Storage.sqlite")
  private let versionURL = URL.applicationSupportDirectory.appending(path: "ClipPocket/schema.version")

  init() {
    var error: String?
    var recovery = false
    container = Storage.openContainer(at: url, versionURL: versionURL, loadError: &error, usingRecoveryStore: &recovery)
    loadError = error
    usingRecoveryStore = recovery
  }

  func retryLoad() {
    var error: String?
    var recovery = false
    container = Storage.openContainer(at: url, versionURL: versionURL, loadError: &error, usingRecoveryStore: &recovery)
    loadError = error
    usingRecoveryStore = recovery
  }

  private static func openContainer(
    at url: URL,
    versionURL: URL,
    loadError: inout String?,
    usingRecoveryStore: inout Bool
  ) -> ModelContainer {
    let directory = url.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    #if DEBUG
    if CommandLine.arguments.contains("enable-testing") {
      let memory = ModelConfiguration(isStoredInMemoryOnly: true)
      if let container = try? ModelContainer(for: HistoryItem.self, HistoryItemContent.self, configurations: memory) {
        return container
      }
    }
    #endif

    let configuration = ModelConfiguration(url: url)
    do {
      let container = try ModelContainer(for: HistoryItem.self, HistoryItemContent.self, configurations: configuration)
      try? "1".write(to: versionURL, atomically: true, encoding: .utf8)
      return container
    } catch {
      loadError = error.localizedDescription
      usingRecoveryStore = true
      let memory = ModelConfiguration(isStoredInMemoryOnly: true)
      if let container = try? ModelContainer(for: HistoryItem.self, HistoryItemContent.self, configurations: memory) {
        return container
      }
      fatalError("Cannot allocate a temporary history store: \(error.localizedDescription).")
    }
  }
}
