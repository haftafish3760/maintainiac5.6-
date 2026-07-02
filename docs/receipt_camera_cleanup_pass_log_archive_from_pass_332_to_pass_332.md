# Receipt Camera Cleanup Pass Log Archive - Pass 332

## Pass 332 - 10:55:47 EDT to 10:58:36 EDT

Scope:
- Split receipt-brain/install/local-only command-center fields out of
  `expense_screen_telemetry_command_center_map.dart` into
  `expense_screen_telemetry_command_center_receipt_brain_map.dart`.
- Kept the top-level command-center map as the privacy-safe aggregate export
  while moving the receipt-brain payload family behind
  `receiptBrainCommandCenterMap`.
- Reduced `expense_screen_telemetry_command_center_map.dart` to 302 lines; the
  new receipt-brain command-center map is 116 lines.

Coordination note:
- This work began as Pass 331, but another Codex thread claimed Pass 331 in
  the shared log during verification. This entry uses the next free pass number.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused command-summary,
  camera-health, and Firestore bridge telemetry tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
- Source audit reports 472 receipt-scope source files with no source files over
  500 lines; footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
