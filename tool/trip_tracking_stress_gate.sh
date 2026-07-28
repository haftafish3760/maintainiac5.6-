#!/usr/bin/env bash
# Deterministic, memory-bounded GPS stress gate for 1K through 1M scenarios.
# Owns one Flutter test invocation and retained log/report paths; it does not
# inspect device data or alter production state. Developers and CI consume it.

set -u

scenario_count="${1:-1000}"
master_seed="${2:-7272026}"
batch_size="${3:-256}"
output_path="${4:-/tmp/trip_tracking_stress_${scenario_count}_${master_seed}.json}"
log_path="${output_path%.json}.log"
git_revision="$(git rev-parse --short HEAD 2>/dev/null || printf unknown)"

case "${scenario_count}" in
  1000|10000|100000|500000|1000000) ;;
  *)
    printf 'scenario count must be 1000, 10000, 100000, 500000, or 1000000\n' >&2
    exit 64
    ;;
esac

flutter test test/trip_tracking_stress_gate_test.dart \
  --dart-define="TRIP_STRESS_SCENARIOS=${scenario_count}" \
  --dart-define="TRIP_STRESS_SEED=${master_seed}" \
  --dart-define="TRIP_STRESS_BATCH_SIZE=${batch_size}" \
  --dart-define="TRIP_STRESS_GIT_REVISION=${git_revision}" \
  --dart-define="TRIP_STRESS_OUTPUT=${output_path}" \
  >"${log_path}" 2>&1
exit_code=$?

if [ "${exit_code}" -eq 0 ]; then
  printf 'TRIP_STRESS_PASS scenarios=%s seed=%s report=%s log=%s\n' \
    "${scenario_count}" "${master_seed}" "${output_path}" "${log_path}"
else
  printf 'TRIP_STRESS_FAIL exit=%s report=%s log=%s\n' \
    "${exit_code}" "${output_path}" "${log_path}" >&2
fi
exit "${exit_code}"
