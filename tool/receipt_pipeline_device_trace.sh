#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"
SERIAL="${1:-R5CX14WC8FA}"
PACKAGE="${PACKAGE:-com.maintainiac}"
PID="$($ADB -s "$SERIAL" shell pidof -s "$PACKAGE" | tr -d '\r')"

if [[ -z "$PID" ]]; then
  echo "Maintainiac is not running on $SERIAL." >&2
  exit 1
fi

$ADB -s "$SERIAL" logcat -d --pid "$PID" -v threadtime |
  rg 'MAINTAINIAC_RECEIPT_TRACE|MLKitImageUtils|PipelineManager: OCR|Unhandled Exception|ANR in'
