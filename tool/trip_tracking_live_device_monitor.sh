#!/usr/bin/env bash
# Read-only, privacy-safe live monitor for a debug Maintainiac field test.
#
# Owns a filtered Android logcat stream for one explicitly supplied device.
# Does not start/stop tracking, change any app data, clear device logs, or
# expose coordinates, route geometry, mileage, customer, or vehicle identity.
# Consumed by the GPS field-test operator over USB or wireless ADB.

set -euo pipefail

serial="${1:-}"
if [[ -z "$serial" ]]; then
  printf 'usage: trip_tracking_live_device_monitor.sh <adb-serial>\n' >&2
  exit 64
fi

if ! adb -s "$serial" get-state >/dev/null 2>&1; then
  printf 'Maintainiac field monitor: device is unavailable: %s\n' "$serial" >&2
  exit 1
fi

if ! adb -s "$serial" shell pidof com.maintainiac >/dev/null 2>&1; then
  printf 'Maintainiac field monitor: app process is not running yet.\n' >&2
  exit 1
fi

printf 'Maintainiac field monitor attached: %s\n' "$serial"
printf 'Read-only debug health feed; press Ctrl-C to stop monitoring.\n'
exec adb -s "$serial" logcat -v threadtime MaintainiacTripDiag:I '*:S'
