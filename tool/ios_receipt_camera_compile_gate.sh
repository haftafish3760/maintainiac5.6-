#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required for the iOS receipt camera compile gate." >&2
  exit 1
fi

cd "$ROOT_DIR"
xcodebuild -quiet \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
