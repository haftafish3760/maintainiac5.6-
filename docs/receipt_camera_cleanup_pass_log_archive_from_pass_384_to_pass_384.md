# Receipt Camera Cleanup Pass Log Archive - Pass 384

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active pass log
under the 500-line gate.

## Pass 384 - 12:26:39 EDT to 12:28:30 EDT

Scope:
- Split parser-pack disclosure and install-choice value models out of
  `receipt_assistance_policy_parser_packs.dart` into
  `receipt_assistance_policy_parser_pack_models.dart`.
- Kept category pack routing, category labels, and route diagnostics in the
  parser-pack routing file.
- Reduced `receipt_assistance_policy_parser_packs.dart` from 285 lines to 164
  lines; the new parser-pack model part is 122 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt assistance
  footprint/install/parser-pack/data-saver Flutter tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
