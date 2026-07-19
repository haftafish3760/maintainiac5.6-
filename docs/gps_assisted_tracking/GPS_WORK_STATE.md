# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 275
- Current objective: retain the critical-battery explanation when native startup returns either success or failure after shutdown
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `e46737cf3` (critical battery false-start regression checkpoint pending)
- Latest validation result: affected controller, native-error, and battery policy tests plus static analysis green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: exercise platform lifecycle and battery behavior with authorized real-device evidence; keep calibration acceptance fail-neutral until persistence is deliberately designed
