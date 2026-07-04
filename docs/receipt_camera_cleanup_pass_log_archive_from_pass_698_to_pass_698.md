# Receipt Camera Cleanup Pass Log Archive - Pass 698

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 698 - 01:29:00 EDT to active cleanup

Scope:
- Fixed shared receipt capture defaults so materials-inventory and
  maintenance/repair launches use detailed-line review when no caller forces a
  review depth.
- Kept expenses and generic shared launches price-only by default, preserving
  the fast review path unless the caller or expense settings asks for details.
- Added a focused shared-flow regression guarding the module-specific review
  depth default and the existing attachment UI override path.
- Recorded `BUG-RECEIPT-0185` under `receipt_line_review_mode`.
- Archived Pass 638 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow.
- Passed focused Flutter receipt capture flow shareability regression.
