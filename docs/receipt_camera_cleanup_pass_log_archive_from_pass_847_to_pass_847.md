# Receipt Camera Cleanup Pass Log Archive - Pass 847

Times are local to the development machine.

## Pass 847 - 12:00:00 EDT to active cleanup

Scope:
- Split ML Kit barcode format mapping out of the barcode scanner service into a
  focused part file.
- Kept the scanner service under the 500-line cap after the coverage-count
  hardening without changing behavior.
- Archived Pass 791 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
