# Receipt Camera Cleanup Pass Log Archive - Pass 132

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 132 - 04:44:58 EDT to 04:49:12 EDT

Scope:
- Wired `tool/receipt_quality_gate.sh` to call the stronger
  `tool/receipt_camera_pipeline_gate.sh`.
- Removed the now-duplicated standalone native camera contract test from the
  final receipt-quality smoke block because the camera pipeline gate already
  covers it.
- Kept the remaining OCR service and receipt processing contract smoke tests
  outside the camera pipeline gate so receipt contract regressions still fail
  the broader quality gate.

Verification:
- `bash -n tool/receipt_quality_gate.sh tool/receipt_camera_pipeline_gate.sh`
  passed.
- `bash tool/receipt_quality_gate.sh` passed end to end after the wiring
  change, including the receipt QA runner, camera/OCR pipeline gate, Android
  compile gate, and final OCR/processing contract smoke tests.
- `git diff --check` passed.
- Gate scripts remain small:
  `receipt_quality_gate.sh` 17 lines and `receipt_camera_pipeline_gate.sh`
  58 lines.

Known follow-up:
- Keep using the full receipt quality gate after gate-script changes or broad
  receipt pipeline changes; use the narrower camera pipeline gate for focused
  camera/OCR changes.
