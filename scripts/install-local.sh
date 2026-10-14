#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:-artifacts/ClipPocket.app}"
DEST="${HOME}/Applications/ClipPocket.app"
if [[ ! -d "$SRC" ]]; then
  echo "Missing $SRC. Run scripts/build-local.sh first." >&2
  exit 1
fi
mkdir -p "${HOME}/Applications"
if pgrep -f "$DEST/Contents/MacOS/ClipPocket" >/dev/null 2>&1; then
  osascript -e 'tell application "ClipPocket" to quit' || true
  sleep 1
fi
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
codesign --force --deep --sign - "$DEST"
echo "Installed $DEST"
echo "Launch with: open \"$DEST\""
