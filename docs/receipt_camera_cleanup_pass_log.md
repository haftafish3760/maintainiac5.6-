# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 499 - 01:33:00 EDT to 01:38:00 EDT

Scope:
- Hardened long-receipt manual overlap stitching so non-finite overlap fractions
  cannot escape the safe manual-overlap fallback path.
- Added regression coverage proving non-finite manual overlap uses
  `manual_overlap_unsafe` and preserves ordered OCR source paths.
- Recorded `BUG-RECEIPT-0018` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format and analyzer for stitch helpers and focused manual
  overlap regression coverage.
- Passed focused Flutter test
  `test/receipt_stitching_manual_overlap_test.dart --plain-name "manual overlap
  fraction rejects non-finite values safely"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 498 - 01:26:00 EDT to 01:30:00 EDT

Scope:
- Hardened multi-photo retake order planning so replacement paths with leading
  or trailing whitespace cannot bypass current-section or duplicate checks.
- Added regression coverage proving unnormalized retake replacement paths are
  rejected before section order is mutated.
- Recorded `BUG-RECEIPT-0017` under `multi_photo_ordering`.
- Archived Pass 481 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for retake order planning and focused
  retake-order regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake plan
  rejects unnormalized replacement paths"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 497 - 01:19:00 EDT to 01:24:00 EDT

Scope:
- Hardened OCR source handoff review so saved-photo glare/washed-out warnings
  get a specific source-quality status and action instead of generic scanner
  preparation review.
- Added regression coverage proving glare risk flags map to
  `saved_glare_review` and `reduce_glare_or_retake`.
- Recorded `BUG-RECEIPT-0016` under `ocr_handoff_contract`.
- Archived Pass 482 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for OCR source handoff review and
  focused OCR service handoff regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_test.dart --plain-name "source handoff reports glare
  saved-photo review"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 496 - 01:12:00 EDT to 01:17:00 EDT

Scope:
- Hardened native saved-photo quality diagnostics so non-finite values from the
  camera bridge cannot suppress bottom-of-receipt warnings.
- Added regression coverage proving bogus bottom luma evidence still surfaces
  `saved_photo_bottom_too_dark` and the OCR bottom-total risk code.
- Recorded `BUG-RECEIPT-0015` under `camera_capture_quality`.
- Archived Pass 483 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for native saved-photo warnings and
  focused warning diagnostics regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_saved_photo_warning_diagnostics_test.dart`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 495 - 01:03:00 EDT to 01:07:00 EDT

Scope:
- Hardened the receipt line editor split-percent parser so negative values keep
  their sign until the clamp step instead of becoming positive percentages.
- Added regression coverage that blocks the old non-digit stripping behavior and
  keeps percent-sign normalization explicit.
- Recorded `BUG-RECEIPT-0014` under `business_personal_split`.
- Archived Pass 484 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the receipt line editor derived
  fields and assisted-review source regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 494 - 00:49:00 EDT to 00:54:00 EDT

Scope:
- Hardened the active receipt entry draft line model so review previews and
  in-progress totals use bounded split percentages before save.
- Added source-level regression coverage for the private entry computed fields
  that drive line review labels and mixed business/personal totals.
- Recorded `BUG-RECEIPT-0013` under `business_personal_split`.
- Archived Pass 485 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for receipt entry computed fields and
  assisted-review source regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 493 - 00:42:00 EDT to 00:47:00 EDT

Scope:
- Hardened receipt line split allocation math so parser/adaptor-created split
  lines cannot produce more than 100% business or negative personal amounts.
- Ensured serialized receipt line maps write bounded split percentages, keeping
  saved records and downstream reports inside valid financial ranges.
- Added regression coverage for malformed over- and under-allocated split
  percentages.
- Recorded `BUG-RECEIPT-0012` under `business_personal_split`.
- Archived Pass 486 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for receipt line records,
  serialization, and focused line-record regression coverage.
