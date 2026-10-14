import AppKit

@MainActor
enum LegalNotices {
  static func show() {
    let text = loadText()
    let view = NSTextView(frame: NSRect(x: 0, y: 0, width: 520, height: 480))
    view.string = text
    view.isEditable = false
    view.isSelectable = true
    view.font = NSFont.systemFont(ofSize: 12)
    view.textContainerInset = NSSize(width: 12, height: 12)
    view.drawsBackground = false

    let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 560, height: 520))
    scroll.documentView = view
    scroll.hasVerticalScroller = true
    scroll.borderType = .noBorder

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Legal Notices"
    window.contentView = scroll
    window.center()
    window.isReleasedWhenClosed = false
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    retain(window)
  }

  private static var windows: [NSWindow] = []

  private static func retain(_ window: NSWindow) {
    windows.append(window)
  }

  static func loadText() -> String {
    let license = bundled("LICENSE") ?? "License text is missing from the app bundle."
    let notices = bundled("NOTICES.txt") ?? ""
    return """
    ClipPocket

    \(license)

    Third-party notices

    \(notices)
    """
  }

  private static func bundled(_ name: String) -> String? {
    let base = (name as NSString).deletingPathExtension
    let ext = (name as NSString).pathExtension
    let url = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? nil : ext)
      ?? Bundle.main.url(forResource: name, withExtension: nil)
    guard let url, let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    return text
  }
}
