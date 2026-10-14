import Cocoa

/// Kept so older call sites still compile. Product information is the Legal Notices window.
class About {
  @objc
  func openAbout(_ sender: NSMenuItem?) {
    Task { @MainActor in
      LegalNotices.show()
    }
  }
}