- Passed focused Flutter regression
  `test/expense_receipt_line_record_test.dart --plain-name "split receipt lines
  bound malformed business percentages"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

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

## Pass 487 - 00:07:47 EDT

Scope:
- Hardened receipt review source preservation so saved proof paths and OCR
  source paths are normalized with order-preserving de-duplication.
- Added a permanent source-preservation regression for duplicate saved proof and
  OCR source paths inflating receipt section counts and handoff metadata.
- Recorded `BUG-RECEIPT-0006` under `source_preservation` in the regression
  ledger.

Verification:
- Passed `dart format --set-exit-if-changed` for touched receipt model/test
  files.
- Passed targeted analyzer for the receipt review model, focused test, and bug
  ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed focused `flutter test test/receipt_camera_result_test.dart --plain-name
  "photo review result removes duplicate saved and OCR source paths" -r compact`.
- Passed full focused `flutter test test/receipt_camera_result_test.dart -r
  compact`.

## Pass 488 - 00:08:32 EDT to 00:10:03 EDT

Scope:
- Hardened the receipt pipeline failure-to-regression process so generated
  failure tasks include a suggested categorized bug ledger category.
- Updated both the Dart generator and shell pipeline fallback to require a
  `BUG-RECEIPT-####` ledger row before a regression task is treated as closed.
- Added regression coverage proving camera pipeline failures create tasks that
  name the failure family, bug ledger, suggested category, and uncategorized-bug
  prohibition.
- Recorded `BUG-RECEIPT-0007` under `qa_harness`.
- Archived Pass 467 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed `dart format --set-exit-if-changed` for the failure-to-regression tool
  and focused test.
- Passed targeted analyzer for the failure-to-regression tool, focused test,
  and bug ledger gate.
- Passed `flutter test test/receipt_pipeline_failure_to_regression_test.dart -r
  compact`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed `bash -n tool/receipt_ocr_pipeline_run.sh`.

## Pass 489 - 00:10:03 EDT to 00:14:10 EDT

Scope:
- Moved native auto-capture readiness thresholds into the shared receipt camera
  session contract so Android and iOS no longer own separate hardcoded gates.
- Added session arguments for stable frame target, max motion score, brightness
  range, and auto-capture cooldown.
- Wired Android and iOS native camera flows to read, clamp, report, and use
  those configured thresholds.
- Updated native diagnostics so admin/debug evidence reports the configured
  readiness gate instead of a stale fixed value.
- Recorded `BUG-RECEIPT-0008` under `native_bridge`.

Verification:
- Passed targeted `dart format --set-exit-if-changed` for touched Dart tests
  and receipt camera contract files.
- Passed targeted analyzer for the native camera contract/service and focused
  native bridge tests.
- Passed focused Flutter tests for native session contract, Android
  auto-capture bridge, iOS settings/close bridge, Android analysis/exposure,
  and iOS storage contract.

## Pass 490 - 00:14:10 EDT to 00:16:05 EDT

Scope:
- Hardened OCR parser line draft labels so multi-section receipt review can use
  source-first line labels when section/line metadata is available.
- Added `sourceFirstLineLabel` to local review and privacy-safe parser summary
  maps while keeping parser-index `lineLabel` intact.
- Recorded `BUG-RECEIPT-0009` under `receipt_line_numbering`.
- Archived Pass 468 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed `dart format --set-exit-if-changed` for the parser model and focused
  parser-handoff test.
- Passed targeted analyzer for the parser model, focused test, and bug ledger
  gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/receipt_ocr_service_parser_handoff_structure_test.dart -r compact`.

## Pass 491 - 00:16:05 EDT to 00:18:14 EDT

Scope:
- Hardened receipt client-proof redaction planning so subtotal, tax, and total
  lines stay together when totals context is requested.
- Kept unselected item lines and payment/transaction lines hidden unless they
  are explicitly selected or required context.
- Recorded `BUG-RECEIPT-0010` under `privacy_redaction`.

Verification:
- Passed `dart format --set-exit-if-changed` for the receipt layout model and
  direct parser parity test.
- Passed targeted analyzer for receipt layout, direct parser parity, and the
  bug ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/expense_receipt_parser_direct_parity_test.dart -r compact`.

## Pass 492 - 00:18:14 EDT to 00:19:58 EDT

Scope:
- Hardened multi-photo native review-depth handoff so detailed line review is
  not downgraded to prices-only when any captured section requests detailed
  lines.
- Added privacy-safe review-depth counts to receipt reader handoff metadata.
- Recorded `BUG-RECEIPT-0011` under `receipt_line_review_mode`.
- Archived Pass 469 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed `dart format --set-exit-if-changed` for receipt review result native
  signal/metadata files and focused frozen result test.
- Passed targeted analyzer for receipt capture models, focused frozen result
  test, and bug ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/receipt_camera_result_frozen_brain_install_test.dart -r compact`.
