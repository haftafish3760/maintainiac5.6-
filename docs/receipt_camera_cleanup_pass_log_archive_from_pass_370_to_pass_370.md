# Receipt Camera Cleanup Pass Log Archive - Pass 370

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 370 - 12:01:00 EDT to 12:03:30 EDT

Scope:
- Hardened the adjustment QA fixture with exact merchant-name, line-description,
  line-category, line-family, and business-use expectations.
- Fixed merchant header canonicalization so CVS receipt headers preserve the
  uppercase `CVS` brand token instead of normalizing to `Cvs`.
- Kept acronym canonicalization scoped to merchant headers so item-description
  casing remains stable for existing parser tests.

Failures fixed during this pass:
- First adjustment QA run failed the 100.0% threshold because production parsing
  returned `Cvs Pharmacy` while the stricter fixture expected `CVS Pharmacy`.
  Fixed merchant canonicalization and reran green.

Verification:
- Passed `dart format`, adjustment QA pack at 100.0%, focused parser
  line-amount and synthetic long-retail Flutter tests, full receipt QA at
  100.0% across 16 fixtures, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
