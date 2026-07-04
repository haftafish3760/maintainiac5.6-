# Receipt Camera Cleanup Pass Log Archive - Pass 736

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 736 - 03:28:54 EDT to active cleanup

Scope:
- Audited native capture staging fixtures for retired lock diagnostics.
- Replaced stale locked focus/exposure/white-balance fixture state with
  continuous/auto/not-requested diagnostics.
- Updated manifest and recovery-index expectations so staged diagnostics keep
  retired lock attempts at zero.
- Recorded `BUG-RECEIPT-0227` under `qa_harness`.
- Archived Pass 711 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native capture staging fixtures,
  manifest expectations, index expectations, and staging regression.
- Passed focused Flutter native capture staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
