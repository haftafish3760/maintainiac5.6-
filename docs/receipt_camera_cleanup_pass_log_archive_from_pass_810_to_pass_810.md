# Receipt Camera Cleanup Pass Log Archive - Pass 810

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 810 - 12:08:00 EDT to active cleanup

Scope:
- Hardened OCR source handoff classification for saved photo quality warnings.
- Mapped generic dark/glare/blur `photo_quality_*` warning tokens into the same
  review families as native saved-photo and OCR-source action risks.
- Added a service regression proving a too-dark saved receipt produces
  `saved_dark_exposure_review` and the retake/raise-brightness action.
- Recorded `BUG-RECEIPT-0295` under `ocr_handoff_contract`.
- Archived Pass 778 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR source-quality format/analyzer and focused service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
