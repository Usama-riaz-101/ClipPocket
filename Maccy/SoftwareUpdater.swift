import Foundation

/// Update checks are not part of ClipPocket. This type stays so older call sites
/// cannot start a feed request even if they are revived.
@Observable
class SoftwareUpdater {
  var automaticallyChecksForUpdates = false

  func checkForUpdates() {}
}
