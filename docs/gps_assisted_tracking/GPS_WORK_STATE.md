# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 305
- Current objective: harden deterministic replay metrics and prevent late iOS Core Location callbacks from crossing retired GPS sessions
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `56b91a852` (GPS simulation benchmark reporting)
- Latest validation result: benchmark corpus/simulation/native controller regressions plus unsigned iOS device build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: extend distance-ground-truth replay coverage, then continue Android/iOS lifecycle and acquisition hardening
