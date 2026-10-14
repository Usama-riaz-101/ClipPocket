import Defaults
import SwiftUI
import KeyboardShortcuts

struct QueueChromeView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    if appState.storageFailed {
      storageError
    } else if let session = appState.queue.session, session.state == .reviewing {
      review(session)
    } else if appState.queue.session != nil {
      active
    }
  }

  private var storageError: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("History could not be opened. Your data was not reset.")
        .font(.system(size: 13))
      Text(appState.storageErrorText)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .lineLimit(3)
      Button("Retry") {
        Storage.shared.retryLoad()
        Task { try? await appState.history.load() }
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func review(_ session: QueueSession) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Review the order before starting.")
        .font(.system(size: 13, weight: .semibold))
      Text("\(session.entries.count) items")
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
      ScrollView {
        VStack(spacing: 4) {
          ForEach(Array(session.entries.enumerated()), id: \.element.id) { index, entry in
            HStack(spacing: 8) {
              Text("\(index + 1)")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 22, height: 22)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .accessibilityLabel("Order \(index + 1)")
              Text(entry.preview)
                .font(.system(size: 13))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
              Button("Up") { _ = appState.queue.move(from: index, to: max(0, index - 1)) }
                .disabled(index == 0)
              Button("Down") {
                _ = appState.queue.move(from: index, to: min(session.entries.count - 1, index + 1))
              }
              .disabled(index == session.entries.count - 1)
              Button("Remove") { _ = appState.queue.remove(id: entry.id) }
            }
            .padding(.vertical, 4)
          }
        }
      }
      .frame(maxHeight: 280)
      Picker("Format", selection: formatBinding) {
        Text("Original").tag(QueueFormatMode.original)
        Text("Plain text").tag(QueueFormatMode.plainText)
      }
      .pickerStyle(.segmented)
      HStack {
        Button("Back") { QueueActions.backToHistory() }
        Spacer()
        Button("Activate Queue") { QueueActions.activate() }
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(12)
  }

  private var formatBinding: Binding<QueueFormatMode> {
    Binding(
      get: { appState.queue.session?.formatMode ?? .original },
      set: { _ = appState.queue.setFormat($0) }
    )
  }

  private var active: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(QueueActions.statusLine())
        .font(.system(size: 13))
        .accessibilityLabel(QueueActions.statusLine())
      HStack {
        Button("Paste Next") { Task { await QueueActions.pasteNext() } }
        Button("Skip") { QueueActions.skip() }
        if appState.queue.session?.state == .paused {
          Button("Resume") { QueueActions.resume() }
        } else {
          Button("Pause") { QueueActions.pause() }
        }
        Button("Cancel") { QueueActions.cancel() }
        if appState.queue.session?.pauseReason == .uncertainDispatch {
          Button("Retry last") { Task { await QueueActions.retryLast() } }
        }
      }
      if appState.queue.session?.state == .completed {
        Button("Dismiss") {
          appState.queue.dismissFinished()
          appState.statusMessage = ""
        }
      }
    }
    .padding(12)
  }
}

struct SetupBannerView: View {
  @Environment(AppState.self) private var appState
  @Default(.didShowSetup) private var didShowSetup

  var body: some View {
    if !didShowSetup {
      VStack(alignment: .leading, spacing: 6) {
        Text("ClipPocket keeps history on this Mac.")
          .font(.system(size: 13, weight: .semibold))
        Text("Copy text to record it. Direct paste needs Accessibility permission. History and Copy work without it.")
          .font(.system(size: 12))
          .fixedSize(horizontal: false, vertical: true)
        HStack {
          Button("OK") { didShowSetup = true }
          if !PasteExecutor.isTrusted {
            Button("Enable direct paste") { PasteExecutor.promptForAccessibility() }
          }
        }
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.accentColor.opacity(0.08))
    }
  }
}

struct CaptureStatusView: View {
  @Environment(AppState.self) private var appState
  @Default(.ignoreEvents) private var ignoreEvents

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if appState.history.all.isEmpty && appState.history.searchQuery.isEmpty && !appState.storageFailed {
        Text("Copy something to start your history.")
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
      }
      if !appState.history.searchQuery.isEmpty && appState.history.items.isEmpty {
        Text("No matches for this search.")
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
      }
      if ignoreEvents {
        HStack {
          Text("History recording is paused.")
            .font(.system(size: 12))
          Button("Resume recording") { ignoreEvents = false }
        }
        .padding(.horizontal, 8)
      }
      if !PasteExecutor.isTrusted {
        HStack {
          Text("Direct paste needs Accessibility permission.")
            .font(.system(size: 12))
          Button("Open permission instructions") { PasteExecutor.promptForAccessibility() }
        }
        .padding(.horizontal, 8)
      }
      if !appState.statusMessage.isEmpty {
        Text(appState.statusMessage)
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .lineLimit(2)
      }
    }
  }
}
