# Receipt Camera Cleanup Pass Log Archive - Pass 321

## Pass 321 - 10:42:20 EDT to 10:45:17 EDT

Scope:
- Split parser telemetry metadata out of
  `expense_receipt_entry_telemetry_actions.dart` into
  `expense_receipt_entry_parser_telemetry_metadata.dart`.
- Kept the telemetry event routing, category bucket helpers, privacy token
  helpers, suggested-category action, and receipt-brain handoff diagnostics in
  the original telemetry actions part.
- Reduced `expense_receipt_entry_telemetry_actions.dart` from 404 lines to 229
  lines; the new parser telemetry metadata part is 184 lines.

Failures fixed during this pass:
- The first extraction left category/review/confidence bucket maps out of the
  helper signature; passed those maps explicitly.
- A focused source-contract assertion expected a full sentence as one raw source
  string while the source used adjacent Dart string literals. Tightened it to
  assert the protected sentence fragments and reran.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused telemetry and
  assisted-review parser-guidance tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
