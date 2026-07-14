# GPS-Assisted Trip Tracking Real-Device Protocol

Simulations and builds do not establish field accuracy. Capture one record per
run for Android and iOS: device/OS/app version, tracking preset, profile,
starting and ending odometer, route type, battery start/end, foreground and
locked-background duration, signal interruptions, expected stops, detected
advisories, GPS distance, confirmed odometer delta, and any user correction.

Run at least these scenarios before making production claims:

1. City driving with several traffic lights and no exit from the vehicle.
2. Drive, park, walk away from the vehicle, return, and resume driving.
3. Highway driving, including a tunnel or deliberate signal-loss interval when
   safe.
4. Low-speed lawn-equipment or work-site movement using that profile.
5. A two-hour background/locked-screen run using each battery preset.

For every run, export only coordinate-minimized diagnostic counters unless the
tester deliberately approves a private route fixture. Promote a field run to a
regression fixture only after removing personal locations and recording its
expected distance, stop, gap, and health outcomes.
