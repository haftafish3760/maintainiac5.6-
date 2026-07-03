# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 517 - 01:17:01 EDT to 01:17:58 EDT

Scope:
- Hardened receipt section retake ordering so duplicate or unnormalized current
  section paths cannot make `indexOf` retake the wrong receipt slot.
- Added retake-order regression coverage proving ambiguous current section
  paths are rejected before replacement.
- Recorded `BUG-RECEIPT-0035` under `multi_photo_ordering`.
- Archived Pass 480 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial targeted analyzer failure by moving the current-path
  uniqueness helper where both retake builders can use it.
- Passed targeted Dart format and analyzer for retake ordering and focused
  retake-order regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake plan
  rejects duplicate current section paths"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 518 - 01:31:00 EDT to 01:39:00 EDT

Scope:
- Hardened long-receipt add-photo ordering so continuation photos insert after
  the same selected section slot that launched the camera, not the first
  matching path after async return.
- Hardened remove-photo ordering so confirmed removals delete the original
  selected section slot and reject ambiguous duplicate or stale section paths.
- Added insert/remove order plan regressions for duplicate current paths and
  stale async anchors.
- Recorded `BUG-RECEIPT-0036` under `multi_photo_ordering`.
- Archived Pass 493 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for photo review ordering actions,
  retake/order plans, and focused ordering regression coverage.
- Passed full focused Flutter test `test/receipt_photo_review_retake_order_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 516 - 01:15:25 EDT to 01:16:19 EDT

Scope:
- Hardened in-entry receipt proof line labels so unsafe draft source IDs and
  generated manual IDs no longer appear in receipt review rows before save.
- Added source regression coverage proving the raw fallback-label path is gone.
- Recorded `BUG-RECEIPT-0034` under `privacy_redaction`.
- Archived Pass 479 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial regression string escaping syntax error, then reran the
  focused chain.
- Passed targeted Dart format and analyzer for draft receipt line labels and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 515 - 01:13:06 EDT to 01:14:21 EDT

Scope:
- Hardened in-entry receipt draft line redaction anchors so unsaved/manual line
  IDs that include typed descriptions use deterministic private-safe tokens.
- Hardened draft OCR line labels so unsafe source IDs fall back to a generic
  receipt-line label.
- Added source regression coverage proving the old raw draft-line ID fallback is
  gone from the assisted review entry model.
- Recorded `BUG-RECEIPT-0033` under `privacy_redaction`.
- Archived Pass 478 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure caused by asserting helper placement in
  the wrong source bundle, then tightened draft OCR line labels and reran.
- Passed targeted Dart format and analyzer for draft line models, computed
  fields, support helpers, and assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 514 - 01:09:30 EDT to 01:11:50 EDT

Scope:
- Hardened receipt line redaction anchors so manual/generated line IDs that
  contain typed item descriptions are replaced with deterministic private-safe
  tokens before entering privacy-safe contracts.
- Added regression coverage proving manual private item text and generated IDs
  do not appear in line review contracts.
- Recorded `BUG-RECEIPT-0032` under `privacy_redaction`.
- Archived Pass 477 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure where the line-number label still used a
  generated private-text ID, then reran the focused chain.
- Fixed a targeted analyzer style issue before commit.
- Passed targeted Dart format and analyzer for expense receipt line records and
  line-record regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_line_record_test.dart --plain-name "privacy-safe receipt
  line contracts never expose generated item ids"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 513 - 01:06:51 EDT to 01:08:06 EDT

Scope:
- Hardened native capture staging bottom-edge evidence so non-finite edge scores
  do not default to "present until OCR evidence" when native framing says the
  receipt may be cut off.
- Hardened staged recovery manifest diagnostics so non-finite numeric values are
  not written into JSON payloads.
- Added staging regression coverage for unusable native edge evidence.
- Recorded `BUG-RECEIPT-0031` under `camera_capture_quality`.
- Archived Pass 476 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure where non-finite diagnostics crashed
  recovery manifest JSON encoding, then reran the focused chain.
- Passed targeted Dart format and analyzer for native staging cleanup,
  diagnostics, safe diagnostics, and staging regression coverage.
- Passed focused Flutter test
  `test/receipt_native_capture_staging_test.dart --plain-name "native staging
  treats non-finite edge evidence as cut off"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 512 - 01:04:59 EDT to 01:06:18 EDT

