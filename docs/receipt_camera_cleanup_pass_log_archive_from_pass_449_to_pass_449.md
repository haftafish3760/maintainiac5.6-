# Receipt Camera Cleanup Pass Log Archive - Pass 449

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 449 - 15:32:40 EDT to 15:39:32 EDT

Scope:
- Stayed on pure Dart receipt QA hardening for the contractor-supply release
  gate without entering the separate inventory parser/catalog lane.
- Split focused pack checks out of `receipt_qa_runner_contract_test.dart` into
  `receipt_qa_runner_pack_focus_test.dart` so QA contracts stay under 500 lines.
- Added `receipt_qa_runner_pack_focus_test.dart` to `tool/receipt_quality_gate.sh`
  and updated its contract test.
- Added a `contractor_supply` QA fixture pack covering home-center material
  quantities/packs and split OCR material description rows.
- Updated runner contracts so the contractor-supply pack and fixture names cannot
  be silently removed.

Failures fixed during this pass:
- First format wrapper failed because the shell gate script was accidentally
  passed to `dart format`; reran formatting on Dart files only and checked the
  shell gate with `bash -n`.

Verification:
- Passed targeted format, analyzer, and `bash -n tool/receipt_quality_gate.sh`.
- Passed `dart run tool/receipt_qa_runner.dart --pack=contractor_supply
  --fail-under=1.0 --summary-json`.
- Passed focused contract tests for the QA runner, pack-focus suite, and receipt
  quality gate contract.
- Passed full pure Dart runner summary with 27 fixtures, 715 checks, 715 passed,
  and 0 failed.
- Passed targeted source audit and `git diff --check`.
- Touched files remain under 500 lines.
