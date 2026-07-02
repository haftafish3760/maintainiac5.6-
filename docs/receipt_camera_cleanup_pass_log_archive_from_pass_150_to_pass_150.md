# Receipt Camera Cleanup Pass Log Archive - Pass 150

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 150 - 06:01:03 EDT to 06:03:11 EDT

Scope:
- Hardened `tool/receipt_cleanup_log_gate.sh` so duplicate pass numbers across
  the active cleanup log and archive files fail the gate.
- Kept the existing 500-line log cap and minimum-entry checks.
- Archived Pass 135 before logging so the active pass log stays under the
  500-line rule.

Verification:
- Focused duplicate-pass guard verification passed:
  `bash tool/receipt_cleanup_log_gate.sh`,
  `bash tool/receipt_fast_guard_gate.sh`, focused source audit, and
  `git diff --check`.
- The fast guard also ran the camera I/O guard and reported:
  `Receipt camera I/O guard passed.`
- Touched files remain under 500 lines:
  `receipt_cleanup_log_gate.sh` 49 lines and
  `receipt_fast_guard_gate.sh` 20 lines.

Known follow-up:
- Keep pass numbers strictly monotonic in the active log; if another process
  lands a pass first, use the next available number rather than renumbering.