Scope:
- Hardened receipt coverage evidence parsing so non-finite diagnostic numbers
  cannot fake bottom-edge or totals completion evidence.
- Added a coverage regression proving malformed native numbers still produce a
  conservative missing-bottom-and-totals continuation decision.
- Recorded `BUG-RECEIPT-0030` under `camera_capture_quality`.
- Archived Pass 475 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial analyzer failure from a wrong diagnostic key in the new
  regression, then fixed the app logic after the corrected regression exposed a
  false likely-complete decision.
- Passed targeted Dart format and analyzer for receipt coverage evidence helpers
  and coverage totals regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_coverage_totals_test.dart --plain-name
  "non-finite coverage diagnostics are treated as missing evidence"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 511 - 01:03:26 EDT to 01:04:01 EDT

Scope:
- Hardened native camera capability parsing so malformed platform numbers cannot
  become fake camera counts, zoom ranges, exposure ranges, or still sizes.
- Added direct unit regression coverage for non-finite capability values.
- Recorded `BUG-RECEIPT-0029` under `native_bridge`.
- Archived Pass 474 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the native camera contract and
  native camera session contract regression coverage.
- Passed focused Flutter test
  `test/receipt_native_camera_session_contract_test.dart --plain-name "native
  capabilities reject non-finite platform numbers"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 510 - 01:02:14 EDT to 01:02:52 EDT

Scope:
- Hardened receipt capture diagnostic telemetry so recovery photo counts from
  native diagnostics reject non-finite numeric values instead of crashing.
- Added regression coverage proving the recovery telemetry converter requires a
  finite numeric value.
- Recorded `BUG-RECEIPT-0028` under `camera_capture_quality`.
- Archived Pass 473 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for capture diagnostic telemetry and
  OCR source handoff regression coverage.
- Passed focused Flutter test `test/receipt_camera_ocr_source_handoff_test.dart`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 509 - 01:00:37 EDT to 01:01:44 EDT

Scope:
- Hardened receipt camera diagnostic bucket helpers so non-finite numeric
  payloads from the native bridge cannot crash telemetry or create fake quality
  evidence.
- Added regression coverage proving diagnostic integer parsing goes through a
  finite-value helper.
- Recorded `BUG-RECEIPT-0027` under `camera_capture_quality`.

Verification:
- Fixed an initial focused-test failure caused by the regression fixture not
  reading the diagnostic helper implementation, then reran the focused chain.
- Passed targeted Dart format and analyzer for diagnostic bucket helpers and
  OCR source handoff regression coverage.
- Passed focused Flutter test `test/receipt_camera_ocr_source_handoff_test.dart`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 508 - 00:58:43 EDT to 00:59:26 EDT

Scope:
- Hardened the main split-percent sheet so custom business percent text can
  include a percent sign, matching the quick price-only split path.
- Added regression coverage proving the old direct custom controller parse path
  is gone.
- Recorded `BUG-RECEIPT-0026` under `business_personal_split`.
- Archived Pass 472 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the split percent sheet and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 507 - 00:56:22 EDT to 00:57:13 EDT

Scope:
- Hardened quick price-only split line entry so custom business percent text can
  include a percent sign just like the full line editor.
- Added regression coverage proving the quick split parser strips `%` and the
  old direct `double.tryParse(...trim())` path is gone.
- Recorded `BUG-RECEIPT-0025` under `business_personal_split`.
- Archived Pass 471 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for quick line-mode helpers and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 506 - 00:54:54 EDT to 00:55:52 EDT

Scope:
- Hardened single-line split review metadata so the parser review reason records
  the user-selected business percent instead of always saying 50%.
- Added regression coverage proving the old misleading split reason is gone and
  the selected percent helper is present.
- Recorded `BUG-RECEIPT-0024` under `business_personal_split`.
- Archived Pass 470 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test compile failure caused by an unescaped `$percent`
  literal in the regression assertion, then reran the focused checks.
- Passed targeted Dart format and analyzer for receipt entry state actions and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 505 - 00:53:06 EDT to 00:53:57 EDT

Scope:
- Hardened per-source continuation attachment signals so blank native values no
  longer hide valid phone-camera backup continuation evidence.
- Added regression coverage through `ReceiptCaptureFlow.attachmentsFromReviewResult`
  proving attachment document/risk signals keep bottom ghost-guide policy.
- Recorded `BUG-RECEIPT-0023` under `ocr_handoff_contract`.
- Archived Pass 492 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for continuation attachment signal
  builders and focused continuation regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_continuation_handoff_test.dart --plain-name "phone
  backup continuation survives blank native values"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 504 - 00:51:33 EDT to 00:52:21 EDT

Scope:
- Hardened continuation/ghost-guide receipt handoff so blank native diagnostic
  values no longer block valid phone-camera backup evidence.
- Added regression coverage proving bottom-section continuation reason and ghost
  guide policy survive empty primary values without leaking paths.
- Recorded `BUG-RECEIPT-0022` under `ocr_handoff_contract`.
- Archived Pass 491 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for continuation handoff source and
  focused continuation regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_continuation_handoff_test.dart --plain-name "phone
  backup continuation survives blank native values"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 503 - 00:49:44 EDT to 00:50:56 EDT

Scope:
- Added focused guardrail coverage proving non-finite previous-section ghost
  guide fractions fall back to safe receipt-camera defaults.
- Kept this as QA hardening only because the current implementation already
  rejects `NaN` and infinite values.
- Archived Pass 490 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for native camera session limits.
- Passed focused Flutter test
  `test/receipt_native_camera_session_limits_test.dart --plain-name "session
  rejects non-finite previous section ghost guide fractions"`.
