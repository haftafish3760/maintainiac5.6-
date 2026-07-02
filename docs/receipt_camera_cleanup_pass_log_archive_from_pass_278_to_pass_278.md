# Receipt Camera Cleanup Pass Log Archive

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line rule.

## Pass 278 - 09:35:39 EDT to 09:35:39 EDT

Scope:
- Split receipt photo coverage evidence parsing helpers out of
  `receipt_photo_coverage_decision.dart` into
  `receipt_photo_coverage_evidence_helpers.dart`.
- Updated the split `receipt_photo_coverage_decision_from_signals.dart` factory
  helper to call library-private evidence helpers directly instead of keeping
  private static parsing logic on the public decision model.
- Reduced `receipt_photo_coverage_decision.dart` from 176 lines to 30 lines;
  the factory helper remains 142 lines, labels remain 105 lines, and the new
  evidence helper part is 144 lines.

Failures fixed during this pass:
- An initial patch attempt used stale context from before Pass 277 had landed
  and was rejected without changing files. Re-read the current split files,
  adjusted the patch to the live part list, and continued.
- A standalone footprint command used the wrong tool filename and failed before
  changing files. Reran the correct `dart run
  tool/receipt_camera_footprint_audit.dart` command successfully.

Verification:
- Passed `dart format` on the touched receipt coverage model parts.
- Passed targeted `dart analyze` on the coverage model parts and focused
  coverage tests.
- Passed focused Flutter tests:
  `test/receipt_camera_coverage_decision_test.dart`,
  `test/receipt_camera_result_coverage_totals_test.dart`, and
  `test/receipt_camera_result_completion_coverage_test.dart`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`.
- Correct footprint audit still reports `total_receipt_camera_ocr_source` at
  1.75 MB.
