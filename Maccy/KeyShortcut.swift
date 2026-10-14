import AppKit.NSEvent
import Defaults
import Sauce

struct KeyShortcut: Identifiable {
  static func create(character: String) -> [KeyShortcut] {
    let key = Key(character: character, virtualKeyCode: nil)
    return [
      KeyShortcut(key: key, modifierFlags: []),
      KeyShortcut(key: key, modifierFlags: [.option]),
      KeyShortcut(key: key, modifierFlags: [.option, .shift])
    ]
  }

  let id = UUID()

  var key: Key?
  var modifierFlags: NSEvent.ModifierFlags = [.command]

  var description: String {
    guard let key, let character = Sauce.shared.currentASCIICapableCharacter(
      for: Int(Sauce.shared.keyCode(for: key)),
      cocoaModifiers: []
    ) else {
      return ""
    }

    return "\(modifierFlags.description)\(character.capitalized)"
  }

  func isVisible(_ all: [KeyShortcut], _ pressedModifierFlags: NSEvent.ModifierFlags) -> Bool {
    if all.count == 1 {
      return true
    }

    let pressed = pressedModifierFlags.intersection(.deviceIndependentFlagsMask).subtracting(.capsLock)
    if pressed.isEmpty {
      return modifierFlags.isEmpty
    }

    return modifierFlags == pressed
  }
}