- Passed cleanup log gate, doc size gate, receipt source audit, and
  `git diff --check`.

## Pass 502 - 00:47:37 EDT to 00:48:43 EDT

Scope:
- Hardened native review-depth diagnostics so malformed non-empty bridge values
  are counted in privacy-safe metadata instead of disappearing into the default
  price-only fallback.
- Added regression coverage proving invalid review-depth values keep the safe
  fallback but expose an `invalid_*` audit bucket.
- Recorded `BUG-RECEIPT-0021` under `native_bridge`.
- Archived Pass 489 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for native review-depth signals and
  focused frozen-result regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_frozen_brain_install_test.dart --plain-name
  "malformed native review depth is visible in safe metadata"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 501 - 00:45:52 EDT to 00:47:00 EDT

Scope:
- Hardened privacy-safe receipt line metadata so generated line IDs cannot leak
  item description text through review or client-proof contracts.
- Added regression coverage proving privacy-safe line review/proof metadata uses
  redaction anchors while source-of-truth line IDs remain intact.
- Recorded `BUG-RECEIPT-0020` under `privacy_redaction`.
- Archived Pass 488 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for receipt line records and focused
  privacy regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_line_record_test.dart --plain-name "privacy-safe receipt
  line contracts never expose generated item ids"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 500 - 00:44:25 EDT to 00:45:01 EDT

Scope:
- Hardened stitched receipt handoff metadata so source preservation includes
  privacy-safe input-source counts, OCR-source counts, overlap totals, and manual
  adjustment state without exposing raw paths.
- Added regression coverage proving the stitched OCR artifact reports its source
  counts while keeping private file paths out of privacy-safe metadata.
- Recorded `BUG-RECEIPT-0019` under `source_preservation`.
- Archived Pass 487 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for stitched receipt metadata,
  stitch result contracts, and focused stitch scanner regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_stitch_scanner_test.dart --plain-name "photo
  review result explains stitched and fallback handoffs"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

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
