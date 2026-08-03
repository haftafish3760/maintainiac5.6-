#!/usr/bin/env bash
# Safe, repeatable evidence collector and entry-flow driver for Maintainiac
# Expense receipts. The opt-in driver controls only the connected S24 Ultra,
# records every screen it reaches, and stops before it selects a real gallery
# image, captures a photo, types receipt data, saves a draft, or triggers sync.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ADB:-adb}"
SERIAL="${SERIAL:-R5CX14WC8FA}"
PACKAGE="${PACKAGE:-com.maintainiac}"
MODE="snapshot"
RUN_TESTS=0
LAUNCH_APP=0
DRIVE_RECEIPT_ENTRY=0
OPEN_RECEIPT_OPTIONS=0

usage() {
  cat <<'EOF'
Usage: tool/expense_receipt_device_runner.sh [options]

Collects receipt-flow device evidence into build/expense_receipt_device_runs.
By default it only observes. With --drive-receipt-entry it navigates the app
to the single-page Expense Receipt form on the directly-connected S24 Ultra.
It never imports a photo, starts camera capture, edits a receipt, saves a
draft, or starts a cloud sync.

Options:
  --serial SERIAL       ADB serial (default: R5CX14WC8FA or $SERIAL)
  --package PACKAGE     Android package (default: com.maintainiac)
  --launch              Bring Maintainiac to foreground before collecting.
  --drive-receipt-entry Launch, open Expenses, then open Add Expense itself.
  --open-receipt-options With --drive-receipt-entry, open Add Receipt options
                        and stop before any photo, PDF, or text is selected.
  --tests               Run focused, non-device receipt UI contracts too.
  --all                 Equivalent to --launch --tests.
  --output DIRECTORY    Artifact directory; defaults to a timestamped build path.
  -h, --help            Print this help.

Artifacts:
  manifest.txt          Device, app, branch, and source evidence.
  screen.png            Current device screen, if capture succeeds.
  ui.xml                Current accessibility tree, if available.
  receipt-logcat.txt    Maintainiac and receipt-related logs.
  crash-logcat.txt      Android crash-buffer evidence.
  focused-tests.txt     Focused contract results, when --tests is supplied.

For camera/gallery end-to-end testing, add a named synthetic fixture route.
Never use a real receipt, user data, or backup credentials in unattended runs.
EOF
}

OUTPUT_DIR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --serial)
      SERIAL="${2:?--serial requires a value}"
      shift 2
      ;;
    --package)
      PACKAGE="${2:?--package requires a value}"
      shift 2
      ;;
    --launch)
      LAUNCH_APP=1
      shift
      ;;
    --drive-receipt-entry)
      DRIVE_RECEIPT_ENTRY=1
      LAUNCH_APP=1
      shift
      ;;
    --open-receipt-options)
      OPEN_RECEIPT_OPTIONS=1
      shift
      ;;
    --tests)
      RUN_TESTS=1
      shift
      ;;
    --all)
      LAUNCH_APP=1
      RUN_TESTS=1
      shift
      ;;
    --output)
      OUTPUT_DIR="${2:?--output requires a directory}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

require_adb_target() {
  if ! "$ADB" devices | awk 'NR > 1 && $1 == serial && $2 == "device" { found = 1 } END { exit found ? 0 : 1 }' serial="$SERIAL"; then
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL target_not_ready serial=$SERIAL" >&2
    "$ADB" devices -l >&2 || true
    exit 1
  fi
}

require_s24_ultra() {
  local model
  model="$($ADB -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
  case "$model" in
    SM-S928U|SM-S928U1)
      ;;
    *)
      echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL refusing_non_s24_ultra serial=$SERIAL model=$model" >&2
      exit 1
      ;;
  esac
}

snapshot() {
  local name="$1"
  "$ADB" -s "$SERIAL" exec-out screencap -p >"$OUTPUT_DIR/${name}.png" 2>"$OUTPUT_DIR/${name}-screencap-error.txt" || true
  "$ADB" -s "$SERIAL" shell uiautomator dump "/sdcard/${name}.xml" >/dev/null 2>"$OUTPUT_DIR/${name}-ui-error.txt" || true
  "$ADB" -s "$SERIAL" pull "/sdcard/${name}.xml" "$OUTPUT_DIR/${name}.xml" >/dev/null 2>&1 || true
}

tap_accessibility_label() {
  local label="$1"
  local ui_file="$2"
  local coordinates
  coordinates="$(python3 - "$label" "$ui_file" <<'PY'
import sys
import xml.etree.ElementTree as element_tree

label, path = sys.argv[1:]
root = element_tree.parse(path).getroot()
for node in root.iter('node'):
    value = (node.attrib.get('content-desc') or node.attrib.get('text') or '')
    first = value.split('\n', 1)[0]
    if first != label or node.attrib.get('clickable') != 'true':
        continue
    bounds = node.attrib.get('bounds', '')
    import re
    match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds)
    if match is None:
        continue
    left, top, right, bottom = map(int, match.groups())
    print((left + right) // 2, (top + bottom) // 2)
    break
else:
    raise SystemExit(f'No clickable accessibility label: {label}')
PY
)" || {
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL missing_label=$label ui=$ui_file" >&2
    exit 1
  }
  set -- $coordinates
  "$ADB" -s "$SERIAL" shell input tap "$1" "$2"
}

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$ROOT_DIR/build/expense_receipt_device_runs/$timestamp"
fi
mkdir -p "$OUTPUT_DIR"

