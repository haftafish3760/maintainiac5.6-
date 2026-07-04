# Receipt Camera Cleanup Pass Log Archive - Pass 687

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 687 - 00:45:35 EDT to active cleanup

Scope:
- Removed old focus-assist wording from blurry receipt quality guidance so the
  user-facing camera flow stays aligned with continuous autofocus as the primary
  product behavior.
- Added regression expectations that blurry receipt guidance names continuous
  autofocus and does not reintroduce focus-assist or tap-focus wording.
- Recorded `BUG-RECEIPT-0174` under `camera_capture_quality`.
- Archived Pass 616 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt photo quality guidance.
- Passed focused Flutter receipt camera quality guidance regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.
