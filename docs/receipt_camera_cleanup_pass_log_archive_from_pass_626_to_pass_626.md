# Receipt Camera Cleanup Pass Log Archive - Pass 626

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 626 - 22:01:05 EDT to active cleanup

Scope:
- Renamed retired tap-focus telemetry counters to legacy tap-focus counters.
- Added regressions rejecting the old active tap-focus telemetry key names.
- Recorded `BUG-RECEIPT-0147` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused telemetry/source regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.
