<!--
GPS-assisted trip-tracking physical field protocol.

Owns repeatable owner-driven evidence for Android and iOS trip tracking.
Does not declare road accuracy, modify trips, or replace automated regression.
Consumed by the owner and GPS pass ledger after signed device builds are ready.
-->

# GPS-assisted trip-tracking field route protocol

## Purpose

This protocol validates one real, short route per phone. It is deliberately
separate from synthetic stress tests: a green simulation proves deterministic
logic only, while this route supplies device, permission, background, GPS, and
human-review evidence.

The route is designed for the planned John Deere Gator 560e drive around a
one-to-two-mile area: drive, stop, get out and walk, then drive again.

## Before each phone

1. Test Android and iPhone separately. Never let both phones create trips for
   the same drive.
2. Record the vehicle's physical odometer to the nearest tenth of a mile.
3. Confirm the correct work profile and vehicle are shown on the dashboard.
4. Confirm device Location Services are on and the phone has charge.
5. Keep the phone with a clear view of the sky when practical. Do not use
   airplane mode, mock locations, or a simulator for this route.
6. Start the device lifecycle script before or after the route only for its
   labeled process-survival evidence; it does not start a trip or prove GPS:

   ```sh
   ./tool/trip_tracking_device_background_qa.sh both 20
   ```

## Start and permission evidence

1. On the Maintainiac dashboard, choose **Start Day**.
2. Enter the physical odometer reading when the app asks for it. This remains
   the canonical mileage baseline.
3. If the system presents a location prompt, the owner taps the appropriate
   choice. For a background route, grant the platform's background-capable
   option only when the owner is comfortable doing so:
   - iPhone: the system may first grant foreground access and later offer
     **Always** access; background behavior must be tested only after the
     system reports the selected access.
   - Android: use the system's location flow and any required notification or
     background-location access. Do not treat a permission sheet as proof that
     the native provider is live.
4. Wait for the dashboard to progress from **GPS STARTING** or **GPS
   ACQUIRING** to **LIVE GPS**. Do not begin the measurement route while it is
   still starting.
5. Record the displayed live odometer tenths and the time. A live projection
   is advisory; it must not replace the confirmed physical odometer.

## Route sequence

Perform the following sequence once per phone, preserving the order:

1. Drive for roughly 0.3–0.5 mile.
2. Pull over safely, leave the vehicle, and walk around for 2–4 minutes.
3. Return to the vehicle and drive for another roughly 0.3–0.5 mile.
4. Stop at a distinct safe location for 3–5 minutes. Do not end the trip just
   because the vehicle is stopped.
5. Drive the remaining route back toward the starting area.

During the route, note only these non-sensitive facts: start time, each stop
time, whether GPS status changed, whether the app stayed responsive, and the
physical ending odometer. Do not upload route coordinates, customer addresses,
or Bluetooth hardware identifiers to source control.

## Background checks

After **LIVE GPS** has been displayed and while the vehicle is safely stopped:

1. Put the phone on its Home screen for at least 60 seconds.
2. Reopen Maintainiac and verify the active workday still exists.
3. Continue the route only if the app shows a recoverable GPS state. If it
   reports a permission, provider, or degraded state, preserve that result for
   diagnosis rather than repeatedly restarting the day.
4. On iPhone, the owner must perform the Home gesture/button action. Build or
   install tooling cannot prove an iOS background transition.

## End-of-day review

1. End the trip through the normal user flow.
2. Compare the physical ending odometer with the app's proposed GPS evidence.
3. Verify that the user can correct or confirm the final TripLog result.
4. Verify that walking did not create vehicle mileage and that stops remain
   visible/reviewable rather than automatically finalizing the trip.
5. Record whether the route includes measured, estimated-gap, or rejected GPS
   evidence. The app must never silently bridge a signal gap as measured route
   distance.

## Pass criteria and escalation

The route is a passing field subset only when all of these are true:

- exactly one local tracking session existed;
- the correct vehicle stayed associated with the session;
- native status did not show live GPS before provider evidence;
- background/reopen preserved or safely recovered the session;
- walking did not accumulate vehicle mileage;
- a stationary stop did not auto-finalize the day;
- the user retained final TripLog and odometer review control.

If any criterion fails, stop the route, keep the trip reviewable, note the
timestamp and displayed status, and report the retained device-script log
directory. Do not delete the trip, rewrite the odometer, or retry until the
failure has a named regression case.
