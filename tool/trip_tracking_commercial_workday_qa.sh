#!/usr/bin/env bash
set -euo pipefail

log_file="${TMPDIR:-/tmp}/maintainiac_commercial_workday_qa_$(date +%s).log"

tests=(
  test/trip_tracking_commercial_workday_replay_test.dart
  test/trip_tracking_field_failure_replay_test.dart
  test/trip_tracking_fuzz_test.dart
  test/trip_tracking_simulation_test.dart
  test/active_workday_gps_start_integration_test.dart
  test/dashboard_round_start_gps_integration_test.dart
  test/trip_tracking_signal_gap_recovery_test.dart
  test/trip_tracking_live_odometer_broadcast_test.dart
  test/trip_tracking_native_capability_boundary_test.dart
  test/trip_tracking_native_provider_registration_contract_test.dart
  test/trip_tracking_provider_registration_state_test.dart
  test/trip_tracking_dashboard_live_status_policy_test.dart
  test/trip_tracking_device_operational_policy_test.dart
  test/trip_tracking_field_evidence_test.dart
  test/trip_tracking_benchmark_reporter_test.dart
  test/trip_tracking_field_trial_summary_test.dart
  test/trip_tracking_long_session_recovery_test.dart
  test/trip_tracking_controller_recovery_integrity_test.dart
  test/trip_tracking_paused_ingestion_test.dart
  test/trip_tracking_atomic_session_start_test.dart
  test/trip_tracking_heartbeat_watchdog_policy_test.dart
)

if ! flutter test --concurrency=1 "${tests[@]}" --reporter compact \
  >"$log_file" 2>&1; then
  echo "COMMERCIAL_WORKDAY_QA_FAIL log=$log_file"
  exit 1
fi

if ! dart run tool/trip_tracking_simulation_runner.dart --iterations=100 \
  >>"$log_file" 2>&1; then
  echo "COMMERCIAL_WORKDAY_QA_FAIL log=$log_file"
  exit 1
fi

echo "COMMERCIAL_WORKDAY_QA_PASS log=$log_file"
