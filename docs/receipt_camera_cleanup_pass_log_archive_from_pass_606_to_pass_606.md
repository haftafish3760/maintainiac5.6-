# Receipt Camera Cleanup Pass Log Archive - Pass 606

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 606 - 21:10:31 EDT to 21:11:41 EDT

Scope:
- Hardened long-receipt continuation handoff so uppercase or padded
  `missing_bottom_edge_and_totals` reason codes normalize before ghost guide
  fractions, continuation source, and bottom/totals flags are chosen.
- Added behavior coverage proving continuation guides keep the last prior
  section path and normalize the missing-bottom reason for expense flow
  options.
- Added source coverage requiring the shared flow diagnostics path to keep the
  lowercase normalization guard.
- Recorded `BUG-RECEIPT-0127` under `ghost_overlap_stitching`.
- Archived Pass 585 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed the first focused regression assertion after Dart formatting split the
  source expression across lines.
- Passed targeted Dart format/analyzer for continuation handoff code and tests.
- Passed focused Flutter continuation handoff and capture-flow recovery
  regressions.
