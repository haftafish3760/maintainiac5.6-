# Receipt Camera Cleanup Pass Log Archive - Pass 443

Archived from the active cleanup pass log so
`docs/receipt_camera_cleanup_pass_log.md` stays under the 500-line cap.

## Pass 443 - 14:48:00 EDT to 14:52:04 EDT

Scope:
- Stayed on parser/review handoff quality.
- Added an assisted-review regression proving out-of-order OCR receipt sections
  route to long-receipt/capture guidance instead of generic parser review.
- Fixed `parserReviewRootCauseCode`, action label, and instruction routing so
  OCR section-order review outranks receipt math review.

Failures fixed during this pass:
- First focused test run failed because out-of-order sections were classified as
  `receipt_math_review`. Updated the root-cause routing to classify OCR
  section-order review as `capture_coverage_or_long_receipt`, then reran green.

Verification:
- Passed targeted format, analyzer, focused assisted-review parser test,
  focused source audit, and targeted diff check.
- Touched files remain under 500 lines:
  `expense_receipt_parse_diagnostics_review.dart` is 294 lines and
  `expense_receipt_parser_assisted_review_test.dart` is 417 lines.
