# Receipt Camera Cleanup Pass Log Archive - Pass 766

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 766 - 05:21:09 EDT to active cleanup

Scope:
- Hardened capture-flow previous-section diagnostics so direct malformed ghost
  fractions cannot produce non-finite metadata or throwing slice-percent math.
- Bounded source, overlay, height, and opacity fractions to 0..1 with malformed
  values falling back to zero before diagnostics are emitted.
- Added a source regression preventing raw ghost-height option rounding from
  returning to the diagnostics helper.
- Recorded `BUG-RECEIPT-0254` under `multi_photo_ordering`.
- Archived Pass 738 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture-flow diagnostics changes.
- Fixed the initial source-regression assertion mismatch caused by Dart format
  splitting the slice-percent expression across lines.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates. The first
  source-audit attempt raced another `dart run` audit on native asset setup;
  the same audit passed when rerun by itself.
