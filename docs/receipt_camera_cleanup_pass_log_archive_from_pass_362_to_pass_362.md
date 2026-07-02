# Receipt Camera Cleanup Pass Log Archive - Pass 362

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active cleanup
log under the 500-line file-size guard.

## Pass 362 - 11:48:00 EDT to 11:51:21 EDT

Scope:
- Hardened fuel QA fixtures with exact merchant-name, line-description,
  line-category, line-family, and business-use expectations.
- Fixed receipt adjustment parser-family classification so negative coupon,
  discount, and rewards lines report `receipt_adjustment` instead of generic
  expense while keeping their `Receipt Adjustment` category.
- Updated the existing adjustment QA fixture to guard the same parser-family
  behavior across retail coupons and store discounts.

Failures fixed during this pass:
- The first fuel QA run exposed a parser-family mismatch on the Pilot rewards
  discount line. It was categorized as `Receipt Adjustment` but still carried
  the `general_expense` parser family. Fixed the family mapping and reran the
  focused and full guards green.

Verification:
- Passed `dart format`, focused fuel and adjustment QA packs at 100.0%, focused
  parser line-amount/fuel-format Flutter tests, full receipt QA at 100.0% across
  16 fixtures, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
