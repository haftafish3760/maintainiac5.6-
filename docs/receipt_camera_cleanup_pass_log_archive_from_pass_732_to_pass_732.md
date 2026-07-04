# Receipt Camera Cleanup Pass Log Archive - Pass 732

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 732 - 03:23:50 EDT to active cleanup

Scope:
- Extended retired-control hardening from tap focus to focus, exposure, and
  white-balance lock enablement at the Dart service boundary.
- Hard-coded retired lock enablement fields false before native channel handoff.
- Added a service source-contract regression rejecting lock enablement derivation
  from session config.
- Recorded `BUG-RECEIPT-0223` under `native_bridge`.
- Archived Pass 707 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
