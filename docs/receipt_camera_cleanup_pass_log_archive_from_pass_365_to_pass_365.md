# Receipt Camera Cleanup Pass Log Archive - Pass 365

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 365 - 11:52:00 EDT to 11:54:35 EDT

Scope:
- Hardened the maintenance QA fixtures with exact merchant-name expectations,
  line-description needles, line categories, parser families, and business-use
  allocation checks.
- Pinned oil-change receipts so they must keep user-facing `Maintenance`
  categories while still routing through the vehicle-cost downstream family.
- Corrected the Take 5 exact-name expectation to the parser's more specific
  `Take 5 Oil Change` normalized merchant value after the first strict QA run.

Failures fixed during this pass:
- First maintenance QA run failed the 100.0% threshold because the new exact
  merchant expectation used `Take 5` while production parsing returned
  `Take 5 Oil Change`. Updated the fixture and reran green.

Verification:
- Passed `dart format`, maintenance QA pack at 100.0%, focused maintenance and
  material parser Flutter tests, full receipt QA at 100.0% across 16 fixtures,
  `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
