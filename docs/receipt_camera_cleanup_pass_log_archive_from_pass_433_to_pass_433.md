# Receipt Camera Cleanup Pass Log Archive - Pass 433

Archived from the active cleanup pass log so
`docs/receipt_camera_cleanup_pass_log.md` stays under the 500-line cap.

## Pass 433 - 14:30:45 EDT to 14:32:30 EDT

Scope:
- Stayed on quiet QA gate execution after adding `--summary-json`.
- Switched `tool/receipt_quality_gate.sh` to run the pure Dart receipt QA runner
  with `--summary-json` so the expensive gate reports compact counts and
  blockers instead of per-fixture detail.
- Tightened `receipt_quality_gate_contract_test.dart` so the gate must keep the
  perfect `--fail-under=1.0` threshold and compact summary output.

Verification:
- Passed `bash -n tool/receipt_quality_gate.sh`, targeted format/analyzer, and
  targeted diff check.
- Passed compact all-pack QA summary: 17 fixtures, 464 checks, 464 passed, 0
  failed, 0 blockers, no full `fixtures` key.
- Passed `flutter test test/receipt_quality_gate_contract_test.dart -r compact`.
