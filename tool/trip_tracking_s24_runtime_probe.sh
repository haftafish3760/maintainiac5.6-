#!/usr/bin/env bash
set -euo pipefail

# Read-only evidence capture for an owner-started S24 field session. This
# script never launches Mainteniac, changes Android settings, clears logs, or
# reads coordinates. It verifies that Android's live system state agrees with
# the driver's visible in-app tracking state.

serial="${1:-}"
expect_active="${2:-}"
package_name="com.maintainiac"

if [[ -z "$serial" || ( -n "$expect_active" && "$expect_active" != "--expect-active" ) ]]; then
  echo "TRIP_RUNTIME_PROBE_FAIL usage: $0 <adb-serial> [--expect-active]"
  exit 64
fi

if ! adb -s "$serial" get-state >/dev/null 2>&1; then
  echo "TRIP_RUNTIME_PROBE_FAIL device_unavailable"
  exit 1
fi

package_dump="$(adb -s "$serial" shell dumpsys package "$package_name" 2>/dev/null || true)"
if [[ -z "$package_dump" ]]; then
  echo "TRIP_RUNTIME_PROBE_FAIL maintainiac_not_installed"
  exit 1
fi

location_mode="$(adb -s "$serial" shell settings get secure location_mode | tr -d '\r')"
service_dump="$(adb -s "$serial" shell dumpsys activity services "$package_name" 2>/dev/null || true)"
location_dump="$(adb -s "$serial" shell dumpsys location 2>/dev/null || true)"
notification_dump="$(adb -s "$serial" shell dumpsys notification --noredact 2>/dev/null || true)"

# Samsung retains historical request records in its location dump. Only the
# current requirements section is evidence that the app still owns an active
# provider request; do not let old drive data make a stopped collector pass.
current_location_dump="${location_dump%%SEC Dump for updateRequirements*}"
current_location_dump="${current_location_dump%%Historical Aggregate Location Provider Data:*}"

fine_location=false
if grep -q 'android.permission.ACCESS_FINE_LOCATION: granted=true' <<<"$package_dump"; then
  fine_location=true
fi

background_location=false
if grep -q 'android.permission.ACCESS_BACKGROUND_LOCATION: granted=true' <<<"$package_dump"; then
  background_location=true
fi

activity_recognition=false
if grep -q 'android.permission.ACTIVITY_RECOGNITION: granted=true' <<<"$package_dump"; then
  activity_recognition=true
fi

service_running=false
if grep -q 'TripTrackingForegroundService' <<<"$service_dump"; then
  service_running=true
fi

provider_request_active=false
if grep -Eq "ProviderRequest\\[[^]]*WorkSource\\{[^}]*${package_name}" <<<"$current_location_dump"; then
  provider_request_active=true
fi

tracking_notification_present=false
if grep -q "$package_name" <<<"$notification_dump"; then
  tracking_notification_present=true
fi

echo "location_services_enabled=$([[ "$location_mode" == "3" ]] && echo true || echo false)"
echo "fine_location_granted=$fine_location"
echo "background_location_granted=$background_location"
echo "activity_recognition_granted=$activity_recognition"
echo "trip_service_running=$service_running"
echo "maintainiac_provider_request_active=$provider_request_active"
echo "maintainiac_notification_present=$tracking_notification_present"

if [[ "$expect_active" == "--expect-active" &&
  ( "$location_mode" != "3" || "$fine_location" != true ||
    "$background_location" != true || "$service_running" != true ||
    "$provider_request_active" != true ) ]]; then
  echo "TRIP_RUNTIME_PROBE_FAIL active_collection_not_observed"
  exit 1
fi

echo "TRIP_RUNTIME_PROBE_PASS"
