## Pass 139 - 05:34:00 EDT to 05:41:07 EDT

Scope:
- Added `tool/codex_rate_limit_probe.py`, an ADB-based helper that reads the
  Codex status sheet from the connected Galaxy S24 Ultra and logs context,
  5-hour, and 7-day rate-limit status without using Computer Use on the Mac app.
- Started the probe as a 15-minute background monitor writing to
  `/tmp/codex_rate_limit_monitor.log`.
- Generalized `test/receipt_qa_runner_contract_test.dart` so every
  subprocess-based QA runner contract test has a 2-minute timeout instead of
  relying on Flutter's 30-second default.
- Hardened receipt image source preparation so missing, empty, corrupt, and
  wrong-file-type OCR source images produce safe unreadable-source diagnostics
  instead of crashing during file read or image decode.

Failures fixed during this pass:
- The prior broad gate exposed a timeout in a focused receipt QA runner pack
  test. The root cause applied to all subprocess-based contract tests, so the
  timeout guard was applied to the whole family.
- The first unreadable-source regression showed empty image bytes can throw
  `RangeError` inside `image.decodeImage`; all image-processor decode sites now
  route through a safe decoder.
- A second focused run showed `qualityCheckFile` still had one raw decode path;
  that final path was moved to the safe decoder before accepting the pass.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed
  all 9 receipt QA runner contract tests after the timeout family fix.
- `python3 -m py_compile tool/codex_rate_limit_probe.py` passed, and a one-shot
  probe read `5h=78% left (resets 9:25 AM)` and `7d=71% left`.
- Focused image-source verification passed:
  `dart analyze` over the image processor and guard test,
  `flutter test test/receipt_image_ocr_source_guard_test.dart -r compact`,
  `dart run tool/maintainiac_source_audit.dart --include-tests` for the two
  touched files, and `git diff --check` for those files.
- Touched files remain under 500 lines:
  `receipt_image_processor.dart` 409 lines,
  `receipt_image_ocr_source_guard_test.dart` 112 lines,
  `receipt_qa_runner_contract_test.dart` 309 lines, and
  `codex_rate_limit_probe.py` 122 lines.

Known follow-up:
- Stitching already falls back on decode exceptions, but its image-read family
  can be tightened with explicit missing/empty/corrupt fixture coverage.
- The ADB rate-limit monitor depends on the phone staying unlocked, connected,
  and on the Codex thread.

## Archived Pass Logs

Older cleanup passes are archived by physical log order so this active log
stays under the 500-line file-size rule while preserving the evidence trail.

- From pass 093 to pass 013: `receipt_camera_cleanup_pass_log_archive_from_pass_093_to_pass_013.md`
- From pass 014 to pass 021: `receipt_camera_cleanup_pass_log_archive_from_pass_014_to_pass_021.md`
- From pass 022 to pass 028: `receipt_camera_cleanup_pass_log_archive_from_pass_022_to_pass_028.md`
- From pass 029 to pass 034: `receipt_camera_cleanup_pass_log_archive_from_pass_029_to_pass_034.md`
- From pass 035 to pass 046: `receipt_camera_cleanup_pass_log_archive_from_pass_035_to_pass_046.md`
- From pass 047 to pass 062: `receipt_camera_cleanup_pass_log_archive_from_pass_047_to_pass_062.md`
- From pass 063 to pass 074: `receipt_camera_cleanup_pass_log_archive_from_pass_063_to_pass_074.md`
- From pass 073 to pass 066: `receipt_camera_cleanup_pass_log_archive_from_pass_073_to_pass_066.md`
- From pass 109 to pass 094: `receipt_camera_cleanup_pass_log_archive_from_pass_109_to_pass_094.md`
- From pass 122 to pass 110: `receipt_camera_cleanup_pass_log_archive_from_pass_122_to_pass_110.md`
- From pass 126 to pass 123: `receipt_camera_cleanup_pass_log_archive_from_pass_126_to_pass_123.md`
- From pass 127 to pass 127: `receipt_camera_cleanup_pass_log_archive_from_pass_127_to_pass_127.md`
- From pass 130 to pass 128: `receipt_camera_cleanup_pass_log_archive_from_pass_130_to_pass_128.md`
- From pass 131 to pass 131: `receipt_camera_cleanup_pass_log_archive_from_pass_131_to_pass_131.md`
- From pass 132 to pass 132: `receipt_camera_cleanup_pass_log_archive_from_pass_132_to_pass_132.md`
- From pass 133 to pass 133: `receipt_camera_cleanup_pass_log_archive_from_pass_133_to_pass_133.md`
- From pass 134 to pass 134: `receipt_camera_cleanup_pass_log_archive_from_pass_134_to_pass_134.md`
- From pass 135 to pass 135: `receipt_camera_cleanup_pass_log_archive_from_pass_135_to_pass_135.md`
- From pass 136 to pass 136: `receipt_camera_cleanup_pass_log_archive_from_pass_136_to_pass_136.md`
- From pass 137 to pass 137: `receipt_camera_cleanup_pass_log_archive_from_pass_137_to_pass_137.md`
- From pass 138 to pass 138: `receipt_camera_cleanup_pass_log_archive_from_pass_138_to_pass_138.md`

## Active Passes
