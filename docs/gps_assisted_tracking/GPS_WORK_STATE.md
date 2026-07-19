# GPS Work State

- Current phase: 15 — platform battery and recovery hardening
- Current pass: 261
- Current objective: enforce the critical-battery GPS cutoff even when Flutter is suspended
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `1cdd51d3b` (critical-battery native enforcement pending checkpoint)
- Latest validation result: affected Dart analysis/tests, Android debug build, and iOS debug no-codesign build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: explicit reviewed calibration acceptance before any GPS adjustment can apply
