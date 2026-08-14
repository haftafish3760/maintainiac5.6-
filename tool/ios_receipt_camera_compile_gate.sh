#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_LOG="$(mktemp "${TMPDIR:-/tmp}/maintainiac-ios-receipt-build.XXXXXX")"
trap 'rm -f "$BUILD_LOG"' EXIT

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required for the iOS receipt camera compile gate." >&2
  exit 1
fi

cd "$ROOT_DIR"
if ! xcodebuild -quiet \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee "$BUILD_LOG"; then
  echo "The iOS receipt camera did not compile." >&2
  exit 1
fi

if grep -Eq '/ios/Runner/[^:]+:[0-9]+:[0-9]+: warning:' "$BUILD_LOG"; then
  echo "First-party iOS receipt-camera warnings are not allowed:" >&2
  grep -E '/ios/Runner/[^:]+:[0-9]+:[0-9]+: warning:' "$BUILD_LOG" >&2
  exit 1
fi

echo "iOS receipt camera compile gate passed with no first-party Swift warnings."
