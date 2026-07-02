# Receipt Camera Cleanup Pass Log Archive - Pass 366

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 366 - 11:55:00 EDT to 11:56:52 EDT

Scope:
- Hardened noisy OCR fixtures with exact merchant-name expectations,
  line-description needles, line categories, parser families, and business-use
  allocation checks.
- Covered swapped date/total characters, noisy Shell fuel totals, Home Depot
  letter-number swaps, and truncated material rows.
- Corrected Home Depot exact-name expectations to the parser's canonical
  `The Home Depot` value after the first strict noisy QA run.

Failures fixed during this pass:
- First noisy QA run failed the 100.0% threshold because Home Depot fixtures
  expected `Home Depot` while production parsing returned `The Home Depot`.
  Updated the fixtures and reran green.

Verification:
- Passed `dart format`, noisy QA pack at 100.0%, full receipt QA at 100.0%
  across 16 fixtures, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
