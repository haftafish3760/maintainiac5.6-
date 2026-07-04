# Receipt Camera Cleanup Pass Log Archive - Pass 776

## Pass 776 - 06:10:03 EDT to active cleanup

Scope:
- Hardened attachment-panel picked-photo review so existing receipt capture
  diagnostics are preserved when newly picked photos are added to review.
- Merged existing `_photoCaptureDiagnosticsByPath` with new pick diagnostics,
  matching the existing quality-check merge behavior.
- Added a source regression proving both existing and new diagnostics are passed
  into `ReceiptPhotoReviewScreen`.
- Recorded `BUG-RECEIPT-0263` under `camera_review_state`.
- Archived Pass 748 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for attachment diagnostics handoff.
- Passed focused Flutter attachment recovery contract regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
