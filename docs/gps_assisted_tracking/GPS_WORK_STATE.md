# GPS Work State

- Current phase: 15 — platform battery and recovery hardening
- Current pass: 262
- Current objective: require explicit current-evidence acceptance before GPS calibration can affect future projections
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `c2d1bfa35` (calibration acceptance hardening pending checkpoint)
- Latest validation result: affected Dart analysis/tests and controller regression tests green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: persist a privacy-safe calibration-acceptance record or keep conservative in-memory acceptance until settings storage supports it
