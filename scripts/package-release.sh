#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
DERIVED="${2:-build/release-universal}"
OUTPUT_DIR="release"
APP="$DERIVED/Build/Products/Release/ClipPocket.app"
ARCHIVE="$OUTPUT_DIR/ClipPocket-macOS.zip"

xcodebuild \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO \
  ARCHS="x86_64 arm64" \
  MARKETING_VERSION="$VERSION" \
  build

codesign --force --deep --sign - "$APP"

ARCHITECTURES="$(lipo -archs "$APP/Contents/MacOS/ClipPocket")"
[[ "$ARCHITECTURES" == *"x86_64"* && "$ARCHITECTURES" == *"arm64"* ]] || {
  echo "Expected a universal binary, got: $ARCHITECTURES" >&2
  exit 1
}

PLIST="$APP/Contents/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")" == "dev.funprojects.clippocket" ]]
[[ -f "$APP/Contents/Resources/AppIcon.icns" ]]
[[ -f "$APP/Contents/Resources/NOTICES.txt" ]]
[[ -f "$APP/Contents/Resources/LICENSE" ]]

if strings "$APP/Contents/MacOS/ClipPocket" | grep -Eq 'appcast|SUFeedURL|maccy\\.app/releases'; then
  echo "Release binary contains a prohibited updater or feed reference." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$ARCHIVE" "$ARCHIVE.sha256"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"

codesign --verify --deep --strict "$APP"
echo "Packaged $ARCHIVE"
echo "Architectures: $ARCHITECTURES"
cat "$ARCHIVE.sha256"
