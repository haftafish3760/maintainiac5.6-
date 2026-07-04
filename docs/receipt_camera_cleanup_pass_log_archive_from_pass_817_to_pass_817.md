# Receipt Camera Cleanup Pass Log Archive - Pass 817

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 817 - 11:41:00 EDT to active cleanup

Scope:
- Carried backup scanner and phone-camera fallback risk tokens through the OCR
  source handoff summary.
- Added `backup_capture_review` with a crop/focus/totals review action so
  fallback-source warnings do not collapse back to generic scanner prep.
- Added parser task-count diagnostics for backup scan crop review and phone
  backup focus review.
- Added a focused OCR service regression for the backup capture review family.
- Recorded `BUG-RECEIPT-0302` under `ocr_handoff_contract`.
- Archived Pass 810 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR source handoff format/analyzer and focused backup
  capture review regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
