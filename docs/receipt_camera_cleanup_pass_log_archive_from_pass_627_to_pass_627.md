# Receipt Camera Cleanup Pass Log Archive - Pass 627

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 627 - 22:02:52 EDT to active cleanup

Scope:
- Renamed the retired tap-focus enabled telemetry counter to
  `legacyTapFocusEnabledCount`.
- Added a source regression rejecting the old active key name.
- Archived Pass 599 from the active cleanup log.
- Recorded `BUG-RECEIPT-0148` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused OCR-source handoff source regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.
