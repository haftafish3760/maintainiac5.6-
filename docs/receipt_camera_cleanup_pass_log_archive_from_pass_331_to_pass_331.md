# Receipt Camera Cleanup Pass Log Archive - Pass 331

## Pass 331 - 10:56:00 EDT to 10:58:20 EDT

Scope:
- Split expense telemetry command-center map export out of
  `expense_screen_telemetry_health_snapshot_metrics.dart` into
  `expense_screen_telemetry_command_center_map.dart`.
- Split native camera, device capability, recovery, capture-source, and
  stitching command-center fields into
  `expense_screen_telemetry_command_center_native_map.dart`.
- Reduced `expense_screen_telemetry_health_snapshot_metrics.dart` from 435
  lines to 118 lines; the command map is 408 lines and the native camera map is
  103 lines.

Failures fixed during this pass:
- First source audit failed because the extracted command-center map was 502
  lines. Split the native camera/stitching section into its own part and reran
  the audit green.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused camera health,
  failure-actions, command-summary, and redaction-contract telemetry tests,
  source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
