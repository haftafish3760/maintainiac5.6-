# Receipt Camera Cleanup Pass Log Archive - Pass 368

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active cleanup
log under the 500-line file-size guard.

## Pass 368 - 11:58:00 EDT to 12:00:11 EDT

Scope:
- Hardened long-receipt continuation fixtures with exact merchant-name,
  line-description, line-category, line-family, and business-use expectations.
- Pinned top, middle, and bottom receipt sections so overlap rows and bottom
  totals cannot quietly drift while still asking for continuation when the
  bottom total is absent.
- Corrected continued-section merchant expectations to canonical `Lowe's`
  after strict QA confirmed the parser intentionally strips the `CONTINUED`
  marker.

Failures fixed during this pass:
- First long-receipt QA run failed the 100.0% threshold because the middle and
  bottom fixtures expected `Lowe's Continued` while production parsing returned
  canonical `Lowe's`. Updated the fixtures and reran green.

Verification:
- Passed `dart format`, long-receipt QA pack at 100.0%, full receipt QA at
  100.0% across 16 fixtures, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
