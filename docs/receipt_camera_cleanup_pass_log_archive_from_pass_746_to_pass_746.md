# Receipt Camera Cleanup Pass Log Archive - Pass 746

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 746 - 03:47:31 EDT to active cleanup

Scope:
- Hardened native receipt review-depth diagnostics so snake-case or hyphenated
  bridge values preserve prices-only versus detailed-line intent.
- Added focused regression coverage for `prices-only` and `detailed_lines`
  native review-depth payloads.
- Recorded `BUG-RECEIPT-0234` under `receipt_line_review_mode`.
- Archived Pass 721 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native review-depth diagnostics.
- Passed focused receipt camera result frozen metadata regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
