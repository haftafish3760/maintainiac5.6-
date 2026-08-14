#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-adb}"
SERIAL="${1:-}"
PACKAGE="${PACKAGE:-com.maintainiac}"

if [[ -z "$SERIAL" ]]; then
  echo "Usage: tool/receipt_pipeline_device_trace.sh S24_ADB_SERIAL" >&2
  echo "A target is required; this tool never guesses or defaults a phone." >&2
  exit 64
fi

if ! "$ADB" devices | awk \
  'NR > 1 && $1 == serial && $2 == "device" { found = 1 } END { exit found ? 0 : 1 }' \
  serial="$SERIAL"; then
  echo "Receipt pipeline trace target is not connected: $SERIAL" >&2
  exit 1
fi

MODEL="$($ADB -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
case "$MODEL" in
  SM-S928U|SM-S928U1) ;;
  *)
    echo "Refusing receipt pipeline trace on non-S24 target: serial=$SERIAL model=$MODEL" >&2
    exit 1
    ;;
esac

PID="$($ADB -s "$SERIAL" shell pidof -s "$PACKAGE" | tr -d '\r')"

if [[ -z "$PID" ]]; then
  echo "Maintainiac is not running on $SERIAL." >&2
  exit 1
fi

$ADB -s "$SERIAL" logcat -d --pid "$PID" -v threadtime |
  rg 'MAINTAINIAC_RECEIPT_TRACE|MLKitImageUtils|PipelineManager: OCR|Unhandled Exception|ANR in'
