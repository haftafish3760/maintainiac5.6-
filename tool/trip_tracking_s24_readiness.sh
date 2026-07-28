#!/usr/bin/env bash
set -euo pipefail

serial="${1:-}"
expect_active="${2:-}"
package_name="com.maintainiac"

if [[ -z "$serial" || ( -n "$expect_active" && "$expect_active" != "--expect-active" ) ]]; then
  echo "TRIP_DEVICE_READINESS_FAIL usage: $0 <adb-serial> [--expect-active]"
  exit 64
fi

if ! adb -s "$serial" get-state >/dev/null 2>&1; then
  echo "TRIP_DEVICE_READINESS_FAIL device_unavailable"
  exit 1
fi

package_dump="$(adb -s "$serial" shell dumpsys package "$package_name" 2>/dev/null || true)"
if [[ -z "$package_dump" ]]; then
  echo "TRIP_DEVICE_READINESS_FAIL maintainiac_not_installed"
  exit 1
fi

location_mode="$(adb -s "$serial" shell settings get secure location_mode | tr -d '\r')"
permissions_ok=true
for permission in ACCESS_FINE_LOCATION FOREGROUND_SERVICE_LOCATION; do
  if ! grep -q "android.permission.${permission}: granted=true" <<<"$package_dump"; then
    permissions_ok=false
  fi
done

background_granted=false
if grep -q "android.permission.ACCESS_BACKGROUND_LOCATION: granted=true" <<<"$package_dump"; then
  background_granted=true
fi

activity_granted=false
if grep -q "android.permission.ACTIVITY_RECOGNITION: granted=true" <<<"$package_dump"; then
  activity_granted=true
fi

service_dump="$(adb -s "$serial" shell dumpsys activity services "$package_name" 2>/dev/null || true)"
service_running=false
if grep -q "TripTrackingForegroundService" <<<"$service_dump"; then
  service_running=true
fi

location_dump="$(adb -s "$serial" shell dumpsys location 2>/dev/null || true)"
current_location_dump="${location_dump%%SEC Dump for updateRequirements*}"
current_location_dump="${current_location_dump%%Historical Aggregate Location Provider Data:*}"
provider_request_active=false
if grep -Eq "ProviderRequest\[[^]]*WorkSource\{[^}]*${package_name}" <<<"$current_location_dump"; then
  provider_request_active=true
fi

echo "location_services_enabled=$([[ "$location_mode" == "3" ]] && echo true || echo false)"
echo "foreground_location_ready=$permissions_ok"
echo "background_location_granted=$background_granted"
echo "activity_recognition_granted=$activity_granted"
echo "trip_service_running=$service_running"
echo "maintainiac_provider_request_active=$provider_request_active"

if [[ "$location_mode" != "3" || "$permissions_ok" != true ]]; then
  echo "TRIP_DEVICE_READINESS_FAIL foreground_prerequisite_missing"
  exit 1
fi

if [[ "$background_granted" != true ]]; then
  echo "TRIP_DEVICE_READINESS_FAIL background_location_required_for_field_test"
  exit 1
fi

if [[ "$expect_active" == "--expect-active" &&
    ( "$service_running" != true || "$provider_request_active" != true ) ]]; then
  echo "TRIP_DEVICE_READINESS_FAIL service_running_without_provider_request"
  exit 1
fi

echo "TRIP_DEVICE_READINESS_PASS"
