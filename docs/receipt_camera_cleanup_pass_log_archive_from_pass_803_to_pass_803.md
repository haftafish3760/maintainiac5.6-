# Receipt Camera Cleanup Pass Log Archive - Pass 803

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 803 - 09:31:00 EDT to active cleanup

Scope:
- Added explicit price-only versus detailed-line review mode fields to the
  pre-save assisted receipt line privacy-safe contract.
- Added business-use label parity so draft contracts match saved receipt line
  review contracts more closely.
- Added source regressions for draft review-mode and business-use labels.
- Recorded `BUG-RECEIPT-0287` under `receipt_line_review_mode`.
- Archived Pass 771 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused assisted-review source
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
