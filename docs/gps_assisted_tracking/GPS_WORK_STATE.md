# GPS Work State

- Current phase: 16 — platform event isolation and real-device evidence hardening
- Current pass: 440
- Current objective: preserve the GPS-only advisory boundary while hardening recovery and live-projection behavior
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `cd57db4af` (GPS consent persistence guidance)
- Latest validation result: targeted consent-persistence regression green; bundled recovery gate exposed and repaired a legacy guidance assertion
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: continue Android/iOS lifecycle and acquisition hardening; collect authorized physical-device evidence
