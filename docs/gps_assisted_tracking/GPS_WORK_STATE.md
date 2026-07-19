# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 292
- Current objective: fail closed when iOS begins or continues GPS tracking after background or precise-location authorization changes
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `2f08a4af4` (iOS GPS permission recovery)
- Latest validation result: targeted native policy/permission tests plus unsigned iOS device and Android debug builds green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: validate the iOS authorization-revocation behavior on the authorized physical device, then continue lifecycle and acquisition hardening
