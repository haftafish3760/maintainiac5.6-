# Receipt Camera Cleanup Pass Log Archive - Pass 137

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 137 - 05:00:15 EDT to 05:01:16 EDT

Scope:
- Added `tool/receipt_cleanup_log_gate.sh` to enforce the 500-line limit across
  the active receipt camera cleanup log and its archive files.
- Wired the log gate into `tool/receipt_quality_gate.sh` before the heavier
  source, QA runner, Flutter, and native compile gates.

Verification:
- `bash -n tool/receipt_cleanup_log_gate.sh tool/receipt_quality_gate.sh`
  passed.
- `bash tool/receipt_cleanup_log_gate.sh` passed with 11 log files and 125
  pass entries before this entry was added.
- `git diff --check` passed.
- Gate files remain under 500 lines:
  `receipt_cleanup_log_gate.sh` 35 lines and `receipt_quality_gate.sh` 18
  lines.

Known follow-up:
- Re-run the log gate after adding future pass entries; archive older active
  entries before the active log exceeds 500 lines.
