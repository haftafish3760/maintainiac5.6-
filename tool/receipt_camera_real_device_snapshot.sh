#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
Usage: tool/receipt_camera_real_device_snapshot.sh [output_dir]

Records metadata-only connected-device state for the receipt camera lane.
This does not install, launch, tap, or navigate any device UI.
EOF
  exit 0
fi

out_dir="${1:-/tmp/maintainiac_receipt_camera_device_snapshot}"
mkdir -p "$out_dir"

timestamp="$(date '+%Y-%m-%d %H:%M:%S %Z')"
summary="$out_dir/summary.txt"

{
  echo "receipt_camera_real_device_snapshot"
  echo "timestamp=$timestamp"
  echo "workspace=$(pwd -P)"
  echo "purpose=metadata_only_no_install_no_ui_navigation"
} > "$summary"

capture_command() {
  local name="$1"
  shift
  local log="$out_dir/$name.txt"
  {
    echo "COMMAND $*"
    if command -v "$1" >/dev/null 2>&1; then
      "$@"
    else
      echo "SKIPPED missing command: $1"
    fi
  } > "$log" 2>&1 || {
    local code=$?
    {
      echo "EXIT_CODE $code"
      echo "Snapshot command failed; this records environment state only."
    } >> "$log"
  }
}

capture_command flutter_devices flutter devices
capture_command adb_devices adb devices -l

if [[ "$(uname -s)" == "Darwin" ]]; then
  capture_command xcrun_devices xcrun xctrace list devices
else
  echo "SKIPPED non-Darwin host" > "$out_dir/xcrun_devices.txt"
fi

{
  echo "snapshot_dir=$out_dir"
  echo "flutter_devices=$out_dir/flutter_devices.txt"
  echo "adb_devices=$out_dir/adb_devices.txt"
  echo "xcrun_devices=$out_dir/xcrun_devices.txt"
  echo "next_action=Run real receipt camera flows manually on connected devices; do not treat this metadata snapshot as capture proof."
} >> "$summary"

cat "$summary"
