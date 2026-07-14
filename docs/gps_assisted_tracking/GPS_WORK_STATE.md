# GPS Work State

- Current phase: 7 — validation, filtering, and recovery hardening
- Current pass: 88
- Current objective: harden native-source integrity and deterministic recovery
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `ed005ea4b` (working GPS changes not yet checkpointed)
- Latest validation result: 149 targeted GPS/odometer/Firebase tests, 24 Firebase emulator rules tests, affected analysis, Android debug build, and iOS device build green
- Unresolved blockers: real Android/iOS route and battery evidence not yet collected; authenticated organization upload remains unverified
- Recent hardening: native samples more than two minutes ahead of the wall clock
  are rejected without changing anchors or mileage; Firebase retries cannot use
  a stale signed-out UID; reviewed-mileage cloud backup is explicitly opt-in
  and local-only when disabled; cloud flushes are serialized and missing
  organization configuration fails closed and remains a durable retryable
  state; iOS maps requested sampling intervals to Core Location accuracy tiers
  instead of forcing the highest-accuracy mode; iOS simulated-location source
  flags now enter the same fail-closed filter as Android mock-location signals;
  Firebase backup settings now expose sign-in state without coupling sign-in to
  backup consent.
- Next action: authenticated org-backed upload and real-device route validation
