# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 290
- Current objective: fail closed when iOS background or precise-location authorization is revoked during active GPS tracking
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `0e5e7e6c3` (live GPS dashboard warnings)
- Latest validation result: iOS Swift syntax, targeted native policy/permission/controller tests, and unsigned iOS device build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: validate the iOS authorization-revocation behavior on the authorized physical device, then continue lifecycle and acquisition hardening
