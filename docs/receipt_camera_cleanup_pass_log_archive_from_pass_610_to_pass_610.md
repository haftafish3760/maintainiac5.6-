# Receipt Camera Cleanup Pass Log Archive - Pass 610

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
camera cleanup log under the project line-count cap.

## Pass 610 - 21:20:25 EDT to active cleanup

Scope:
- Hardened OCR source handoff so marginal saved-photo lighting warnings
  (`brightness_assist_still_dim` and `dimmer_than_preview`) count as
  dark/exposure review risks instead of looking ready for OCR.
- Mirrored the same dim-light risk family into OCR diagnostic warning buckets.
- Added regression coverage proving dimmer receipt-photo handoff contracts now
  report `saved_dark_exposure_review` and the matching review action.
- Recorded `BUG-RECEIPT-0131` under `ocr_handoff_contract`.

Verification:
- Passed targeted Dart format/analyzer for OCR source handoff review,
  diagnostics helpers, and OCR service regressions.
- Passed focused Flutter OCR service and OCR source-quality regressions.
