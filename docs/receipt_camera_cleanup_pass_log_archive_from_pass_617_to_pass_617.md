# Receipt Camera Cleanup Pass Log Archive - Pass 617

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap.

## Pass 617 - 21:39:59 EDT to active cleanup

Scope:
- Hardened native Android and iOS optional auto capture so shadow-risk or
  dirty-lens/haze readability guidance holds auto capture back.
- Added native `waiting_for_quality_review` status and mapped it to
  `manual_only_quality_review` diagnostics on both platforms.
- Kept manual capture available while preventing automatic capture from firing
  on frames that need user review.
- Added Android and iOS source-contract regressions for the new holdback.
- Recorded `BUG-RECEIPT-0138` under `camera_capture_quality`.

Verification:
- Passed targeted Dart analyzer for native auto-capture source-contract tests.
- Passed focused Flutter Android/iOS native auto-capture/settings regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

