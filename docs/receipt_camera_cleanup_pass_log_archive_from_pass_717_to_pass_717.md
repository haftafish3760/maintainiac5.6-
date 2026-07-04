# Receipt Camera Cleanup Pass Log Archive - Pass 717

This file archives Pass 717 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 717 - 02:39:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so native results cannot return more
  receipt photo paths than the session `maxSectionCount` allows.
- Added a focused regression where long-receipt mode is disabled but the native
  bridge returns two receipt paths.
- Recorded `BUG-RECEIPT-0205` under `multi_photo_ordering`.

Verification:
- Passed Dart format/analyzer for native section-count validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
