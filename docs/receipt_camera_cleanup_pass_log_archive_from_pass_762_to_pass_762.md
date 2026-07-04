# Receipt Camera Cleanup Pass Log Archive - Pass 762

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 762 - 04:41:45 EDT to active cleanup

Scope:
- Hardened Android and iOS previous-section ghost crop boundaries so malformed
  source start/height fractions cannot create unsafe overlap guide crops.
- Added local crop-boundary fallbacks in addition to session argument
  sanitization, preserving long-receipt continuation guidance if future call
  paths mutate the values.
- Added Android/iOS native ghost overlay source regressions for safe crop
  fractions.
- Recorded `BUG-RECEIPT-0250` under `multi_photo_ordering`.
- Archived Pass 734 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for ghost overlay regressions.
- Passed focused Android settings-quality and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
