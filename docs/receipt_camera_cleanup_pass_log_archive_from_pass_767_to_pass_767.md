# Receipt Camera Cleanup Pass Log Archive - Pass 767

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 767 - 05:32:59 EDT to active cleanup

Scope:
- Hardened shared camera review opening so continuation flows clamp the
  requested selected index within the newly staged photo set before offsetting
  by pre-existing photos.
- Prevented negative or oversized `initialSelectedIndex` values from selecting
  an older receipt photo instead of the newly captured section.
- Added a source regression for the review-opening index helper.
- Recorded `BUG-RECEIPT-0255` under `camera_review_state`.
- Archived Pass 739 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for review-opening index changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
