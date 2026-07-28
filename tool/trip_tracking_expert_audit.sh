#!/usr/bin/env bash
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root" || exit 1

iterations="${1:-250}"
if ! [[ "$iterations" =~ ^[0-9]+$ ]] || [ "$iterations" -lt 1 ] || [ "$iterations" -gt 1000 ]; then
  echo "TRIP_EXPERT_AUDIT_USAGE iterations=1..1000"
  exit 64
fi

log_dir="${TMPDIR:-/tmp}/maintainiac_trip_expert_audit_$(date +%s)"
mkdir -p "$log_dir"
failures=0
warnings=0

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
warn() { echo "WARN $1"; warnings=$((warnings + 1)); }

required_files=(
  lib/main.dart
  lib/shared/trip_tracking/trip_tracking_controller.dart
  lib/shared/trip_tracking/trip_tracking_engine.dart
  lib/shared/trip_tracking/trip_tracking_bluetooth_binding.dart
  android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt
  android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt
  ios/Runner/TripTrackingNativeBridge.swift
)
missing=0
for path in "${required_files[@]}"; do
  if [ ! -f "$path" ]; then
    echo "$path" >>"$log_dir/missing_files.log"
    missing=$((missing + 1))
  fi
done
if [ "$missing" -eq 0 ]; then pass "production_sources_present"; else fail "production_sources_missing=$missing log=$log_dir/missing_files.log"; fi

if rg -q "TripTrackingController\(" lib/main.dart &&
  rg -q "TripTrackingNativeBridge" android/app/src/main/kotlin/com/maintainiac/MainActivity.kt &&
  rg -q "TripTrackingNativeBridge" ios/Runner/AppDelegate.swift; then
  pass "gps_controller_and_native_bridges_wired"
else
  fail "gps_production_wiring_incomplete"
fi

bluetooth_refs="$(rg -l "TripTrackingBluetoothBinding\(" lib --glob '!lib/shared/trip_tracking/trip_tracking_bluetooth_binding.dart' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$bluetooth_refs" -gt 0 ]; then
  pass "bluetooth_trip_binding_wired refs=$bluetooth_refs"
else
  fail "bluetooth_trip_binding_not_wired_to_production"
fi

oversized="$log_dir/oversized_sources.log"
find lib/shared/trip_tracking -name '*.dart' -type f -print0 |
  xargs -0 wc -l | awk '$1 > 750 && $2 != "total" {print}' | sort -nr >"$oversized"
oversized_count="$(wc -l <"$oversized" | tr -d ' ')"
if [ "$oversized_count" -eq 0 ]; then
  pass "trip_sources_at_or_below_750_lines"
else
  warn "trip_sources_over_750_lines=$oversized_count log=$oversized"
fi

if bash -n tool/trip_tracking_qa_gate.sh \
  tool/trip_tracking_commercial_workday_qa.sh \
  tool/trip_tracking_s24_readiness.sh \
  tool/trip_tracking_s24_runtime_probe.sh; then
  pass "qa_and_device_scripts_parse"
else
  fail "qa_or_device_script_syntax"
fi

analysis_targets=(
  lib/shared/trip_tracking
  lib/screens/settings/trip_tracking_settings_screen.dart
  lib/screens/dashboard/data/dashboard_trip_tracking_summary.dart
  lib/main.dart
)
if flutter analyze "${analysis_targets[@]}" >"$log_dir/analyze.log" 2>&1; then
  pass "focused_flutter_analyze"
else
  fail "focused_flutter_analyze log=$log_dir/analyze.log"
fi

bluetooth_tests=(
  test/device_bluetooth_connection_observation_test.dart
  test/trip_automatic_start_coordinator_test.dart
  test/trip_automatic_start_detector_test.dart
  test/trip_tracking_bluetooth_binding_test.dart
  test/trip_tracking_bluetooth_connection_coordinator_test.dart
  test/trip_tracking_bluetooth_coordinator_test.dart
  test/trip_tracking_bluetooth_native_contract_test.dart
  test/trip_tracking_bluetooth_test.dart
)
if flutter test --concurrency=1 "${bluetooth_tests[@]}" --reporter compact >"$log_dir/bluetooth_tests.log" 2>&1; then
  pass "bluetooth_and_automatic_start_tests"
else
  fail "bluetooth_and_automatic_start_tests log=$log_dir/bluetooth_tests.log"
fi

if ./tool/trip_tracking_commercial_workday_qa.sh >"$log_dir/commercial_workday.log" 2>&1; then
  pass "commercial_workday_suite"
else
  fail "commercial_workday_suite log=$log_dir/commercial_workday.log"
fi

if dart run tool/trip_tracking_simulation_runner.dart \
  "--iterations=$iterations" \
  "--output=$log_dir/simulation.json" >"$log_dir/simulation.log" 2>&1; then
  pass "bounded_hostile_simulation iterations=$iterations"
else
  fail "bounded_hostile_simulation log=$log_dir/simulation.log"
fi

if git diff --check -- lib/shared/trip_tracking test/trip* tool/trip* >"$log_dir/diff_check.log" 2>&1; then
  pass "trip_scope_diff_check"
else
  fail "trip_scope_diff_check log=$log_dir/diff_check.log"
fi

echo "TRIP_EXPERT_AUDIT_SUMMARY failures=$failures warnings=$warnings log_dir=$log_dir"
[ "$failures" -eq 0 ]
