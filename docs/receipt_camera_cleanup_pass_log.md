# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 481 - 23:43:00 EDT to 23:45:51 EDT

Scope:
- Added the receipt-line foundation for numbered review modes.
- Extended `ExpenseReceiptLineRecord` with receipt display line numbering,
  price-only versus detailed-line review mode labels, business/personal/split
  review labels, review summaries, and privacy-safe line review contracts.
- Preserved allocation-only behavior for users who only care about the price
  and business/personal/split allocation while detailed lines keep item detail.
- Added model and parser regressions proving parsed receipt lines expose line
  numbers and that allocation-only price lines do not leak item text in
  privacy-safe metadata.

Verification:
- Passed targeted Dart format and analyzer for the expense line model,
  serialization, and focused line/parser tests.
- Passed focused Flutter tests for `test/expense_receipt_line_record_test.dart`
  and `test/expense_receipt_parser_business_personal_test.dart`.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 480 - 23:23:00 EDT to 23:42:22 EDT

Scope:
- Stayed on the camera post-capture review loop.
- Wired selected-photo capture-readiness diagnostics into the review context row
  and preview status copy so the app can tell the user when a receipt looked
  steady, when framing should be checked, or when a manual/early capture needs
  sharpness review.
- Kept the guidance advisory only: Retake, Add Another Photo, and Next/Use
  Receipt remain user-controlled.
- Added a regression to the receipt photo review quality handoff test to keep
  the readiness copy and selected diagnostics wiring in place.

Verification:
- Passed targeted Dart format and analyzer for the review controls, readiness
  copy, preview status, and focused review handoff test.
- Passed focused Flutter test
  `test/receipt_photo_review_quality_handoff_test.dart`.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 479 - 21:55:00 EDT to 21:59:49 EDT

Scope:
- Stayed on the clear-photo review/result layer.
- Added direct `ReceiptPhotoReviewResult` getters for capture-readiness counts,
  manual-capture-allowed count, and auto-capture-allowed count.
- Kept the existing native UI health and receipt-reader handoff counts intact,
  while giving UI, telemetry, and admin diagnostics a simpler way to read the
  photo readiness state.
- Added a regression to the native quality result test proving the readiness
  summary survives as direct result data.

Verification:
- Passed targeted Dart format and analyzer for the native signals result helper
  and focused native quality test.
- Passed focused Flutter test `test/receipt_camera_result_native_quality_test.dart`.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 478 - 21:45:00 EDT to 21:54:41 EDT

Scope:
- Stayed on the clear-photo native staging path.
- Added a permanent staging regression proving capture-readiness diagnostics
  survive from native capture into staged photo diagnostics, recovery manifest,
  and recovery index.
- Covered readiness code, readiness label, manual capture allowance, stable
  frame count, and required stable frames.
- Kept the privacy guard in the same path proving private receipt text is not
  retained in safe diagnostics.

Verification:
- Passed targeted Dart format and analyzer for the native staging test/helpers.
- Passed focused Flutter test `test/receipt_native_capture_staging_test.dart`.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 477 - 21:36:00 EDT to 21:44:08 EDT

Scope:
- Stayed on the release-one clear-photo camera lane.
- Added native Android and iOS capture-readiness diagnostics using the same
  shared Flutter keys as the review pipeline: readiness code, readiness label,
  manual capture allowed, stable frame count, and required stable frames.
- Kept manual capture represented as available while auto-capture stays
  advisory and opt-in.
- Whitelisted the new readiness diagnostics in native capture staging so the
  values survive the trip into Flutter review/handoff.
- Added Android and iOS bridge regressions proving the native camera contracts
  carry the readiness fields and conservative readiness code vocabulary.

Verification:
- Passed targeted Dart format and analyzer for the native staging whitelist and
  bridge/review tests.
- Passed focused Flutter tests for Android auto-capture bridge, iOS camera
  settings/close bridge, and native photo quality result handoff.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 476 - 21:28:00 EDT to 21:35:50 EDT

