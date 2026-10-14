#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
DERIVED="${1:-build/dd}"
xcodebuild \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -configuration Release \
  -destination "platform=macOS,arch=x86_64" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  build
APP="$DERIVED/Build/Products/Release/ClipPocket.app"
codesign --force --deep --sign - "$APP"
mkdir -p artifacts
rm -rf artifacts/ClipPocket.app
cp -R "$APP" artifacts/ClipPocket.app
codesign --force --deep --sign - artifacts/ClipPocket.app
echo "Built $(pwd)/artifacts/ClipPocket.app"
codesign -dv artifacts/ClipPocket.app 2>&1 | head -n 20
