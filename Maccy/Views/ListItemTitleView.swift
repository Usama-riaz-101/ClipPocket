import SwiftUI

enum LinkStyledText {
  static func coloring(_ source: AttributedString, selected: Bool) -> AttributedString {
    var result = source
    let plain = String(source.characters)
    if selected {
      result.foregroundColor = .white
    }
    guard !plain.isEmpty,
          let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return result
    }

    let linkColor: Color = selected
      ? Color(red: 1, green: 0.9, blue: 0.45)
      : Color(nsColor: .linkColor)
    let matches = detector.matches(in: plain, range: NSRange(location: 0, length: (plain as NSString).length))
    for match in matches {
      guard let stringRange = Range(match.range, in: plain),
            let lower = AttributedString.Index(stringRange.lowerBound, within: result),
            let upper = AttributedString.Index(stringRange.upperBound, within: result) else {
        continue
      }
      result[lower..<upper].foregroundColor = linkColor
    }
    return result
  }
}

struct ListItemTitleView<Title: View>: View {
  var attributedTitle: AttributedString?
  @ViewBuilder var title: () -> Title

  var body: some View {
    if let attributedTitle {
      Text(attributedTitle)
        .accessibilityIdentifier("copy-history-item")
        .lineLimit(2)
        .truncationMode(.middle)
    } else {
      title()
        .accessibilityIdentifier("copy-history-item")
        .lineLimit(2)
        .truncationMode(.middle)
        // Workaround for macOS 26 to avoid flipped text
        // https://github.com/p0deje/Maccy/issues/1113
        .drawingGroup()
    }
  }
}
