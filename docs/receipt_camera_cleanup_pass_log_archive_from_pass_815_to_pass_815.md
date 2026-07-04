# Receipt Camera Cleanup Pass Log Archive - Pass 815

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 815 - 12:42:00 EDT to active cleanup

Scope:
- Added a saved-photo shadow warning family for native `shadow_risk` captures.
- Wired shadow risk through review action labels, OCR source review status,
  source-quality action, and parser/admin diagnostics.
- Added focused regressions for saved shadow warning diagnostics and OCR source
  handoff contract.
- Recorded `BUG-RECEIPT-0300` under `camera_capture_quality`.
- Archived Pass 808 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted native warning/handoff format/analyzer and focused shadow
  warning plus handoff regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
