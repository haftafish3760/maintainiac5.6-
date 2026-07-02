# Receipt Camera Cleanup Pass Log Archive - Pass 359

## Pass 359 - 11:42:20 EDT to 11:46:29 EDT

Scope:
- Added optional exact merchant-name expectations to the pure Dart receipt QA
  runner.
- Applied exact `Target` merchant guards to both mixed business/personal retail
  fixtures so merchant normalization drift cannot hide behind broad needle
  matching.
- Added the `merchant_name_matched` QA check to the runner contract.

Verification:
- Passed `dart format`, targeted `dart analyze`, retail QA pack, full receipt
  QA at 100.0%, focused QA runner contract tests, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
