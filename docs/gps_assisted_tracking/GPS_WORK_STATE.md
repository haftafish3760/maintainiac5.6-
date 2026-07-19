# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 277
- Current objective: distinguish a live native collector from a stale GPS fix stream and surface recovery guidance
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `2de86a9c5` (GPS freshness health checkpoint pending)
- Latest validation result: affected controller/dashboard/engine tests plus static analysis green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: exercise platform lifecycle and battery behavior with authorized real-device evidence; keep calibration acceptance fail-neutral until persistence is deliberately designed
