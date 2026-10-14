#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
DERIVED="${1:-build/dd}"
xcodebuild \
  -project Maccy.xcodeproj \
  -scheme Maccy \
  -destination "platform=macOS,arch=x86_64" \
  -derivedDataPath "$DERIVED" \
  -only-testing:MaccyTests \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  test
