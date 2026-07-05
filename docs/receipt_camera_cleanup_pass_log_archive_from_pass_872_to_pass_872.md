# Receipt Camera Cleanup Pass Log Archive - Pass 872

This archive keeps older receipt camera cleanup pass entries outside the active
cleanup log so the active log stays under the project line-count cap.

## Pass 872 - 16:26:00 EDT to active cleanup

Scope:
- Hardened receipt section-order diagnostics for long-receipt retakes,
  inserted sections, manual reorder, and normal ghost-guided continuation.
- Added invalid families for retake offsets, context flag mismatches,
  previous/next context gaps, top-retake ghost mismatches, and insert offsets.
- Surfaced privacy-safe section-order review action codes, labels, metadata,
  and handoff counts so OCR cannot silently trust malformed ordering metadata.
- Added regression coverage for invalid retake context, top ghost mismatch,
  insert offset mismatch, and normal long-receipt ghost continuation.
- Recorded `BUG-RECEIPT-0321` under `multi_photo_ordering`.
- Archived Pass 799 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
