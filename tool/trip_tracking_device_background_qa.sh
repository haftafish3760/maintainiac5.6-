#!/usr/bin/env bash
# Batched physical-device lifecycle evidence for Maintainiac trip tracking.
#
# Owns safe launch/background-resume checks, concise retained logs, and process
# liveness checks for this app only. It does not start a trip, change location
# permission, inject location, read coordinates, force-stop apps, or prove GPS
# accuracy. Android Home is a real background transition; iOS suspend/resume is
# explicitly a lifecycle probe, not proof of iOS background-location behavior.

set -u

bundle_id="com.maintainiac"
android_serial="${ANDROID_SERIAL:-R5CX14WC8FA}"
ios_device="${IOS_DEVICE:-robbies-iPhone.coredevice.local}"
mode="${1:-both}"
wait_seconds="${2:-20}"
run_stamp="$(date +%Y%m%d_%H%M%S)"
run_dir="/tmp/maintainiac_trip_device_background_${run_stamp}"

if [ "${wait_seconds}" -lt 5 ] || [ "${wait_seconds}" -gt 60 ]; then
  printf 'wait seconds must be between 5 and 60\n' >&2
  exit 64
fi
case "${mode}" in
  android|ios|both) ;;
  *)
    printf 'mode must be android, ios, or both\n' >&2
    exit 64
    ;;
esac

mkdir -p "${run_dir}"
printf '%s\n' \
  'Maintainiac GPS device lifecycle logs; no coordinates or route data captured.' \
  > "${run_dir}/README.txt"

android_result="NOT_REQUESTED"
ios_result="NOT_REQUESTED"

run_android() {
  if ! adb -s "${android_serial}" get-state > "${run_dir}/android_connection.log" 2>&1; then
    android_result="NOT_CONNECTED"
    return
  fi
  if ! adb -s "${android_serial}" shell am start -n "${bundle_id}/.MainActivity" \
    > "${run_dir}/android_launch.log" 2>&1; then
    android_result="LAUNCH_FAILED"
    return
  fi
  sleep 2
  adb -s "${android_serial}" shell pidof "${bundle_id}" \
    > "${run_dir}/android_foreground_pid.log" 2>&1 || true
  adb -s "${android_serial}" shell input keyevent HOME \
    > "${run_dir}/android_background_action.log" 2>&1 || true
  sleep "${wait_seconds}"
  adb -s "${android_serial}" shell pidof "${bundle_id}" \
    > "${run_dir}/android_background_pid.log" 2>&1 || true
  adb -s "${android_serial}" shell am start -n "${bundle_id}/.MainActivity" \
    > "${run_dir}/android_resume.log" 2>&1 || true
  sleep 2
  adb -s "${android_serial}" shell pidof "${bundle_id}" \
    > "${run_dir}/android_resume_pid.log" 2>&1 || true
  adb -s "${android_serial}" logcat -d -v epoch \
    | grep -Ei 'maintainiac|triptracking|trip_tracking' \
    > "${run_dir}/android_trip_logcat.log" || true
  if [ -s "${run_dir}/android_background_pid.log" ] && \
    [ -s "${run_dir}/android_resume_pid.log" ]; then
    android_result="PROCESS_SURVIVED_HOME"
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

if [ "${mode}" = "android" ] || [ "${mode}" = "both" ]; then run_android; fi
if [ "${mode}" = "ios" ] || [ "${mode}" = "both" ]; then run_ios; fi

printf 'TRIP_DEVICE_BACKGROUND_QA android=%s ios=%s logs=%s\n' \
  "${android_result}" "${ios_result}" "${run_dir}"
printf '%s\n' \
  'Interpretation: process survival is lifecycle evidence only. Start a real GPS trip, press Home on the iPhone, and drive the planned route for background GPS field evidence.' \
  > "${run_dir}/RESULT.txt"