require_adb_target
require_s24_ultra

if [ "$OPEN_RECEIPT_OPTIONS" -eq 1 ] && [ "$DRIVE_RECEIPT_ENTRY" -eq 0 ]; then
  echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL --open-receipt-options requires --drive-receipt-entry" >&2
  exit 2
fi

if [ "$LAUNCH_APP" -eq 1 ]; then
  activity="$($ADB -s "$SERIAL" shell cmd package resolve-activity --brief "$PACKAGE" 2>/dev/null | tr -d '\r' | tail -n 1)"
  if [ -z "$activity" ] || [ "$activity" = "No activity found" ]; then
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL activity_not_found package=$PACKAGE" >&2
    exit 1
  fi
  if [ "$DRIVE_RECEIPT_ENTRY" -eq 1 ]; then
    # Start from the app root without clearing any user data. A running
    # Flutter route would otherwise leave the runner trapped in the last
    # receipt draft instead of the dashboard it is meant to test.
    "$ADB" -s "$SERIAL" shell am force-stop "$PACKAGE" >"$OUTPUT_DIR/force-stop.txt" 2>&1
  fi
  "$ADB" -s "$SERIAL" shell am start -n "$activity" >"$OUTPUT_DIR/launch.txt" 2>&1 || {
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL launch_failed artifact=$OUTPUT_DIR/launch.txt" >&2
    exit 1
  }
fi

{
  echo "runner=expense_receipt_device_runner"
  echo "captured_at_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "serial=$SERIAL"
  echo "package=$PACKAGE"
  echo "branch=$(git -C "$ROOT_DIR" branch --show-current)"
  echo "commit=$(git -C "$ROOT_DIR" rev-parse HEAD)"
  echo "worktree=$(git -C "$ROOT_DIR" status --short | wc -l | tr -d ' ') changed_paths"
  echo "device=$($ADB -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
  echo "android=$($ADB -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
  "$ADB" -s "$SERIAL" shell dumpsys package "$PACKAGE" 2>/dev/null |
    awk -F= '/versionName=|versionCode=|lastUpdateTime=/ { print $1 "=" $2 }'
  "$ADB" -s "$SERIAL" shell dumpsys activity activities 2>/dev/null |
    awk '/topResumedActivity=|mCurrentFocus=/'
} >"$OUTPUT_DIR/manifest.txt"

snapshot screen

if [ "$DRIVE_RECEIPT_ENTRY" -eq 1 ]; then
  sleep 2
  snapshot 01-launch
  tap_accessibility_label Expenses "$OUTPUT_DIR/01-launch.xml"
  sleep 2
  snapshot 02-expenses
  tap_accessibility_label 'Add Expense' "$OUTPUT_DIR/02-expenses.xml"
  sleep 2
  snapshot 03-expense-receipt
  if ! grep -q 'Expense Receipt' "$OUTPUT_DIR/03-expense-receipt.xml"; then
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL receipt_entry_not_reached artifact=$OUTPUT_DIR/03-expense-receipt.xml" >&2
    exit 1
  fi
  if [ "$OPEN_RECEIPT_OPTIONS" -eq 1 ]; then
    "$ADB" -s "$SERIAL" shell input swipe 720 2700 720 950 380
    sleep 1
    snapshot 04-receipt-attachment
    tap_accessibility_label 'Add Receipt' "$OUTPUT_DIR/04-receipt-attachment.xml"
    sleep 1
    snapshot 05-receipt-options
  fi
fi

"$ADB" -s "$SERIAL" logcat -d -v threadtime 2>/dev/null |
  grep -E 'com\.maintainiac|MAINTAINIAC_RECEIPT_TRACE|ReceiptCamera|MLKit|OCR|ANR|FATAL EXCEPTION' |
  tail -n 1200 >"$OUTPUT_DIR/receipt-logcat.txt" || true
"$ADB" -s "$SERIAL" logcat -b crash -d -v threadtime 2>/dev/null |
  tail -n 400 >"$OUTPUT_DIR/crash-logcat.txt" || true

if [ "$RUN_TESTS" -eq 1 ]; then
  (
    cd "$ROOT_DIR"
    flutter test --concurrency=1 --reporter compact \
      test/expense_receipt_manual_exit_contract_test.dart \
      test/expense_receipt_manual_optional_evidence_contract_test.dart \
      test/expense_receipt_manual_screen_rebuild_contract_test.dart \
      test/expense_receipt_manual_step_indicator_contract_test.dart \
      test/receipt_capture_flow_assist_opt_in_contract_test.dart \
      test/receipt_photo_review_quality_handoff_test.dart
  ) >"$OUTPUT_DIR/focused-tests.txt" 2>&1 || {
    echo "EXPENSE_RECEIPT_DEVICE_RUNNER_FAIL focused_tests artifact=$OUTPUT_DIR/focused-tests.txt" >&2
    exit 1
  }
fi

echo "EXPENSE_RECEIPT_DEVICE_RUNNER_PASS artifacts=$OUTPUT_DIR"
