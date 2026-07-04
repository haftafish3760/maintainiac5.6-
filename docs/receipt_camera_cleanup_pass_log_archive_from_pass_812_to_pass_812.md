# Receipt Camera Cleanup Pass Log Archive - Pass 812

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 812 - 12:20:00 EDT to active cleanup

Scope:
- Added sibling OCR source-quality regressions for generic glare and blur photo
  warning tokens.
- Pinned glare to `saved_glare_review`/`reduce_glare_or_retake` and blur to
  `saved_soft_blur_review`/`retake_hold_steady`, including parser task counts.
- Recorded `BUG-RECEIPT-0297` under `ocr_handoff_contract`.
- Archived Pass 780 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted source-quality format/analyzer and focused glare/blur service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
