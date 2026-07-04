# Receipt Camera Cleanup Pass Log Archive - Pass 628

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap.

## Pass 628 - 22:04:55 EDT to active cleanup

Scope:
- Removed the public `onTapFocus` callback hook from the shared native receipt
  camera shell and preview controls.
- Added a source regression proving the tap-focus shell hook stays absent.
- Archived Pass 600 from the active cleanup log.
- Recorded `BUG-RECEIPT-0149` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused native shell/session regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

