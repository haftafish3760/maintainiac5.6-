# Receipt Camera Double-Team Handoff

Last updated: 2026-07-03

This is the coordination file for running a second Codex model beside the active
camera-hardening thread in `/Users/rbbie/Documents/Maintainiac_5.6`.

The goal is faster progress without two agents editing the same files or
silently changing each other's contracts.

## Capacity Target

This split should be close to 50/50 by responsibility, not by line count:

- Current camera model: capture foundation, native camera behavior, image
  quality, long-receipt capture, stitching/overlap, and camera diagnostics.
- Second model: receipt review, OCR/parser handoff contracts, line numbering,
  business/personal/split review data, fixture generation, parser-facing QA,
  and regression coverage around review truth.

If one side gets blocked, do not steal files from the other lane. Add a
coordination note and pick the next safe item inside the assigned lane.

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

### Current Camera Model Owns - Lane A

The current model owns roughly half the work: the native/shared camera
foundation and physical capture quality path.

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
- temporary full-quality OCR source handoff
- camera diagnostics and privacy-safe capture metadata
- real-device camera readiness scripts
- camera-side barcode/QR scanner bridge only where it touches native capture or
  scanner invocation

The second model must not edit those areas unless the user explicitly transfers
ownership or the current camera model writes a coordination note naming the file.

### Second Model Owns - Lane B

The second model owns roughly half the work: the review, OCR/parser handoff,
fixture, and QA foundation that proves camera output can become trustworthy
receipt data without changing native capture internals.

- OCR result contract models
- parser handoff models
- receipt line numbering contracts
- detailed-line versus price-only review data contracts
- business/personal/split line classification models
- receipt review state models and non-camera review helpers
- saved receipt line serialization and map round-trip rules
- parser-facing barcode/QR payload contracts after safe scanner output exists
- OCR suggestion versus user-confirmed truth tests
- privacy-safe OCR/parser diagnostics
- synthetic receipt fixture definitions and generator helpers
- real-receipt fixture schema for future redacted samples
- parser-facing regression fixtures
- expense review UI tests that do not edit camera capture or native review
  screens
- QA runner contract coverage for fixture classes and parser handoff classes
- tests proving handoff maps preserve stable line IDs and line numbers
- docs that describe OCR/parser handoff behavior without redefining camera UI

The second model is allowed to add focused tests for these contracts. If a test
exposes a camera-flow bug, document the bug and hand it back instead of patching
camera-owned files.

Lane B is not "leftovers." It is the entire receipt truth/review/fixture half of
the system. A good Lane B pass should leave the camera branch with stronger
proof that every captured receipt can become numbered, reviewable, classified,
privacy-safe data.

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
- `lib/screens/expenses/entry/expense_receipt_detail_mode_panel.dart`
- `lib/screens/expenses/entry/expense_receipt_entry_line_mode_helpers.dart`
- `lib/screens/expenses/entry/expense_receipt_line_computed_fields.dart`
- `lib/screens/expenses/entry/expense_receipt_line_labels.dart`
- `lib/screens/expenses/entry/expense_receipt_line_model_conversions.dart`
- `lib/screens/expenses/entry/expense_receipt_line_models.dart`
- `lib/screens/expenses/entry/expense_receipt_line_review_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_line_evidence_controls.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_line_evidence_panel.dart`
- `lib/screens/expenses/entry/expense_receipt_recap_classification.dart`
- `lib/screens/expenses/entry/expense_receipt_recap_line_controls.dart`
- `lib/screens/expenses/entry/expense_receipt_recap_paper.dart`
- `test/receipt_ocr_service_parser_handoff_structure_test.dart`
- `test/receipt_ocr_service_fuel_receipts_test.dart`
- `test/expense_receipt_line_record_test.dart`
- `test/expense_receipt_parser_business_personal_test.dart`
- `test/expense_receipt_parser_ocr_diagnostics_test.dart`
- `test/expense_receipt_parser_line_amounts_test.dart`
- `test/expense_receipt_parser_allocations_test.dart`
- `test/expense_receipt_assisted_review_flow_test.dart`
- `test/expense_receipt_assisted_review_save_guardrails_test.dart`
- `test/receipt_qa_runner_contract_test.dart`
- `test/helpers/receipt_*`
- `test/helpers/expense_*`

The second model may add new focused files with meaningful names, for example:

- `lib/shared/widgets/receipt_capture/receipt_fixture_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_synthetic_fixture_generator.dart`
- `test/receipt_synthetic_fixture_generator_test.dart`
- `test/receipt_review_handoff_line_numbering_test.dart`
- `test/receipt_user_confirmed_truth_regression_test.dart`
- `test/receipt_price_only_review_contract_test.dart`
- `test/receipt_detailed_line_review_contract_test.dart`
- `test/receipt_fixture_schema_redaction_test.dart`

Keep new files modular and under the project line cap. Do not use lazy numbered
names like `file1`, `helper2`, or `ocr3`.

Lane B may touch expense review widgets only when the change is about line
review, price-only versus detailed mode, classification, or review evidence. It
must not change the camera entry button, native capture launch path, photo
review screen, or capture flow.

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
- `lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart`
- `lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_ocr_action_helpers.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_ocr_photo_helpers.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_ocr_readiness_helpers.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_ocr_review_helpers.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_ocr_review_row.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review_photo_recovery.dart`
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
- Temporary full-quality receipt captures feed OCR/prep first.
- Saved receipt proof images follow user storage settings; full original-quality
  retention must be an explicit user choice.
- Derived/stiched/cleaned/OCR images are artifacts and must not mutate
  user-confirmed receipt records silently.
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
9. Add or strengthen synthetic receipt fixture coverage for clean, blurry,
   glare, cropped, long, duplicate-total, missing-total, corrupted, empty, and
   wrong-file-type cases at the contract level.
10. Add or strengthen real-receipt fixture schema support so future user receipt
   samples can be redacted and given editable expected outputs.
11. Update `docs/receipt_bug_regression_ledger.md` only when a confirmed bug is
   fixed with a regression test.
12. Update this handoff or create a short companion note only if ownership
   boundaries change.

## Equal Work Backlog

Lane A backlog for the current model:

- continuous focus and exposure parity across Android/iOS contracts
- receipt readability meter and guidance codes
- long receipt continuation behavior
- segment retake ordering and previous/next context
- ghost overlay placement and overlap contracts
- stitching/overlap fallback behavior
- source preservation and cleanup safety
- camera-side barcode/QR invocation and privacy-safe scanner summaries
- real-device QA readiness for Android/iOS

Lane B backlog for the second model:

- stable OCR line IDs and one-based line numbers
- price-only review contracts
- detailed-line review contracts
- business/personal/split line classification contracts
- user-confirmed truth versus OCR/parser suggestion contracts
- synthetic receipt fixture generator/schema
- future real redacted fixture schema
- parser-facing malformed OCR regressions
- privacy-safe OCR/parser diagnostic summaries
- receipt review UI tests that do not touch capture flow

Each lane is large enough to keep one model busy. If Lane B finishes its first
batch early, it should deepen fixture/regression coverage rather than crossing
into Lane A camera files.

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
