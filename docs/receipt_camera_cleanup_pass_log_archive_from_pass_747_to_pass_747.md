# Receipt Camera Cleanup Pass Log Archive - Pass 747

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 747 - 03:48:44 EDT to active cleanup

Scope:
- Hardened Android and iOS native receipt review-depth argument readers so
  snake-case, hyphenated, padded, or cased bridge values preserve prices-only
  versus detailed-line intent.
- Added native source regressions for both bridge argument readers.
- Recorded `BUG-RECEIPT-0235` under `native_bridge`.
- Archived Pass 722 from the active cleanup log to keep the doc under cap and
  removed a stale duplicate verification tail line.

Verification:
- Passed targeted Dart format/analyzer for native bridge review-depth tests.
- Passed focused Android/iOS native bridge UI contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
