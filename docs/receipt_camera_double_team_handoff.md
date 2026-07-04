# Receipt Camera Double-Team Handoff

Last updated: 2026-07-03

This is the coordination file for running a second Codex model beside the active
camera-hardening thread in `/Users/rbbie/Documents/Maintainiac_5.6`.

The goal is faster progress without two agents editing the same files or
silently changing each other's contracts.

## Branch Setup

Primary active branch owned by the current camera model:

- `codex/expense-camera-lane`

Recommended branch for the second model:

- `codex/receipt-ocr-handoff-lane`

Start the second branch from the latest pushed `codex/expense-camera-lane`
checkpoint, then keep the scope below. Do not work from Maintainiac 5.5.

Before editing, run:

```sh
cd /Users/rbbie/Documents/Maintainiac_5.6
git fetch origin
git checkout codex/expense-camera-lane
git pull --ff-only origin codex/expense-camera-lane
git checkout -b codex/receipt-ocr-handoff-lane
git status --short --branch
```

If the worktree is dirty, stop and inspect. Dirty means files have changes that
are not committed. They may be user work or another model's work. Do not delete,
reset, stash, or overwrite them without explicit user approval.

## Ownership Split

### Current Camera Model Owns

The current model owns the native/shared camera foundation:

- native Android CameraX behavior
- native iOS AVFoundation behavior
- camera capability contracts
- continuous focus/exposure/readability guidance
- camera session orchestration
- receipt capture UI
- photo review screen flow
- long receipt segment capture
- segment retake ordering
- previous/next segment context
- ghost overlay and overlap guidance
- stitching session handoff
- original source image preservation
- camera-side barcode/QR scanner bridge
- camera diagnostics and privacy-safe capture metadata
- real-device camera readiness scripts

The second model must not edit those areas unless the user explicitly transfers
ownership or the current camera model writes a coordination note naming the file.

### Second Model Owns

The second model should work on OCR/review handoff infrastructure that can be
tested without changing the live camera flow:

- OCR result contract models
- parser handoff models
- receipt line numbering contracts
- detailed-line versus price-only review data contracts
- business/personal/split line classification models
- OCR suggestion versus user-confirmed truth tests
- privacy-safe OCR/parser diagnostics
- synthetic receipt fixture definitions and generator helpers
- real-receipt fixture schema for future redacted samples
- parser-facing regression fixtures
- tests proving handoff maps preserve stable line IDs and line numbers
- docs that describe OCR/parser handoff behavior without redefining camera UI

The second model is allowed to add focused tests for these contracts. If a test
exposes a camera-flow bug, document the bug and hand it back instead of patching
camera-owned files.

## Files The Second Model May Touch

Prefer these files and nearby focused test files:

- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_lines.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_proof.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_readiness.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_warnings.dart`
- `lib/screens/expenses/data/expense_line_record.dart`
- `lib/screens/expenses/data/expense_line_record_serialization.dart`
- `lib/screens/expenses/data/expense_receipt_parse_models.dart`
- `lib/screens/expenses/data/expense_receipt_parse_result.dart`
- `lib/screens/expenses/data/expense_receipt_parser_ocr_handoff_logic.dart`
- `lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `lib/screens/expenses/data/expense_receipt_ocr_review_helpers.dart`
- `lib/screens/expenses/data/expense_receipt_classification_models.dart`
- `lib/screens/expenses/data/expense_receipt_classification_scores.dart`
- `lib/screens/expenses/data/expense_receipt_classifier.dart`
- `test/receipt_ocr_service_parser_handoff_structure_test.dart`
- `test/receipt_ocr_service_fuel_receipts_test.dart`
- `test/expense_receipt_line_record_test.dart`
- `test/expense_receipt_parser_business_personal_test.dart`
- `test/expense_receipt_parser_ocr_diagnostics_test.dart`
- `test/expense_receipt_parser_line_amounts_test.dart`
- `test/expense_receipt_parser_allocations_test.dart`
- `test/receipt_qa_runner_contract_test.dart`
- `test/helpers/receipt_*`
- `test/helpers/expense_*`

The second model may add new focused files with meaningful names, for example:

- `lib/shared/widgets/receipt_capture/receipt_fixture_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_synthetic_fixture_generator.dart`
- `test/receipt_synthetic_fixture_generator_test.dart`
- `test/receipt_review_handoff_line_numbering_test.dart`
- `test/receipt_user_confirmed_truth_regression_test.dart`

Keep new files modular and under the project line cap. Do not use lazy numbered
names like `file1`, `helper2`, or `ocr3`.

## Files The Second Model Must Not Touch

