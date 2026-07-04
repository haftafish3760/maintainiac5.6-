# Receipt Camera Cleanup Pass Log Archive - Pass 822

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 822 - 13:18:00 EDT to active cleanup

Scope:
- Classified `receipt_review_depth_*` OCR source document signals into explicit
  handoff counts and a `reviewDepthStatus`.
- Exposed price-only versus detailed-line camera intent in the privacy-safe OCR
  source handoff contract for downstream receipt review/admin diagnostics.
- Added focused OCR service regression coverage for detailed-line review-depth
  handoff.
- Recorded `BUG-RECEIPT-0307` under `receipt_line_review_mode`.
- Fixed a receipt PDF inspector compile failure found by the focused OCR service
  test by routing trailer-name checks through `AppPdfSecurityPolicy`.
- Recorded `BUG-RECEIPT-0308` under `qa_harness`.
- Archived Pass 815 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted review-depth handoff/PDF inspector format/analyzer and
  focused OCR service plus PDF inspector regressions.
