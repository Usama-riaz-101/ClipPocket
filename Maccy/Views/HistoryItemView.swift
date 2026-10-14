import Defaults
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  private var visualIndex: Int? {
    if item.selectionIndex >= 0 && (appState.queueSelectionMode || appState.navigator.isMultiSelectInProgress) {
      return item.selectionIndex
    }
    return nil
  }

  private var rowHighlighted: Bool {
    if appState.queueSelectionMode {
      return appState.navigator.leadHistoryItem?.id == item.id
    }
    return item.isSelected
  }

  private var selectionAppearance: SelectionAppearance {
    let previousSelected = previous?.isSelected ?? false
    let nextSelected = next?.isSelected ?? false
    switch (previousSelected, nextSelected) {
    case (true, false):
      return .topConnection
    case (false, true):
      return .bottomConnection
    case (true, true):
      return .topBottomConnection
    default:
      return .none
    }
  }

  @Default(.showHexColorSwatch) private var showHexColorSwatch
  @Environment(AppState.self) private var appState

  private var colorSwatchImage: NSImage? {
    guard showHexColorSwatch else { return nil }
    return ColorImage.from(item.title)
  }

  var body: some View {
    ListItemView(
      id: item.id,
      selectionId: item.id,
      appIcon: item.applicationImage,
      image: item.thumbnailImage,
      accessoryImage: item.thumbnailImage != nil ? nil : colorSwatchImage,
      attributedTitle: LinkStyledText.coloring(item.attributedTitle ?? AttributedString(item.title), selected: rowHighlighted),
      shortcuts: item.shortcuts,
      isSelected: rowHighlighted,
      selectionIndex: visualIndex,
      selectionAppearance: selectionAppearance
    ) {
      Text(verbatim: item.title)
    }
    .onAppear {
      item.ensureThumbnailImage()
    }
    .onTapGesture {
      if appState.queueSelectionMode {
        appState.navigator.addToSelection(item: item)
        return
      }
      if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
        appState.navigator.addToSelection(item: item)
      } else {
        let flags = NSEvent.ModifierFlags.currentModifierFlags
        Task {
          appState.history.select(item, flags: flags)
        }
      }
    }
  }
}
