# Receipt Camera Cleanup Pass Log Archive - Pass 614

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap.

## Pass 614 - 21:33:08 EDT to active cleanup

Scope:
- Removed remaining active product-doc wording that described tap-focus as part
  of the expected receipt camera flow.
- Replaced those docs with continuous autofocus, readability guidance,
  brightness/glare checks, and sharpness-focused real-device expectations.
- Updated Command Center soft-blur recovery action copy so it tells reviewers
  to trust continuous focus/readable text, not ask users to tap receipt text.
- Added focused telemetry regression coverage proving soft-blur guidance keeps
  continuous focus primary and rejects tap-focus wording.
- Recorded `BUG-RECEIPT-0135` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for telemetry soft-blur recovery copy.
- Passed focused Flutter telemetry photo-recovery action regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

