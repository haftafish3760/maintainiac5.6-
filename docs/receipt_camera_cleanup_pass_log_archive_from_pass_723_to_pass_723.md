# Receipt Camera Cleanup Pass Log Archive - Pass 723

This file archives Pass 723 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 723 - 02:54:10 EDT to active cleanup

Scope:
- Retired dormant Android and iOS native tap-to-focus gesture paths so legacy
  flags cannot bring manual tap focus back into the receipt camera.
- Kept pinch zoom, brightness/exposure, continuous focus, and readability
  guidance as the active receipt-camera control model.
- Tightened native control readiness so tap/manual focus lock diagnostics report
  retired controls instead of becoming ready if a stale flag flips.
- Added Android/iOS bridge regressions that reject `FocusMeteringAction`,
  `UITapGestureRecognizer`, tap focus point metering, and tap-suppression
  zoom baggage in active native camera sources.
- Recorded `BUG-RECEIPT-0212` under `camera_capture_quality`.
- Fixed stale Android import-hygiene expectations for the legitimate Camera2
  interop imports used by continuous autofocus and the UUID import used by
  native unique receipt filenames.
- Recorded `BUG-RECEIPT-0213` under `qa_harness`.
- Archived Pass 696 from the active cleanup log to keep the doc under cap.

Verification:
- First focused native bridge run failed because manual focus-lock assertions
  still expected the retired tap-focus path; fixed those assertions before
  continuing.
- Second focused batch failed because Android import hygiene did not include
  legitimate Camera2 continuous-focus interop imports; the follow-up focused
  import-hygiene run also exposed the missing UUID import for native unique
  receipt filenames. Fixed both before continuing.
- Passed targeted Dart format/analyzer and focused native bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