Do not edit these camera-owned files:

- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt`
- `ios/Runner/ReceiptCameraViewController.swift`
- `ios/Runner/ReceiptCameraViewController*.swift`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile.lock`
- `lib/shared/widgets/receipt_capture/receipt_capture.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_flow.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_flow_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_settings_session.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_keys.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor.dart`
- `lib/shared/widgets/receipt_capture/receipt_stitching_*`
- `lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_barcode_scanner_service.dart`
- `test/receipt_native_android_*`
- `test/receipt_native_ios_*`
- `test/receipt_native_camera_*`
- `test/receipt_camera_result_*`
- `test/receipt_camera_capture_*`
- `test/receipt_camera_quality_*`
- `test/receipt_stitching_*`

Also do not touch inventory-owned catalog/work-supply files unless the user
explicitly asks. The inventory model owns those.

## Product Rules The Second Model Must Preserve

- Google ML Kit local OCR is the primary free/local OCR engine.
- Google Cloud Vision OCR is future premium/cloud assist, not required for this
  branch unless explicitly assigned.
- OCR output is suggestion data, not truth.
- User-confirmed fields are truth.
- Parser guesses must never silently overwrite user-confirmed financial data.
- Original receipt images are source truth and must not be destroyed.
- Derived/stiched/cleaned/OCR images are artifacts, not source truth.
- Privacy-safe diagnostics must never include raw receipt text, store phone
  numbers, addresses, customer names, employee names, VINs, plates, passenger
  data, patient data, private notes, or full barcode payloads.
- Hive/local storage is the immediate source of truth.
- Firestore/cloud sync is a mirror/backup, not the brain.
- Do not model NEMT patient data.

## Required Work For The Second Model

Work in this order unless the current tree shows a failing check that must be
fixed first.

1. Audit the current OCR/parser handoff contracts.
2. Identify the line-numbering path from OCR lines to receipt review lines.
3. Add or strengthen tests proving every review line has a stable line ID and a
   safe one-based line number.
4. Prove price-only review keeps amount/classification data without requiring
   item description text.
5. Prove detailed-line review can keep item description text locally while
   privacy-safe diagnostics expose only safe summary flags.
6. Prove business/personal/split classification survives map serialization and
   parser handoff.
7. Add fixture schema support for synthetic and future real redacted receipts.
8. Add tests for malformed OCR input: empty lines, duplicate line numbers,
   negative line numbers, huge line numbers, missing totals, duplicate totals,
   and noisy text.
9. Update `docs/receipt_bug_regression_ledger.md` only when a confirmed bug is
   fixed with a regression test.
10. Update this handoff or create a short companion note only if ownership
   boundaries change.

## Testing Rules

Use targeted checks while developing. Do not run full gates after tiny edits.
When a command is long-running, run it non-interactively and inspect the final
result only.

Minimum checks for the second model after a focused batch:

```sh
dart format <changed dart files>
dart analyze <changed dart files and changed test files>
flutter test <focused changed tests>
bash tool/receipt_cleanup_log_gate.sh
bash tool/receipt_doc_size_gate.sh
dart run tool/maintainiac_source_audit.dart
git diff --check
```

If a test fails because of a real bug, fix the bug and add a regression test.
Do not skip, weaken, or delete the failing test to make the branch look green.

## Coordination Protocol

- Commit and push clean milestones with descriptive commit messages.
- Do not leave large uncommitted batches if handing work back.
- If a needed change touches a forbidden camera-owned file, stop and write a
  note describing the required change instead of editing it.
- If a camera-owned test fails because of the second branch, revert the second
  branch's causing change or coordinate with the camera owner before continuing.
- If merge conflicts occur, do not guess. Inspect both sides and preserve the
  camera branch's source-of-truth behavior unless the user explicitly approves a
  different contract.

## Suggested First Pass For The Second Model

Start with this narrow first pass:

1. Read:
   - `lib/shared/widgets/receipt_capture/receipt_ocr_parser_handoff_lines.dart`
   - `lib/shared/widgets/receipt_capture/receipt_ocr_parser_models.dart`
   - `lib/screens/expenses/data/expense_line_record.dart`
   - `test/receipt_ocr_service_parser_handoff_structure_test.dart`
   - `test/expense_receipt_line_record_test.dart`
2. Add a regression test proving malformed OCR line numbers cannot leak into
   review labels or parser handoff maps.
3. Add a regression test proving price-only mode still carries line number,
   amount, and business/personal/split classification.
4. Run the focused tests only.
5. Commit and push.

That first pass gives useful safety without touching the native camera files.

