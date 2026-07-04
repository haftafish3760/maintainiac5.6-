# Receipt Camera Cleanup Pass Log Archive - Pass 690

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 690 - 00:50:48 EDT to active cleanup

Scope:
- Hardened directly constructed selected receipt line references so malformed
  business/personal percentages cannot publish non-finite or overallocated
  split totals.
- Made business use the source of truth for selected-line allocation and made
  split personal percent the complement of the clamped business percent.
- Added regression coverage for overallocated and non-finite selected-line
  split allocations.
- Recorded `BUG-RECEIPT-0177` under `business_personal_split`.
- Archived Pass 629 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for selected receipt line allocation.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.
