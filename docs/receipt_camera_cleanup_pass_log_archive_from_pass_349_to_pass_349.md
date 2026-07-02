# Receipt Camera Cleanup Pass Log Archive - Pass 349

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line rule.

## Pass 349 - 11:25:20 EDT to 11:29:50 EDT

Scope:
- Hardened pure Dart receipt QA mismatch output for line-family and line-use
  regressions.
- `production_parser_line_families_mismatch` and
  `production_parser_line_uses_mismatch` now include expected and actual line
  sequences instead of vague mismatch labels.
- Added a QA runner contract guard so those expected/actual diagnostics cannot
  be silently removed.

Verification:
- Passed `dart format`, targeted `dart analyze`, full receipt QA at 100.0%,
  focused QA runner contract tests, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
