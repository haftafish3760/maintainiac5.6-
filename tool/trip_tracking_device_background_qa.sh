#!/usr/bin/env bash
# Batched physical-device lifecycle evidence for Maintainiac trip tracking.
#
# Owns safe launch/background-resume checks, concise retained logs, and an
# optional deterministic simulation gate. It does not start a trip, change
# location permission, inject location, read coordinates, force-stop apps, or
# prove GPS accuracy. Android Home is a real background transition; iOS
# suspend/resume is a lifecycle probe, not proof of iOS background location.

set -u

bundle_id="com.maintainiac"
android_serial="${ANDROID_SERIAL:-R5CX14WC8FA}"
ios_device="${IOS_DEVICE:-robbies-iPhone.coredevice.local}"
mode="${1:-both}"
wait_seconds="${2:-20}"
batch_count="${3:-1}"
stress_scenarios="${4:-0}"
stress_seed="${5:-7272026}"
run_stamp="$(date +%Y%m%d_%H%M%S)"
run_dir="/tmp/maintainiac_trip_device_background_${run_stamp}"

if [ "${wait_seconds}" -lt 5 ] || [ "${wait_seconds}" -gt 60 ]; then
  printf 'wait seconds must be between 5 and 60\n' >&2
  exit 64
fi
if [ "${batch_count}" -lt 1 ] || [ "${batch_count}" -gt 10 ]; then
  printf 'batch count must be between 1 and 10\n' >&2
  exit 64
fi
case "${mode}" in
  android|ios|both) ;;
  *)
    printf 'mode must be android, ios, or both\n' >&2
    exit 64
    ;;
esac
case "${stress_scenarios}" in
  0|1000|10000|100000|500000|1000000) ;;
  *)
    printf 'stress scenarios must be 0, 1000, 10000, 100000, 500000, or 1000000\n' >&2
    exit 64
    ;;
esac

mkdir -p "${run_dir}"
printf '%s\n' \
  'Maintainiac GPS device lifecycle logs; no coordinates or route data captured.' \
  > "${run_dir}/README.txt"

android_result="NOT_REQUESTED"
ios_result="NOT_REQUESTED"
simulation_result="NOT_REQUESTED"

run_simulation() {
  if [ "${stress_scenarios}" = "0" ]; then
    simulation_result="NOT_REQUESTED"
    return
  fi
  if ./tool/trip_tracking_stress_gate.sh \
    "${stress_scenarios}" "${stress_seed}" 256 \
    "${run_dir}/trip_tracking_stress.json" \
    > "${run_dir}/trip_tracking_stress_gate.log" 2>&1; then
    simulation_result="PASS_${stress_scenarios}_SCENARIOS"
  else
    simulation_result="FAILED_${stress_scenarios}_SCENARIOS"
  fi
}

run_android() {
  if ! adb -s "${android_serial}" get-state > "${run_dir}/android_connection.log" 2>&1; then
    android_result="NOT_CONNECTED"
    return
  fi
  batch=1
  android_survived_batches=0
  while [ "${batch}" -le "${batch_count}" ]; do
    batch_dir="${run_dir}/android_batch_${batch}"
    mkdir -p "${batch_dir}"
    if ! adb -s "${android_serial}" shell am start -n "${bundle_id}/.MainActivity" \
      > "${batch_dir}/launch.log" 2>&1; then
      android_result="LAUNCH_FAILED"
      return
    fi
    sleep 2
    adb -s "${android_serial}" shell pidof "${bundle_id}" \
      > "${batch_dir}/foreground_pid.log" 2>&1 || true
    adb -s "${android_serial}" shell input keyevent HOME \
      > "${batch_dir}/background_action.log" 2>&1 || true
    sleep "${wait_seconds}"
    adb -s "${android_serial}" shell pidof "${bundle_id}" \
      > "${batch_dir}/background_pid.log" 2>&1 || true
    adb -s "${android_serial}" shell am start -n "${bundle_id}/.MainActivity" \
      > "${batch_dir}/resume.log" 2>&1 || true
    sleep 2
    adb -s "${android_serial}" shell pidof "${bundle_id}" \
      > "${batch_dir}/resume_pid.log" 2>&1 || true
    if [ -s "${batch_dir}/background_pid.log" ] && \
      [ -s "${batch_dir}/resume_pid.log" ]; then
      android_survived_batches=$((android_survived_batches + 1))
    fi
    batch=$((batch + 1))
  done
  adb -s "${android_serial}" logcat -d -v epoch \
    | grep -Ei 'maintainiac|triptracking|trip_tracking' \
    > "${run_dir}/android_trip_logcat.log" || true
  if [ "${android_survived_batches}" -eq "${batch_count}" ]; then
    android_result="PROCESS_SURVIVED_HOME_${batch_count}_BATCHES"
  else
    android_result="PROCESS_NOT_CONFIRMED"
  fi
}

run_ios() {
  if ! xcrun devicectl list devices > "${run_dir}/ios_devices.log" 2>&1; then
    ios_result="DEVICE_QUERY_FAILED"
    return
  fi
  if ! xcrun devicectl device process launch --device "${ios_device}" "${bundle_id}" \
    --json-output "${run_dir}/ios_launch.json" \
    > "${run_dir}/ios_launch.log" 2>&1; then
    ios_result="LAUNCH_FAILED"
    return
  fi
  ios_result="LAUNCHED_MANUAL_BACKGROUND_REQUIRED"
}

run_simulation
if [ "${mode}" = "android" ] || [ "${mode}" = "both" ]; then run_android; fi
if [ "${mode}" = "ios" ] || [ "${mode}" = "both" ]; then run_ios; fi

printf 'TRIP_DEVICE_BACKGROUND_QA simulation=%s android=%s ios=%s batches=%s logs=%s\n' \
  "${simulation_result}" "${android_result}" "${ios_result}" "${batch_count}" "${run_dir}"
printf '%s\n' \
  'Interpretation: process survival is lifecycle evidence only. Start a real GPS trip, press Home on the iPhone, and drive the planned route for background GPS field evidence.' \
  > "${run_dir}/RESULT.txt"
