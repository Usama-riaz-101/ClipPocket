# ClipPocket — Clipboard History & Paste Queue for macOS

**A fast, private clipboard manager for Mac with searchable history, image previews, pins, instant paste, and an ordered multi-item paste queue.**

[![Download ClipPocket for macOS](https://img.shields.io/badge/Download-ClipPocket_for_macOS-1677ff?style=for-the-badge&logo=apple)](https://github.com/Usama-riaz-101/ClipPocket/releases/latest/download/ClipPocket-macOS.zip)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)](https://github.com/Usama-riaz-101/ClipPocket/releases/latest)
[![Local First](https://img.shields.io/badge/privacy-local--first-20a05a)](#privacy)
[![License](https://img.shields.io/badge/license-PolyForm_Noncommercial-orange)](LICENSE)

ClipPocket keeps copied text and images close at hand without accounts, cloud sync, tracking, or a server. Press **Shift-Command-V** from any app, search or select an item with the keyboard or mouse, and ClipPocket pastes it back into the field you were using.

## See ClipPocket in action

![ClipPocket clipboard history and instant paste walkthrough](docs/media/clippocket-walkthrough.gif)

## Download

### [Download the latest ClipPocket app](https://github.com/Usama-riaz-101/ClipPocket/releases/latest/download/ClipPocket-macOS.zip)

1. Download and unzip `ClipPocket-macOS.zip`.
2. Move **ClipPocket.app** to your Applications folder.
3. On first launch, Control-click the app and choose **Open**. The current community build is ad-hoc signed rather than Apple-notarized.
4. Allow ClipPocket under **System Settings → Privacy & Security → Accessibility** for automatic paste. Clipboard history still works without this permission.

ClipPocket requires macOS 14 or newer. The downloadable build supports Intel Macs and Apple silicon Macs.

## Features

- **Instant clipboard picker** — open it anywhere with Shift-Command-V.
- **Automatic paste** — select an entry and it returns to the previous text field.
- **Keyboard-first search** — type to filter, use arrow keys, then press Return.
- **Text and image history** — identify copied images using inline previews.
- **Link highlighting** — URLs are visually distinct from ordinary text.
- **Pins** — keep important clipboard entries available.
- **Ordered paste queue** — prepare Name, Email, Address, or any sequence and paste one item per field.
- **Queue controls** — reorder, remove, preview, skip, pause, resume, and cancel.
- **Normal Command-V stays normal** — ClipPocket never hijacks the system paste shortcut.
- **Menu-bar utility** — compact, native, and out of the way.

## How to use

### Clipboard history

1. Copy text or an image normally.
2. Press **Shift-Command-V**.
3. Search, use the arrow keys, or click an entry.
4. Press Return or click the entry to paste it into the previously active field.

### Ordered paste queue

1. Open ClipPocket from the menu bar and choose **Queue**.
2. Select entries in the order you need them.
3. Review, reorder, or remove entries, then activate the queue.
4. Focus each destination field and press **Control-Option-Command-V** to paste the next entry.

New clipboard copies pause an active queue and are recorded separately; they never mutate the queue snapshot.

## Privacy

ClipPocket is local-first:

- Clipboard data remains on your Mac.
- No account, analytics, external API, update feed, or runtime network connection.
- Data is stored under `~/Library/Application Support/ClipPocket`.
- Preferences use the independent `dev.funprojects.clippocket` domain.

## Build from source

Xcode is required.

```sh
git clone https://github.com/Usama-riaz-101/ClipPocket.git
cd ClipPocket
zsh scripts/test-local.sh
zsh scripts/build-local.sh
zsh scripts/install-local.sh
```

The local build installs to `~/Applications/ClipPocket.app`.

## Project status

ClipPocket is Fun Projects **Project 02**. See [`DELIVERY-REPORT.md`](DELIVERY-REPORT.md) for implementation evidence, measured performance, compatibility notes, and remaining editor-verification details.

## License

ClipPocket-specific work is available under the **PolyForm Noncommercial License 1.0.0**: you may inspect, use, modify, and share it for noncommercial purposes, but you may not sell it or use it for commercial purposes.

Required third-party copyright and license notices remain available in [`LICENSE`](LICENSE) and the in-app **Legal Notices** screen. This mixed-license project is source-available, not OSI-approved open source.

Created and maintained by [Usama Riaz](https://www.linkedin.com/in/usama-riaz-6a9748248).

Copyright © 2026 Usama Riaz.