Scope:
- Stayed on the camera-lane clear-photo readiness slice.
- Added stable diagnostic keys for capture readiness so native Android/iOS
  camera code can report the same manual/auto-capture decision fields.
- Wired capture-readiness diagnostics into native camera UI health counts and
  receipt-reader handoff counts.
- Added a regression proving an auto-capture-ready photo records manual capture
  availability, auto-capture availability, and the readiness code without
  storing receipt content.

Verification:
- Passed targeted format and analyzer for the capture model, quality model,
  native health-code helper, and focused camera quality tests.
- Passed focused Flutter tests for quality guidance, quality result handoff, and
  native saved-photo quality.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 475 - 21:12:00 EDT to 21:15:25 EDT

Scope:
- Stayed on the camera-lane quality/readiness slice.
- Added `ReceiptCaptureReadinessDecision` so receipt photo quality can produce a
  stable capture-readiness contract for manual capture and opt-in auto-capture.
- Kept manual capture allowed even when auto-capture is off, waiting for
  stability, or held back by quality/framing risk.
- Added regressions proving auto-capture waits for stable frames and stays
  blocked for glare or likely cut-off receipts while manual capture remains
  available.

Verification:
- Passed targeted format and analyzer for the quality model and guidance tests.
- Passed focused Flutter tests for receipt camera quality guidance and result
  quality.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 474 - 20:29:58 EDT to 20:31:22 EDT

Scope:
- Added `docs/expense_codex_b_handoff.md` as the dedicated instruction manual
  for the second Codex worker on the expense app lane.
- Linked the Codex B handoff from `README.md` and the expense release-one
  blueprint.
- Extended the expense blueprint guard so it protects the handoff link, branch
  name, owned expense paths, forbidden camera/shared-receipt paths, contract
  integration branch, and bug-to-regression rule.

Verification:
- Passed targeted format, analyzer, and focused Flutter test for the expense
  blueprint/handoff guard.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 473 - 18:46:30 EDT to 18:47:43 EDT

Scope:
- Expanded the planning lane from camera-only to the full release-one expense
  app.
- Added `docs/expense_release_one_blueprint.md` covering expense intake, shared
  receipt camera, OCR/parser review, fuel specialization, PDF/file intake,
  records/storage, reports/export, diagnostics/admin health, QA/regressions, and
  safe two-Codex ownership split.
- Linked the expense blueprint from `README.md` and `PROJECT_RULES.md`.
- Added `expense_release_one_blueprint_test.dart` and wired it into the fast
  receipt/expense guard so the blueprint remains discoverable.

Verification:
- Passed `dart format` for the new blueprint guard and fast-guard contract.
- Passed `bash -n tool/receipt_fast_guard_gate.sh`.
- Passed targeted analyzer for the expense blueprint guard and fast-guard
  contract.
- Passed focused Flutter tests for the expense blueprint guard and fast-guard
  contract.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 472 - 18:42:27 EDT to 18:43:55 EDT

Scope:
- Stayed on documentation architecture for the shared release-one receipt camera
  system before adding more feature code.
- Added `docs/receipt_camera_release_one_blueprint.md` as the active camera-first
  map for scope boundaries, architecture lanes, milestones, pass budget, pass
  discipline, and release-one definition of done.
- Linked the blueprint from `README.md`, `PROJECT_RULES.md`, and the active
  receipt camera/OCR master pass plan.
- Added `receipt_camera_release_one_blueprint_test.dart` and wired it into the
  fast receipt guard so the camera-first blueprint remains discoverable.
- Fixed a fast-guard continuation issue so the production directive and new
  blueprint tests remain inside the `dart analyze` file list.

Verification:
- Passed `bash -n tool/receipt_fast_guard_gate.sh`.
- Passed targeted analyzer for the blueprint guard, fast-guard contract, and
  production directive guard.
- Passed focused Flutter test batch for the blueprint guard, fast-guard contract,
  and production directive guard.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 471 - 18:14:30 EDT to 18:41:59 EDT

Scope:
- Propagated stitch overlap and source-preservation codes into OCR-source
  attachment document signals and OCR handoff stitch-signal counts.
