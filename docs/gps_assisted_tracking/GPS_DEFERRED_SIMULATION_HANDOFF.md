# Deferred GPS Simulation Handoff

Do not run this suite until simulation work is explicitly reassigned. Source,
contract, non-simulation regression, Android build, and iOS device-build work
are already validated separately.

Run the following deterministic suite as one bounded batch, capture only its
final log, and turn every failure into a focused regression before changing
production code:

```sh
flutter test \
  test/trip_tracking_simulation_test.dart \
  test/trip_tracking_simulator_false_positive_matrix_test.dart \
  test/trip_tracking_simulator_summary_test.dart \
  test/trip_tracking_benchmark_corpus_test.dart \
  test/trip_tracking_benchmark_reporter_test.dart \
  test/trip_tracking_deterministic_fuzz_test.dart \
  test/trip_tracking_fuzz_test.dart \
  test/trip_tracking_session_sampling_fuzz_test.dart
```

Do not interpret a green synthetic suite as real-device accuracy. Keep route
coordinates out of field evidence; use `GPS_FIELD_EVIDENCE_TEMPLATE.json` for
the coordinate-minimized comparison record after an authorized physical run.
