# Receipt Camera Cleanup Pass Log Archive - Pass 710

This file archives Pass 710 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 710 - 02:23:00 EDT to active cleanup

Scope:
- Tightened shared Flutter receipt help copy so it names continuous
  autofocus/readability guidance instead of generic continuous focus.
- Replaced first-use intro `flash, focus` wording with `flash, readability
  guidance` so the shared camera entry point does not imply a manual focus
  feature.
- Added help-flow source regressions for the updated copy and the retired
  generic focus phrase.
- Recorded `BUG-RECEIPT-0198` under `camera_capture_quality`.
- Archived Pass 652 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the receipt camera help flow.
- Passed focused receipt camera help flow regression.
- First cleanup log gate failed at 501 lines; archived Pass 653 and reran the
  gate before milestone push.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
