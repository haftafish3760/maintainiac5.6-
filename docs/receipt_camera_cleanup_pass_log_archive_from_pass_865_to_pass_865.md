# Receipt Camera Cleanup Pass Log Archive - Pass 865

Times are local to the development machine.

## Pass 865 - 12:29:00 EDT to active cleanup

Scope:
- Added an explicit iOS `continuous_focus_not_requested` diagnostic for
  non-continuous focus sessions instead of leaving `lastFocusStatus` as
  `not_used`.
- Pinned the iOS native bridge source regression for configured, unavailable,
  and not-requested focus-status families.
- Recorded `BUG-RECEIPT-0317` under `native_bridge`.
- Archived Pass 822 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused iOS native bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