- Added `docs/maintainiac_production_operating_directive.md` as the repo-level
  production trust, QA discipline, and bug-to-regression directive.
- Linked the directive from `README.md`, `PROJECT_RULES.md`, and the focused
  fast receipt guard.
- Added the production directive guard test so critical rules remain present in
  the repo.

Failures fixed during this pass:
- The directive guard initially failed because protected phrases wrapped across
  Markdown lines; made those policy phrases contiguous and reran the focused
  tests.

Verification:
- Passed targeted analyzer and focused Flutter tests for the directive and
  fast-guard contract files.
- Passed targeted analyzer and focused Flutter tests for stitch-signal handoff
  files and camera/OCR handoff regressions.
- Passed `bash -n tool/receipt_fast_guard_gate.sh`,
  `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.

## Pass 470 - 18:10:04 EDT to 18:14:29 EDT

Scope:
- Stayed on the stitching/overlap slice of the shared receipt camera system.
- Added explicit stitch overlap coverage and source-preservation contracts to
  `ReceiptStitchResult`, including matched/missing pair counts, all-pairs
  evidence, fallback pair code, and original-vs-derived OCR source policy.
- Exposed stitch coverage/source-preservation codes through receipt review
  handoff metadata and stitch diagnostic counts so OCR/parser review can verify
  camera output without guessing.
- Extended stitch result and camera-result handoff regressions for stitched,
  fallback, single-photo, and manual-overlap cases.

Verification:
- Passed targeted analyzer for stitch models, handoff metadata, and focused
  stitching tests.
- Passed focused Flutter stitching batch: stitch result contract, manual
  overlap, full stitching fixtures, and camera-result stitch scanner handoff
  tests. The batch completed with 20 tests passed.
- Passed targeted `git diff --check`; touched files remain under 500 lines.

## Pass 469 - 18:06:54 EDT to 18:10:03 EDT

Scope:
- Stayed on the retake/order slice of the shared receipt camera system.
- Added result-level rollups for privacy-safe retake diagnostics so preserved
  slot, inserted extra section, original/final section number, guidance code,
  retake order policy, and previous/next/two-sided alignment context flow into
  `receiptSectionOrderCounts`.
- Added a receipt-result regression proving middle-section retake metadata
  reaches handoff counts and privacy-safe metadata without leaking file paths or
  raw receipt text.

Verification:
- Passed targeted format and analyzer for the retake/order result files and
  tests.
- Passed focused Flutter tests for result stitch/scanner handoff, retake order,
  long-receipt guidance, and camera capture layout.
- Passed targeted `git diff --check`; touched files remain under 500 lines.

## Pass 468 - 17:56:49 EDT to 18:06:53 EDT

Scope:
- Reset the active goal to camera-first release-one hardening: clear capture,
  long-receipt multi-photo flow, retake order, ghost/overlap guidance,
  stitching handoff, and source preservation before deeper OCR/parser work.
- Stopped stale failed detached OCR pipeline processes and fixed the quiet
  pipeline failure cleanup path so it no longer runs `dart run` while already
  failing.
- Changed receipt guard scripts to use direct `dart tool/...dart` for local
  file-audit tools, avoiding unnecessary Flutter/Dart build hooks during fast
  guard and detached pipeline checks.
- Split the blended static OCR pipeline phase into named static subphases so a
  future failure reports the exact guard that failed.
- Hardened retake ordering so replacement photos preserve the original section
  slot and emit privacy-safe retake diagnostics for previous/next alignment
  context and inserted extra sections.

Failures fixed during this pass:
- Focused quiet-batch policy test failed because it still expected stale phase
  log cleanup instead of full temp-run cleanup; updated the contract.
- Long-receipt guidance contract failed because it still expected the old
  previous-index retake guide logic; updated it to require the new retake
  alignment context and diagnostic merge.

Verification:
- Passed `bash -n` for edited receipt guard and quiet-pipeline shell scripts.
- Passed direct Dart guard scripts for quiet-batch policy, source audit,
  external fixture schema, camera I/O, and footprint audit.
- Passed targeted analyzer for edited retake, long-receipt, and guard contract
  files.
- Passed focused Flutter tests for quiet-batch policy, fast guard, retake order,
  long-receipt guidance, and camera capture layout.
- Passed targeted `git diff --check`; touched files remain under 500 lines.
- Current receipt camera/OCR source footprint audit reports 293 files and
  1.68 MB of source, excluding build artifacts and PDF helpers.

## Pass 467 - 17:06:55 EDT to 17:10:28 EDT

Scope:
- Continued treating the receipt/camera/OCR path as shared app infrastructure:
  expenses and fuel first, with inventory/work-supply receipt intake as a
  downstream consumer of the same source-of-truth pipeline.
- Investigated the detached OCR pipeline after it reached a real static phase
  failure instead of a launcher failure.
- Fixed `tool/receipt_ocr_pipeline_run.sh` so repo shell scripts are executed
  through stdin-safe `run_repo_script` calls in detached contexts, avoiding
  macOS `Operation not permitted` failures from direct `bash tool/*.sh` paths.
- Hardened `tool/receipt_quiet_batch_policy_gate.dart` so direct repo shell
  script execution cannot return to OCR pipeline phases.
- Audited the current fixture/QA architecture and confirmed the next major
  shared-system gap: inline QA fixtures are useful, but external/real fixture
  support is still explicitly marked `externalFixtureFilesReady=false`.

Failures fixed during this pass:
- `static_guardrails` failed because detached execution could not open
  `tool/receipt_cleanup_log_gate.sh` directly as a script path.
- Older detached pipeline children and stale screen sockets were cleaned up so
  the next OCR pipeline run had clean metadata.

Verification:
- Passed a detached probe proving `/bin/bash -s < <(sed "" tool/script.sh)` can
  run `receipt_cleanup_log_gate.sh` under `screen`.
- Passed `bash -n` for the edited OCR pipeline and launcher scripts.
- Passed `dart format`, `dart analyze tool/receipt_quiet_batch_policy_gate.dart`,
  and `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `flutter test test/receipt_quiet_batch_policy_gate_contract_test.dart
  -r compact`.
- Passed targeted `git diff --check` and line-count checks for touched pipeline,
  policy, and focused test files.
- Restarted `receipt_ocr_pipeline`; metadata showed `status=running`,
  `running=true`, `runner_started=true`, and `runner_finished=false`. Did not
  tail or watch the long-running pipeline.

## Pass 466 - 17:01:04 EDT to 17:06:54 EDT

Scope:
- Treated the shared receipt/camera/OCR pipeline as app-wide infrastructure for
  expenses first, with inventory/work supplies as downstream consumers, not as a
  one-off OCR text extractor.
- Fixed the quiet OCR pipeline launcher after repeated detached-run failures:
  generated runners now preserve command argument boundaries, prefer `screen`,
  restore the repo working directory, expose runner lifecycle metadata, and use
  a login-shell payload command that actually stays alive after Codex returns.
- Changed the OCR pipeline and quality-gate launchers to rewrite payload scripts
  into the quiet batch directory and execute those payloads through a quoted
  login-shell command.
- Hardened `tool/receipt_ocr_pipeline_run.sh` so each run clears stale phase
  logs/regression task files before writing the current summary.
- Updated the quiet-batch policy gate and focused contract test so the
  non-monitoring launcher behavior, copied payload execution, stale-log cleanup,
  and no-live-log workflow are permanent regression guards.

Failures fixed during this pass:
- Detached OCR pipeline runs were failing or going stale before meaningful QA
  because macOS/screen execution treated direct script paths and bad generated
  command quoting inconsistently.
- The pipeline phase directory could retain stale phase logs from earlier failed
  attempts, making failure triage ambiguous.
- The policy gate initially failed from unescaped Dart shell-string assertions;
  fixed those before restarting the pipeline.

Verification:
- Passed `bash -n` for the edited launcher and pipeline shell scripts.
- Passed `dart format`, `dart analyze tool/receipt_quiet_batch_policy_gate.dart`,
  and `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `flutter test test/receipt_quiet_batch_policy_gate_contract_test.dart
  -r compact`.
- Passed targeted `git diff --check` and line-count checks on edited launcher,
  policy, pipeline, and focused test files.
- Restarted `receipt_ocr_pipeline` as a detached quiet batch; the metadata check
  showed `status=running`, `running=true`, `runner_started=true`, and
  `runner_finished=false`. Did not watch or tail the running pipeline.

## Pass 464 - 16:43:45 EDT to 16:45:20 EDT

Scope:
- Checked the detached OCR pipeline once using metadata only; the old run showed
  stale status because pid `37666` was dead with no exit code.
- Hardened `tool/receipt_quiet_batch.sh` with an EXIT trap so detached batches
  always write final status and exit code.
- Hardened `tool/receipt_quiet_batch_status.sh` so dead `running` batches with
  no exit code report `stale`.
- Hardened `tool/receipt_ocr_pipeline_run.sh` with an EXIT trap and startup or
  unhandled-exit failure report path.
- Updated `tool/receipt_quiet_batch_policy_gate.dart` so those finalization and
  stale-state protections are required.
- Restarted the detached OCR pipeline after static verification. The hardened
  launcher returned immediately with pid `41064`.

Verification:
- Passed `bash -n` for the quiet batch, status helper, OCR pipeline runner, and
  OCR pipeline launcher.
- Passed `dart format`, `dart analyze`, and
  `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Did not read phase logs, poll the restarted pipeline, run Flutter directly, or
  attach to long OCR pipeline output during this pass.

## Pass 463 - 16:41:30 EDT to 16:43:03 EDT

Scope:
- Used the larger one-command OCR/camera pipeline instead of another narrow
  feature pass.
- Checked the detached quiet-batch status once using metadata only; no previous
  `receipt_ocr_pipeline` batch existed.
- Fixed `tool/receipt_start_ocr_pipeline.sh` and
  `tool/receipt_start_quiet_quality_gate.sh` so they invoke
  `bash tool/receipt_quiet_batch.sh` instead of requiring executable file bits.
- Updated `tool/receipt_quiet_batch_policy_gate.dart` so the quiet launchers
  require that safer `bash` invocation.
- Started `tool/receipt_start_ocr_pipeline.sh receipt_ocr_pipeline` as a
  detached quiet batch. The launcher returned immediately with pid `37666`.

Verification:
- Passed static wrapper checks: `dart format`, `bash -n`, `dart analyze`, and
  `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Did not inspect pipeline logs, poll pipeline progress, run Flutter directly,
  or attach to the long OCR pipeline output during this pass.
- Detached pipeline status/log files are under
  `/tmp/maintainiac_receipt_quiet_batch/receipt_ocr_pipeline/`.

## Pass 462 - 16:38:45 EDT to 16:40:46 EDT

Scope:
- Strengthened the one-command OCR/camera pipeline failure workflow.
- Added `tool/receipt_pipeline_failure_to_regression.dart`, which reads a
  failed pipeline run's `failure_report.txt` and creates a regression task under
  `/tmp/maintainiac_receipt_ocr_pipeline/<run>/regression_tasks/`.
- Wired `tool/receipt_ocr_pipeline_run.sh` so a failed phase writes the normal
  failure report and then generates the regression task automatically.
- Expanded `tool/receipt_quiet_batch_policy_gate.dart` so the pipeline must
  include the failure-to-regression generator.
- Updated `docs/receipt_ocr_pipeline_blueprint.json` and the QA standard with
  the failure-to-regression command and policy.

Verification:
- Passed Dart format for the new generator and policy gate.
- Passed `bash -n tool/receipt_ocr_pipeline_run.sh`.
- Passed JSON parse for `docs/receipt_ocr_pipeline_blueprint.json`.
- Passed `dart analyze tool/receipt_pipeline_failure_to_regression.dart
  tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `dart run tool/receipt_quiet_batch_policy_gate.dart`.
- Passed `bash tool/receipt_cleanup_log_gate.sh` and targeted
  `git diff --check`.
- Did not start the OCR pipeline, Flutter, or the full receipt QA runner during
  this pass.
